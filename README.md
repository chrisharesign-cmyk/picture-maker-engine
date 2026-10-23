# picture-maker-engine

The ready-built engine for Picture Maker's RunPod pods: [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp)
(MIT) with the patches from [MCP-Image-Generator-Uncensored](https://github.com/hypersniper05/MCP-Image-Generator-Uncensored) (MIT),
built with CUDA 12.8.1 on Ubuntu 22.04 for RTX 3090/4090, A5000/A6000, A40, L40 and L40S cards.

Every build is published as its own release (`engine-<engine version>-<image server commit>-r<run number>`)
with `engine.tar.gz`, `engine.json` (the image server commit it was built for) and `engine.sha256`.
Picture Maker pins one release by name and its SHA-256, and its pods refuse an engine file that doesn't match,
so changing a file here can't change what the pods run.

GitHub Actions builds it (`.github/workflows/build.yml`). To rebuild for a newer image server, open
**Actions → Build engine → Run workflow**. No keys or passwords are stored here.
