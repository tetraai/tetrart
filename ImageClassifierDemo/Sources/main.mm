//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#include <TetraRT/TetraRT.h>

#include <CoreML/CoreML.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <optional>
#include <unistd.h>

#include "Utils/MobileNetV2.hpp"
#include "Utils/RgbImageTensor.hpp"

namespace fs = std::filesystem;

/**
 * Parse command line arguments.
 * @returns The path of the image to classify.
 */
std::optional<fs::path> ParseArgs(int argc, char* argv[])
{
    std::optional<fs::path> imagePath;

    int ch = 0;
    while ((ch = getopt(argc, argv, "m:i:")) != -1)
    {
        switch (ch) {
            case 'i':
                imagePath = optarg;
                break;
            case '?':
            default:
                std::cerr << "Usage:\n\t" << argv[0] << "[ -i IMAGE_PATH ]\n";
        }
    }

    return imagePath;
}

int main(int argc, char* argv[])
{
    @autoreleasepool {
        auto imagePath = ParseArgs(argc, argv);

        // This helper class manages model resources.
        MobileNetV2 mobileNet;

        // TetraRT must be initialized before use. An optional parameter can be used
        // to configure logging.
        trt::Initialize();

        // Load the model.
        //
        // A ModelBundle can contain multiple variants of the same model. For example,
        // multiple resolutions of the same model may be stored within the same bundle.
        // The default variant can be statically defined within the model file or
        // determined at runtime based on device characteristics. This can be useful to
        // select simplified models on less-powerful devices.
        //
        // ModelDescriptions are metadata. Their only role in this scenario is to
        // load the Model.
        auto model = trt::ModelBundle(mobileNet.GetModelPath()).GetDefaultModelVariant().Load();

        // Load an image from disk
        RgbImageTensor imageTensor(imagePath.has_value() ? imagePath.value() : mobileNet.GetSampleImagePath());
        MLMultiArray* inputArray = imageTensor.ToMLMultiArray(mobileNet.GetInputHeight(), mobileNet.GetInputWidth());
        MLFeatureValue* imageFeatureValue = [MLFeatureValue featureValueWithMultiArray:inputArray];

        // Debugging: print a small version the image to the console
        // {
        //     imageTensor.Render(/*height=*/32, /*width=*/32, std::cout);
        // }

        // Bind the input.
        // For convenience, inputs can also be copied from a Core ML
        // id<MLFeatureProvider> by calling SetInputs().
        model->SetInput(@"x", imageFeatureValue);

        // Perform inference
        model->Run();

        // Retrieve results
        id<MLFeatureProvider> outputs = model->GetOutputProvider();

        // Do something interesting with inference results.
        mobileNet.PrintTopClasses(outputs, std::cout);
    }

    return 0;
}
