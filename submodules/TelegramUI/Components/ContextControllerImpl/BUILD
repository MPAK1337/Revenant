load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ContextControllerImpl",
    module_name = "ContextControllerImpl",
    srcs = [
        "Sources/ContextControllerCompatibility.swift",
    ],
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/ContextUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
