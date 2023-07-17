#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)

__cleanup_dirs=()
function __cleanup()
{
    test "${#__cleanup_dirs[@]}" -eq 0 && return

    for d in "${__cleanup_dirs[@]}"; do
        test -d "${d}" && rm -fr "${d}"
    done
}


function __smoke_test()
{
    pushd "${REPO_ROOT}" > /dev/null
    echo "=== Running SmokeTest ==="
    __cleanup_dirs+=("${PWD}/build")
    swift run -c release SmokeTest
    popd > /dev/null
}

function __image_classifier_demo()
{
    pushd "${REPO_ROOT}/ImageClassifierDemo" > /dev/null
    echo "=== Building ImageClassifierDemo ==="

    local tempdir=$(mktemp -d -t ImageClassifierDemoRoot)
    __cleanup_dirs+=("${tempdir}" "${PWD}/build")

    xcodebuild clean
    xcodebuild install -configuration Release -target ImageClassifierDemo DSTROOT="${tempdir}"
    pushd "${tempdir}" > /dev/null
    "${tempdir}/usr/local/bin/ImageClassifierDemo"

    popd > /dev/null
    popd > /dev/null
}

function build_and_test_main()
{
    trap __cleanup EXIT
    __smoke_test
    __image_classifier_demo
}

function describe_build_env()
{
    echo "=== Build Environment ==="
    uname -a
    xcodebuild -version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail

    describe_build_env
    build_and_test_main "$@"
fi
