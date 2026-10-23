#!/usr/bin/env bash
# Builds the stable-diffusion.cpp engine exactly as Picture Maker's pods used to build it on the network volume,
# then packs it for a GitHub release. Runs inside nvidia/cuda:12.8.1-devel-ubuntu22.04, which matches the pods'
# image (runpod/pytorch, CUDA 12.8.1 on Ubuntu 22.04), so the engine runs there unchanged.
set -euo pipefail
SERVER_REPO=https://github.com/hypersniper05/MCP-Image-Generator-Uncensored
SERVER_REF=${SERVER_REF:-main}
# 86 = A40, A6000, A5000, RTX 3090.  89 = RTX 4090, L40S, L40, RTX 6000 Ada.
CUDA_ARCHS=${CUDA_ARCHS:-86-real;89-real}

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq --no-install-recommends git cmake build-essential ca-certificates python3 >/dev/null

rm -rf work && mkdir work && cd work
git clone -q "$SERVER_REPO" app
git -C app checkout -q "$SERVER_REF"
SERVER_SHA=$(git -C app rev-parse HEAD)
SDCPP_REF=$(sed -n 's/^ARG SDCPP_REF=//p' app/Dockerfile)
echo "image server $SERVER_SHA, engine $SDCPP_REF"

git clone -q --depth 1 --branch "$SDCPP_REF" --recursive --shallow-submodules https://github.com/leejet/stable-diffusion.cpp src
for p in app/docker/patches/*.patch; do git -C src apply "$p"; done
cmake -S src -B src/build -DCMAKE_BUILD_TYPE=Release \
  -DSD_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCHS" -DGGML_CUDA_NCCL=OFF \
  -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON \
  -DSD_BUILD_SHARED_LIBS=ON -DSD_BUILD_SHARED_GGML_LIB=ON \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON '-DCMAKE_INSTALL_RPATH=$ORIGIN' \
  -DSD_SERVER_BUILD_FRONTEND=OFF
cmake --build src/build --config Release -j "$(nproc)"

mkdir -p out/sdcpp
cp -a src/build/bin/. out/sdcpp/ && rm -f out/sdcpp/*.a
(cd app/docker/patches && ls -1 *.patch | sed 's/[.]patch$//') > out/sdcpp/MCP_PATCHES
test -x out/sdcpp/sd-server
python3 - "$SERVER_SHA" "$SDCPP_REF" "$CUDA_ARCHS" > out/engine.json <<'PY'
import json, sys, time
print(json.dumps({"server_sha": sys.argv[1], "sdcpp_ref": sys.argv[2], "cuda_archs": sys.argv[3],
                  "cuda": "12.8.1", "ubuntu": "22.04", "built": time.strftime("%Y-%m-%d %H:%M UTC", time.gmtime())}))
PY
tar -C out -czf ../engine.tar.gz sdcpp
cp out/engine.json ../engine.json
cd .. && ls -l engine.tar.gz engine.json && cat engine.json
{ echo "TAG=engine-${SDCPP_REF}-${SERVER_SHA:0:7}"; echo "SDCPP_REF=$SDCPP_REF"; echo "SERVER_SHA=$SERVER_SHA"; } >> "${GITHUB_ENV:-/dev/null}"
