This demo shows how to use Tetra Runtime in an app that is already using Core
ML. In [`Sources/main.mm`](Sources/main.mm), an image is loaded into a
Core ML `MLMultiArray`, which is used as an input to an image classifier model.
Inference results are retrieved from an `MLFeatureProvider` and collated with
labels to print the most likely classes.

More information about Tetra Runtime can be found in
[Tetra Documentation](https://hub.tetra.ai/docs/).
