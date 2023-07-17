//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#include "Utils/MobileNetV2.hpp"

#include "Utils/OnScopeExit.hpp"

#include <Foundation/Foundation.h>
#include <ZipArchive.h>

#include <fstream>
#include <iostream>
#include <sstream>
#include <string_view>
#include <utility>

namespace fs = std::filesystem;

namespace
{

constexpr std::string_view c_demoDataZipName("MobileNetV2DemoData.zip");

/**
 * Create an NSError with the given description.
 */
NSError* ErrorWithDescription(const std::string& description)
{
    NSString* errorDescription = [NSString stringWithUTF8String:description.c_str()];
    NSDictionary<NSErrorUserInfoKey, id>* userInfo = @{
        NSLocalizedDescriptionKey: errorDescription,
        NSLocalizedFailureReasonErrorKey: errorDescription,
        NSLocalizedRecoverySuggestionErrorKey: errorDescription
    };

    return [NSError errorWithDomain:@"ai.tetra.demo" code:1 userInfo:userInfo];
}

/**
 * Return the path of the demo data archive, downloading it if necessary.
 */
fs::path FetchDemoData()
{
    NSURL* remoteZipUrl = [NSURL URLWithString:[NSString stringWithUTF8String:MobileNetV2::c_demoDataUrl.data()]];

    NSString* currentDirectoryStr = [NSFileManager defaultManager].currentDirectoryPath;
    NSString* demoDataZipNameStr = [NSString stringWithUTF8String:c_demoDataZipName.data()];
    NSURL* localZipUrl = [NSURL fileURLWithPathComponents:@[currentDirectoryStr, demoDataZipNameStr]];
    fs::path localZipPath(localZipUrl.fileSystemRepresentation);

    if (fs::exists(localZipPath))
    {
        std::cout << "Skipping download of demo data already found in " << localZipPath << ".\n";
        return localZipPath;
    }

    dispatch_semaphore_t requestSemaphore = dispatch_semaphore_create(0);
    __block NSError* savedError = nil;
    NSURLSessionDataTask* dataTask =
        [[NSURLSession sharedSession]
             dataTaskWithURL:remoteZipUrl
            completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error)
    {
        OnScopeExit signal([&requestSemaphore]() { dispatch_semaphore_signal(requestSemaphore); });
         if (error)
         {
             savedError = error;
             return;
         }

        // This is documented to be a correct cast when loading an HTTP URL.
        // https://developer.apple.com/documentation/foundation/nshttpurlresponse
        NSHTTPURLResponse* httpResponse = reinterpret_cast<NSHTTPURLResponse*>(response);
        if (httpResponse.statusCode < 200 || httpResponse.statusCode > 299)
        {
            std::ostringstream msg;
            msg << "Failed with HTTP status " << httpResponse.statusCode << ".";
            savedError = ErrorWithDescription(msg.str());
            return;
        }

        std::cout << "got " << data.length << " bytes...";
        if (![data writeToURL:localZipUrl atomically:YES])
        {
            std::ostringstream msg;
            msg << "Failed to write " << localZipPath.string() << ".";
            savedError = ErrorWithDescription(msg.str());
        }
     }];

    std::cout << "Downloading " << MobileNetV2::c_demoDataUrl << " to " << localZipPath.string() << "..." << std::flush;
    [dataTask resume];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC);
    while (dispatch_semaphore_wait(requestSemaphore, timeout)) {
        timeout = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC);
        std::cout << "." << std::flush;
    }

    if (savedError)
    {
        throw std::runtime_error(savedError.localizedDescription.UTF8String);
    }

    std::cout << "done." << std::endl;

    return localZipPath;
}

/**
 * Extract demo inputs and return their paths.
 * @returns a tuple of (model, labels, sample image) paths.
 */
std::tuple<fs::path, fs::path, fs::path> FetchDemoFiles()
{
    auto zipPath = FetchDemoData();

    NSString* zipPathStr = [NSString stringWithUTF8String:zipPath.c_str()];
    NSString* currentDirectoryStr = [NSFileManager defaultManager].currentDirectoryPath;
    fs::path currentDirectoryPath(currentDirectoryStr.fileSystemRepresentation);

    [SSZipArchive unzipFileAtPath:zipPathStr toDestination:currentDirectoryStr];

    return std::make_tuple(currentDirectoryPath / "MobileNetV2DemoData" / "MobileNetV2.trtmodel",
                           currentDirectoryPath / "MobileNetV2DemoData" / "imagenet_classes.txt",
                           currentDirectoryPath / "MobileNetV2DemoData" / "input_image1.jpg");
}

/**
 * Parse the MobileNetV2 labels file.
 */
std::vector<std::string> ParseClassLabels(const fs::path& labelsPath)
{
    std::vector<std::string> labels;
    labels.reserve(1000);

    std::ifstream labelsStream(labelsPath);
    if (!labelsStream.good()) {
        throw std::runtime_error("Could not open " + labelsPath.string() + ".");
    }

    for (std::string line; std::getline(labelsStream, line); ) {
        labels.push_back(std::move(line));
    }

    return labels;
}

}

MobileNetV2::~MobileNetV2() = default;

MobileNetV2::MobileNetV2()
{
    auto [modelPath, classLabelsPath, sampleImagePath] = FetchDemoFiles();
    m_modelPath = std::move(modelPath);
    m_classLabels = ParseClassLabels(classLabelsPath);
    m_sampleImagePath = std::move(sampleImagePath);
}

const std::vector<std::string>& MobileNetV2::GetClassLabels() const
{
    return m_classLabels;
}

size_t MobileNetV2::GetInputHeight() const
{
    return 224;
}

size_t MobileNetV2::GetInputWidth() const
{
    return 224;
}

const fs::path& MobileNetV2::GetModelPath() const
{
    return m_modelPath;
}

const fs::path& MobileNetV2::GetSampleImagePath() const
{
    return m_sampleImagePath;
}

void MobileNetV2::PrintTopClasses(id<MLFeatureProvider> _Nonnull outputs, std::ostream& out) const
{
    std::vector<std::pair<NSUInteger, float>> classScores;

    MLMultiArray* scores = [outputs featureValueForName:@"var_822"].multiArrayValue;
    for (NSUInteger i = 0; i < scores.count; ++i)
    {
        classScores.emplace_back(i, scores[i].floatValue);
    }

    std::stable_sort(classScores.begin(), classScores.end(), [](auto c1, auto c2) { return c1.second > c2.second; });

    out << "Top 5 classes\n";
    for (size_t i = 0; i < 5; ++i) {
        auto classIndex = classScores.at(i).first;
        out << '"' << GetClassLabels().at(classIndex) << "\" (" << classIndex << "): "
            << classScores.at(i).second << "\n";
    }

}
