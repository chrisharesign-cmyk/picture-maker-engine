#!/usr/bin/env bash
# Builds llama.cpp's llama-server (the program that lets a pod describe pictures) with CUDA, and packs it for a GitHub release.
# Runs inside nvidia/cuda:12.8.1-devel-ubuntu22.04, which matches the pods' image, like build.sh does for the picture engine.
set -eEuo pipefail
LOG=$(mktemp)
exec > >(tee -a "$LOG") 2>&1
trap 'rc=$?; msg=$(tail -n 15 "$LOG" | tr "\n" "|" | cut -c1-3000); echo "::error::Failed (exit $rc) at line $LINENO: $BASH_COMMAND || $msg"' ERR
LLAMA_REF=${LLAMA_REF:-b12767}
CUDA_ARCHS=${CUDA_ARCHS:-86-real;89-real}   # 86 = A40, A6000, RTX 3090.  89 = RTX 4090, L40S.

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq --no-install-recommends git cmake build-essential ca-certificates python3 >/dev/null

rm -rf work && mkdir work && cd work
git clone -q --depth 1 --branch "$LLAMA_REF" https://github.com/ggml-org/llama.cpp src
LLAMA_SHA=$(git -C src rev-parse HEAD)
echo "llama.cpp $LLAMA_REF ($LLAMA_SHA)"
cmake -S src -B src/build -DCMAKE_BUILD_TYPE=Release \
  -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCHS" -DGGML_CUDA_NCCL=OFF \
  -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON \
  -DLLAMA_OPENSSL=OFF -DLLAMA_BUILD_UI=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON '-DCMAKE_INSTALL_RPATH=$ORIGIN'
cmake --build src/build --config Release -j "$(nproc)" --target llama-server

mkdir -p out/llama
cp -a src/build/bin/. out/llama/ && rm -f out/llama/*.a
test -x out/llama/llama-server
tar -C out -czf ../llama.tar.gz llama
sha256sum ../llama.tar.gz | cut -d" " -f1 > ../llama.sha256
cd .. && ls -l llama.tar.gz && cat llama.sha256
{ echo "TAG=llama-${LLAMA_REF}-r${GITHUB_RUN_NUMBER:-0}"; echo "LLAMA_REF=$LLAMA_REF"; echo "LLAMA_SHA=$LLAMA_SHA"; } >> "${GITHUB_ENV:-/dev/null}"
