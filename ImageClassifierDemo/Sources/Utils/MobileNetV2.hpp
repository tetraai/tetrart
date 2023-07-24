//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#pragma once

#include <CoreML/CoreML.h>

#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

/**
 * Convenience wrapper around a MobileNetV2 model for Tetra Runtime.
 */
class MobileNetV2
{
public:
    /**
     * The URL of the package containing model, labels, and a sample image.
     */
    static constexpr std::string_view c_demoDataUrl =
        "https://tetra-public-assets.s3.us-west-2.amazonaws.com/apidoc/MobileNetV2DemoData.zip";

    ~MobileNetV2();

    /**
     * Create a new instance, downloading the model and labels if necessary.
     */
    MobileNetV2();

    /**
     * Get the model's class labels.
     */
    const std::vector<std::string>& GetClassLabels() const;

    /**
     * Get the required height of the model's input.
     */
    size_t GetInputHeight() const;

    /**
     * Get the required width of the model's input.
     */
    size_t GetInputWidth() const;

    /**
     * Get the path to the model.
     */
    const std::filesystem::path& GetModelPath() const;

    /**
     * Get the path to a sample image.
     */
    const std::filesystem::path& GetSampleImagePath() const;

    /**
     * Print a report enumerating the most likely classes.
     */
    void PrintTopClasses(id<MLFeatureProvider> _Nonnull outputs, std::ostream& out) const;

private:
    std::filesystem::path m_modelPath;
    std::vector<std::string> m_classLabels;
    std::filesystem::path m_sampleImagePath;
};
