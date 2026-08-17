# TheRock AMD Bootstrap

Canonical, test-driven bootstrap for local AI workloads on AMD GPUs.

This repository exists so we do **not** rediscover the same AMD / ROCm / PyTorch problems in every new project or every new AI chat.

Current primary test machine:

- GPU: **AMD Radeon RX 6900 XT 16 GB**
- Architecture: **RDNA2**
- LLVM/GFX target: **gfx1030**
- OS: **Windows 11**
- Python baseline: **3.12 x64**
- Working PyTorch path: **AMD TheRock multi-arch ROCm nightlies**

## Read this first

AI agents and humans should read [`AGENTS.md`](AGENTS.md) before proposing an AMD setup.

The most important rule:

> Do not confuse AMD's official production PyTorch support matrix with the wider set of GPUs supported by TheRock multi-arch packages.

As of 2026-08-17, AMD's Windows PyTorch ROCm 7.2.1 production matrix does **not** list RX 6900 XT / gfx1030. However, AMD TheRock multi-arch releases explicitly provide `device-gfx1030`, including Windows PyTorch packages.

## Known-good RX 6900 XT install path

Create a clean Python 3.12 environment and install PyTorch from TheRock:

```bat
py -3.12 -m venv .venv
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

Then run:

```bat
.venv\Scripts\python.exe scripts\doctor.py
```

Expected core result:

```text
torch.cuda.is_available() = True
GPU = AMD Radeon RX 6900 XT
```

`torch.cuda` is the compatibility namespace used by PyTorch. Seeing `torch.cuda` does **not** mean the workload is using NVIDIA CUDA.

## Proven workload

The same TheRock `gfx1030` route is used by the tested NuovaRicambi Image Cleaner stack:

```text
RX 6900 XT
  -> TheRock ROCm PyTorch
  -> MIOpen / HIPRTC
  -> DENet watermark-mask detection
  -> BiRefNet foreground segmentation
  -> GPU batch processing
```

A 20-image test batch and MIOpen BatchNorm smoke test were successfully used as validation gates before full processing.

## Repository map

- [`AGENTS.md`](AGENTS.md) — operating contract for AI agents.
- [`docs/KNOWN_GOOD_RX6900XT.md`](docs/KNOWN_GOOD_RX6900XT.md) — known-good machine and install facts.
- [`docs/TEST_LEDGER.md`](docs/TEST_LEDGER.md) — PASS / FAIL / BLOCKED history. Add new experiments here.
- [`docs/STACK_MATRIX.md`](docs/STACK_MATRIX.md) — which backend to prefer for ComfyUI, diffusion, LLMs, RVC and other workloads.
- [`docs/COMFYUI_PLAN.md`](docs/COMFYUI_PLAN.md) — current image-generation experiment plan.
- [`scripts/doctor.py`](scripts/doctor.py) — minimal AMD PyTorch / MIOpen smoke test.

## Golden rules

1. **Never install ordinary PyPI `torch` over a known-good TheRock environment.**
2. Keep `torch`, `torchvision`, and ROCm device packages under explicit control.
3. New applications get a new venv. Do not destroy a working one to test another app.
4. Run the doctor before blaming ComfyUI, Diffusers, Transformers, RVC, a model, or a custom node.
5. Treat CUDA-only extensions as compatibility blockers until a HIP/ROCm path is verified.
6. Snapshot exact package versions when a stack works.
7. Record failed routes so a future AI does not recommend them again.

## Source of truth vs current experiments

This repository separates three states:

- **KNOWN GOOD** — personally tested on the target machine.
- **SUPPORTED UPSTREAM** — documented by AMD / TheRock / the upstream project but not necessarily tested locally.
- **EXPERIMENTAL** — worth trying, but not yet accepted as a local baseline.

Never silently promote an experimental path to known-good.

## Primary upstream references

- AMD TheRock releases: https://github.com/ROCm/TheRock/blob/main/RELEASES.md
- AMD TheRock project: https://github.com/ROCm/TheRock
- AMD Windows Radeon compatibility: https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityrad/windows/windows_compatibility.html
- AMD Windows HIP SDK system requirements: https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/shared/hipsdk/reference/system-requirements.html
- ComfyUI: https://github.com/Comfy-Org/ComfyUI

## Scope

The repo is not limited to image generation. It is intended to become the reusable AMD bootstrap for:

- ComfyUI / Stable Diffusion / SDXL / FLUX-class image models
- LoRA inference and training
- ControlNet / OpenPose / IP-Adapter
- Diffusers / Transformers
- segmentation / vision models
- RVC / audio AI
- LLM inference
- llama.cpp / HIP / ROCm engines
- model fine-tuning
- custom HIP-compatible ML workloads

The rule is simple: **test, measure, record, reuse**.
