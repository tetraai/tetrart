//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#include "Utils/RgbImageTensor.hpp"

#include "Utils/OnScopeExit.hpp"

#include <CoreML/CoreML.h>

#include <filesystem>
#include <iostream>
#include <sstream>

namespace fs = std::filesystem;

namespace
{

/**
 * Info about 3-channel image dimensions.
 */
struct RgbImageShape {
    enum class Color : size_t {
        Red = 0,
        Green = 1,
        Blue = 2
    };

    size_t OffsetOf(Color color, size_t row, size_t column)
    {
        return (static_cast<size_t>(color) * (Height * Width) + (row * Width) + column);
    }

    size_t Height{0};
    size_t Width{0};
};

/**
 * Compute the strides for a tensor of the given shape, assuming it's layout
 * is contiguous.
 */
NSArray<NSNumber*>* DefaultStrides(NSArray<NSNumber*>* _Nonnull shape)
{
    if (shape.count == 0)
    {
        return @[];
    }

    NSMutableArray<NSNumber*>* strides = [[NSMutableArray alloc] initWithCapacity:shape.count];
    for (NSUInteger i = 0; i < shape.count; ++i)
    {
        [strides addObject:[NSNumber numberWithUnsignedLongLong:1]];
    }

    for (NSUInteger i = 0; i < strides.count - 1; ++i)
    {
        for (NSUInteger j = i + 1; j < shape.count; ++j)
        {
            NSUInteger newStride = strides[i].unsignedLongLongValue * shape[j].unsignedLongLongValue;
            strides[i] = [NSNumber numberWithUnsignedLongLong:newStride];
        }
    }

    return strides;
}

}

// ------------------------------------------------------------------------------------------

RgbImageTensor::~RgbImageTensor() = default;

RgbImageTensor::RgbImageTensor(fs::path imagePath)
    : m_imagePath(std::move(imagePath))
{}

const fs::path& RgbImageTensor::GetImagePath() const
{
    return m_imagePath;
}

MLMultiArray* RgbImageTensor::ToMLMultiArray(size_t height, size_t width) const
{
    // Based loosely on https://nshipster.com/image-resizing/

    NSString* nsImagePath = [NSString stringWithUTF8String:GetImagePath().c_str()];
    NSURL* imageUrl = [NSURL fileURLWithPath:nsImagePath];

    //
    // Read the image using ImageIO
    //
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageUrl, /*options=*/NULL);
    if (!imageSource)
    {
        throw std::runtime_error("Failed to create image source.");
    }
    OnScopeExit releaseImageSource([imageSource]() { CFRelease(imageSource); });

    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, /*index=*/0, /*options=*/NULL);
    if (!image)
    {
        throw std::runtime_error("Failed to create image from source.");
    }
    OnScopeExit releaseImage([image]() { CGImageRelease(image); });


    //
    // Scale the image using CoreGraphics
    //
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    if (!colorSpace)
    {
        throw std::runtime_error("Failed to create color space.");
    }
    OnScopeExit releaseColorSpace([colorSpace]() { CGColorSpaceRelease(colorSpace); });

    size_t bytesPerRow = width * 4;
    std::vector<uint8_t> bitmapData(bytesPerRow * height);
    CGContextRef context = CGBitmapContextCreate(bitmapData.data(), width, height, /*bitsPerComponent=*/8, bytesPerRow,
                                                 colorSpace, bitmapInfo);
    if (!context)
    {
        throw std::runtime_error("Failed to create CoreGraphics context.");
    }
    OnScopeExit releaseContext([context]() { CGContextRelease(context); });

    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGRect rect = CGRectMake(/*x=*/0, /*y=*/0, /*width=*/width, /*height=*/height);
    CGContextDrawImage(context, rect, image);

    //
    // Drop the alpha channel and transpose to [n]CHW to produce the MLMultiArray data
    //
    auto bitmapDataNoAlpha = new std::vector<float>(width * height * 3, 0);

    RgbImageShape imageShape{.Height = height, .Width = width};
    for (size_t r = 0; r < height; ++r) {
        for (size_t c = 0; c < width; ++c) {
            auto hwcOffset = ((r * width) + c) * 4;
            (*bitmapDataNoAlpha).at(imageShape.OffsetOf(RgbImageShape::Color::Red, r, c)) = bitmapData[hwcOffset + 0];
            (*bitmapDataNoAlpha).at(imageShape.OffsetOf(RgbImageShape::Color::Green, r, c)) = bitmapData[hwcOffset + 1];
            (*bitmapDataNoAlpha).at(imageShape.OffsetOf(RgbImageShape::Color::Blue, r, c)) = bitmapData[hwcOffset + 2];
        }
    }

    //
    // Produce the MLMultiArray, which will assume ownership of bitmapDataNoAlpha.
    //

    NSArray<NSNumber*>* shape = @[
        @1,
        @3,
        [NSNumber numberWithUnsignedLongLong:height],
        [NSNumber numberWithUnsignedLongLong:width]
    ];

    NSArray<NSNumber*>* strides = DefaultStrides(shape);

    NSError* error = nil;
    MLMultiArray* array = [[MLMultiArray alloc] initWithDataPointer:bitmapDataNoAlpha->data()
                                                              shape:shape
                                                           dataType:MLMultiArrayDataTypeFloat32
                                                            strides:strides
                                                        deallocator:^(void * _Nonnull bytes) {delete bitmapDataNoAlpha;}
                                                              error:&error];

    if (!array)
    {
        if (error)
        {
            std::ostringstream msg;
            msg << "Could not create MLMultiArray: " << error.localizedDescription.UTF8String;
            throw std::runtime_error(msg.str());
        }
        throw std::runtime_error("Unknown error while creating MLMultiArray.");
    }

    return array;
}

void RgbImageTensor::Render(size_t height, size_t width, std::ostream& out) const
{
    MLMultiArray* array = ToMLMultiArray(height, width);

    out << std::hex;

    NSMutableArray<NSNumber*>* location = [NSMutableArray arrayWithArray:@[@0, @0, @0, @0]];
    for (size_t r = 0; r < height; ++r)
    {
        [location replaceObjectAtIndex:2 withObject:[NSNumber numberWithUnsignedLongLong:r]];

        if (r)
        {
            out << "\n";
        }

        for (size_t c = 0; c < width; ++c)
        {
            [location replaceObjectAtIndex:3 withObject:[NSNumber numberWithUnsignedLongLong:c]];

            [location replaceObjectAtIndex:1 withObject:@0];
            auto red = static_cast<int>([array objectForKeyedSubscript:location].floatValue);

            [location replaceObjectAtIndex:1 withObject:@1];
            auto green = static_cast<int>([array objectForKeyedSubscript:location].floatValue);

            [location replaceObjectAtIndex:1 withObject:@2];
            auto blue = static_cast<int>([array objectForKeyedSubscript:location].floatValue);

            auto avg = (red + green + blue) / 3;

            out << std::setw(3) << 255 - avg;
        }
    }

    out << "\n";

    out << std::dec;
}
