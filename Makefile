BAZEL := "bazel"

STARTUP_FLAGS += --output_base="$HOME/.cache/bazel"
STARTUP_FLAGS += --host_jvm_args=-Xmx500m
STARTUP_FLAGS += --host_jvm_args=-Xms500m
STARTUP_FLAGS += --batch

BUILD_FLAGS += --verbose_failures
BUILD_FLAGS += --spawn_strategy=standalone
BUILD_FLAGS += --genrule_strategy=standalone
BUILD_FLAGS += --local_resources=400,2,1.0
BUILD_FLAGS += --worker_verbose
BUILD_FLAGS += --strategy=Javac=worker
BUILD_FLAGS += --strategy=Closure=worker
#BUILD_FLAGS += --experimental_repository_cache="$HOME/.bazel_repository_cache"

TESTFLAGS += $(BUILDFLAGS)
TEST_FLAGS += --test_output=errors
TEST_FLAGS += --test_strategy=standalone

BAZEL_BUILD := $(BAZEL) $(STARTFLAGS) $(BAZELFLAGS) build $(BUILDFLAGS)
#BAZEL_BUILD := $(BAZEL) build
BAZEL_TEST := $(BAZEL) $(STARTFLAGS) $(BAZELFLAGS) test $(TEST_FLAGS)
#BAZEL_TEST := $(BAZEL) test

test_not_working_targets:
	$(BAZEL) test \
	//examples/helloworld/csharp/GreeterClient:GreeterClientTest \ # fails with # Nuget command failed: Unable to load the service index for source https://api.nuget.org/v3/index.json
	//examples/helloworld/csharp/GreeterServer:GreeterServerTest \
	//examples/helloworld/node:client
	//examples/helloworld/node:server

# Python targets are not working (pip grpcio only compatible with 3.1.x)
test_pip_dependent_targets:
	$(BAZEL_TEST) \
	//examples/helloworld/python:test_greeter_server \

all: build test

build: external_proto_library_build
	$(BAZEL_BUILD) \
	//examples/extra_args:person_tar \
	//examples/helloworld/go/client \
	//examples/helloworld/go/server \
	//examples/helloworld/grpc_gateway:swagger \
	//tests/proto_file_in_subdirectory:protolib \
	//tests/with_grpc_false:protos \
	//tests/with_grpc_false:cpp \
	//tests/with_grpc_false:java \

test:
	$(BAZEL_TEST) \
	//examples/helloworld/cpp:test \
	//examples/helloworld/java/org/pubref/rules_protobuf/examples/helloworld/client:netty_test \
	//examples/helloworld/java/org/pubref/rules_protobuf/examples/helloworld/server:netty_test \
	//examples/wkt/go:wkt_test \
	//tests/proto_file_in_subdirectory:test \
	//examples/helloworld/closure:greeter_test \
	//examples/helloworld/grpc_gateway:greeter_test \

external_proto_library_build:
	cd tests/external_proto_library && $(BAZEL_BUILD) :cc_gapi :go_gapi :java_gapi

fmt:
	buildifier WORKSPACE
	find bzl/build_file/ -name '*.BUILD' | xargs buildifier
	find third_party/ -name BUILD | xargs buildifier
	find examples/ -name BUILD | xargs buildifier
	find tests/ -name BUILD | xargs buildifier

rpl:
	rpl -vvRs \
	-x'.bzl' -x'.md' -x'BUILD' \
	'com_github_grpc_grpc' 'com_google_grpc' \
	closure examples go gogo grpc_gateway objc python \
	ruby tests java cpp protobuf csharp node README.md
