# TheRock AMD Bootstrap

Canonical, test-driven bootstrap and knowledge base for local AI workloads on AMD GPUs.

The point of this repository is simple: **do not rediscover the same AMD / ROCm / PyTorch problems in every project or every new AI chat.** Read the local PASS/FAIL history first, preserve the known-good runtime, then test one layer at a time.

## Primary verified machine

- GPU: **AMD Radeon RX 6900 XT 16 GB**
- Architecture: **RDNA2 / gfx1030**
- OS: **Windows 11 x64**
- Python: **3.12.8 x64**
- GPU runtime: **AMD TheRock multi-arch PyTorch / ROCm packages**
- UI: **ComfyUI**

## Current verified status

The following has been proven on the real machine:

- TheRock `device-gfx1030` PyTorch recognizes RX 6900 XT.
- GPU matmul: **PASS**.
- FP16 matmul: **PASS**.
- Conv2d / MIOpen path: **PASS**.
- ComfyUI starts on native AMD/HIP.
- DynamicVRAM is enabled.
- ComfyUI-Manager imports.
- ComfyUI_IPAdapter_plus imports.
- comfyui_controlnet_aux imports.
- **Z-Image Turbo text-to-image: VERIFIED PASS at 1024x1024 / 8 steps.**

Exact observed versions and settings are in [`docs/KNOWN_GOOD_RX6900XT.md`](docs/KNOWN_GOOD_RX6900XT.md).

## Read this first

AI agents and humans should read [`AGENTS.md`](AGENTS.md) before changing packages or recommending a new AMD setup.

Critical distinction:

> AMD's official production PyTorch support matrix and TheRock multi-arch device coverage are not the same thing.

For this machine, the practical known-good route is TheRock `device-gfx1030`. Changing that base without first reading the test ledger is a regression risk.

## Quick start — ComfyUI

Base setup:

```bat
scripts\10_SETUP_COMFYUI_RX6900XT.bat
```

Optional manager and basic pose/reference nodes:

```bat
scripts\12_INSTALL_COMFYUI_MANAGER.bat
scripts\13_INSTALL_BASIC_CUSTOM_NODES.bat
```

Install the verified Z-Image Turbo model set:

```bat
scripts\14_INSTALL_Z_IMAGE_TURBO_MODELS.bat
```

Start:

```bat
scripts\11_LAUNCH_COMFYUI_RX6900XT.bat
```

Stop reliably:

```bat
STOP_COMFYUI.bat
```

Verified workflow:

```text
workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json
```

## Known-good TheRock package route

The tested stack uses the TheRock multi-arch index and protects the torch family as one unit:

```bat
py -3.12 -m venv .venv
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]" torchaudio
```

`torch.cuda` / `cuda:0` are historical PyTorch API names and can refer to the AMD ROCm/HIP backend. They do **not** prove NVIDIA CUDA is in use.

## Z-Image Turbo golden rule

Required model files:

```text
models\text_encoders\qwen_3_4b.safetensors
models\diffusion_models\z_image_turbo_bf16.safetensors
models\vae\ae.safetensors
```

The VAE selector must be:

```text
ae.safetensors
```

Do **not** use `pixel_space` for this workflow. That exact mistake completed 8/8 sampling but then sent a 16-channel tensor into `SaveImage`, causing Pillow to fail. The corrected workflow generated a real 1024x1024 image.

## Obstacles already solved

The repository records the failures we hit so they are not repeated:

- logger wrapper `WorkerArgument` mismatch;
- internal `worker` token leaking into `main.py`;
- Windows BAT `shift` changing `%0` and blanking `%~f0`;
- missing `torchaudio` after protecting the TheRock torch stack;
- stale ComfyUI process causing port `8188` conflict and `comfyui.db` lock;
- missing Z-Image model payloads;
- wrong Z-Image VAE (`pixel_space`) causing `(1, 1, 16)` SaveImage failure.

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) and [`docs/TEST_LEDGER.md`](docs/TEST_LEDGER.md).

## Repository map

- [`AGENTS.md`](AGENTS.md) — operating contract for AI agents.
- [`docs/KNOWN_GOOD_RX6900XT.md`](docs/KNOWN_GOOD_RX6900XT.md) — exact proven machine/runtime state.
- [`docs/TEST_LEDGER.md`](docs/TEST_LEDGER.md) — empirical PASS / FAIL / FIXED history.
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — symptom → cause → fix.
- [`docs/SESSION_2026-08-17_18.md`](docs/SESSION_2026-08-17_18.md) — full successful ComfyUI/Z-Image session record.
- [`docs/Z_IMAGE_TURBO_RX6900XT.md`](docs/Z_IMAGE_TURBO_RX6900XT.md) — verified Z-Image recipe.
- [`docs/COMFYUI_SETUP.md`](docs/COMFYUI_SETUP.md) — current practical installer guide.
- [`docs/STACK_MATRIX.md`](docs/STACK_MATRIX.md) — workload/backend planning.
- [`docs/COMFYUI_PLAN.md`](docs/COMFYUI_PLAN.md) — broader image-generation plan.
- [`docs/UPSTREAM_SOURCES.md`](docs/UPSTREAM_SOURCES.md) — upstream facts that must be re-checked as they change.
- [`scripts/doctor.py`](scripts/doctor.py) — AMD PyTorch / MIOpen smoke test.
- [`workflows/Z_IMAGE_TURBO_RX6900XT_VERIFIED.json`](workflows/Z_IMAGE_TURBO_RX6900XT_VERIFIED.json) — real verified workflow.

## Golden rules

1. **Never install ordinary PyPI `torch` over a known-good TheRock environment.**
2. Treat `torch`, `torchvision`, and `torchaudio` as a protected matched stack.
3. New applications get their own venv.
4. Run the doctor before blaming ComfyUI, a model, a custom node, or AMD.
5. Treat CUDA-only extensions as compatibility blockers until a HIP/ROCm path is verified.
6. Snapshot exact package versions when a stack works.
7. Record failed routes so a future AI does not recommend them again.
8. Never promote an experiment to KNOWN GOOD without a real local PASS.

## Scope

This repository is intended to become the reusable AMD bootstrap for:

- ComfyUI / diffusion image models
- LoRA inference and training
- ControlNet / OpenPose / IP-Adapter
- Diffusers / Transformers
- segmentation / vision models
- RVC / audio AI
- LLM inference
- llama.cpp / HIP / ROCm engines
- model fine-tuning
- custom HIP-compatible ML workloads

The rule is: **test, measure, record, reuse**.
