#!/bin/bash

set -e

# check and download dependency for gRPC code generate
if [ ! -e ./proto/vendor/protobuf/src/google/protobuf ]; then
    rm -rf ./proto/vendor/protobuf/src/google/protobuf
    DIR="./proto/vendor/protobuf/src/google/protobuf"
    mkdir -p $DIR
    wget https://raw.githubusercontent.com/protocolbuffers/protobuf/v3.9.0/src/google/protobuf/empty.proto -P $DIR
fi

# Due to https://github.com/golang/protobuf/issues/1122, our .proto file names must be globally unique to avoid
# namespace conflicts (https://protobuf.dev/reference/go/faq/#namespace-conflict). The best way to achieve this is to
# include the whole Go import path in the name that gets compiled into the .pb.go file (e.g.
# "github.com/longhorn/backing-image-manager/pkg/rpc.proto" instead of "rpc.proto"). This formulation does the
# compilation inside a temporary directory prefixed with the full desired path before copying the .pb.go file out
# (similar to the way https://github.com/container-storage-interface/spec/blob/master/lib/go/Makefile does it).
PKG_DIR="pkg/rpc"
TMP_DIR_BASE=".protobuild"
TMP_DIR="${TMP_DIR_BASE}/github.com/longhorn/backing-image-manager/pkg/rpc"
mkdir -p "${TMP_DIR}"
cp "${PKG_DIR}/rpc.proto" "${TMP_DIR}/rpc.proto"
protoc -I "${TMP_DIR_BASE}" -I "proto/vendor/protobuf/src/" "${TMP_DIR}/rpc.proto" --go_out=plugins=grpc:"${TMP_DIR_BASE}"
mv "${TMP_DIR}/rpc.pb.go" "${PKG_DIR}/rpc.pb.go"
rm -rf "${TMP_DIR_BASE}"
