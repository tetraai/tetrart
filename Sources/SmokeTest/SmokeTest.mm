//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#include <TetraRT/TetraRT.h>

#include <iostream>

int main(int argc, char* argv[])
{
    // Just make sure we can call something in the framework.
    trt::Initialize();

    std::cout << "No smoke, no fire!\n";

    return 0;
}
