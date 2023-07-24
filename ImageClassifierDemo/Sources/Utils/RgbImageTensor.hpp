//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#pragma once

#include <CoreML/CoreML.h>

#include <filesystem>
#include <ostream>

/**
 * A tensor created from image data.
 */
class RgbImageTensor {
public:
    ~RgbImageTensor();

    /**
     * Construct a new instance from data in the given image file.
     */
    explicit RgbImageTensor(std::filesystem::path imagePath);

    /**
     * Get the path to the image.
     */
    const std::filesystem::path& GetImagePath() const;

    /**
     * Get the image data as a [1, 3, height, width] float MLMultiArray.
     */
    MLMultiArray* _Nonnull ToMLMultiArray(size_t height, size_t width) const;

    /**
     * Render a [height x width] representation of the image.
     */
    void Render(size_t height, size_t width, std::ostream& out) const;

private:
    std::filesystem::path m_imagePath;
};
