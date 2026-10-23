# picture-maker-engine

The ready-built engine for Picture Maker's RunPod pods: [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp)
(MIT) with the patches from [MCP-Image-Generator-Uncensored](https://github.com/hypersniper05/MCP-Image-Generator-Uncensored) (MIT),
built with CUDA 12.8.1 on Ubuntu 22.04 for RTX 3090/4090, A5000/A6000, A40, L40 and L40S cards.

Pods download it from the latest release:

- `https://github.com/chrisharesign-cmyk/picture-maker-engine/releases/latest/download/engine.tar.gz`
- `https://github.com/chrisharesign-cmyk/picture-maker-engine/releases/latest/download/engine.json`
  (names the image server commit the engine was built for, so the pod installs the matching code)

GitHub Actions builds it (`.github/workflows/build.yml`). To rebuild for a newer image server, open
**Actions → Build engine → Run workflow**. No keys or passwords are stored here.
