# Known-good RX 6900 XT state

Status: **VERIFIED LOCALLY**

Last verified during the 2026-08-17 / 2026-08-18 Windows test session.

## Hardware / OS

| Item | Observed value |
|---|---|
| GPU | AMD Radeon RX 6900 XT |
| Architecture | gfx1030 / RDNA2 |
| VRAM | 15.98 GiB reported by doctor; ComfyUI reports 16368 MB |
| OS | Windows 11, build family 10.0.26100 |
| Python | 3.12.8 x64 |

## PyTorch / TheRock

Observed working environment:

```text
torch                  2.13.0+rocm10.1.0a20260817
torchvision            0.28.0+rocm10.1.0a20260817
amd-torch-device-gfx1030       2.13.0+rocm10.1.0a20260817
amd-torchvision-device-gfx1030 0.28.0+rocm10.1.0a20260817
rocm package           10.1.0a20260817
rocm-sdk-device-gfx1030 10.1.0a20260817
torch.version.hip      7.16.26323
torch.version.cuda     None
```

ComfyUI reported:

```text
AMD arch: gfx1030
ROCm version: (7, 16)
Device: cuda:0 AMD Radeon RX 6900 XT : native
```

The `cuda:0` label is the historical PyTorch device API namespace. This is still the AMD ROCm/HIP backend.

## Smoke tests

`scripts\doctor.py` has passed on the real machine:

```text
GPU count: 1
GPU 0: AMD Radeon RX 6900 XT
Matmul: PASS
Conv2d/MIOpen path: PASS
FP16 matmul: PASS
[PASS] AMD PyTorch GPU backend is working.
```

A MIOpen warning about the CK grouped convolution runtime library was observed, but the actual Conv2d/MIOpen smoke test passed. Therefore the warning alone is not a failure condition for this stack.

## ComfyUI

Observed working values during successful launch:

```text
ComfyUI version: 0.33.0
Git description observed: v0.33.0-19-gc1739380
comfyui-frontend-package: 1.49.6
comfyui-workflow-templates: 0.11.43
comfyui-embedded-docs: 0.5.10
comfy-kitchen: 0.2.31
comfy-aimdo: 0.4.13
```

Observed runtime behavior:

- HIP backend available and enabled.
- eager backend available and enabled.
- Triton backend unavailable / disabled.
- DynamicVRAM detected and enabled.
- `NORMAL_VRAM` selected.
- async weight offloading enabled with 2 streams.
- pinned memory enabled.
- server starts at `http://127.0.0.1:8188`.

## Custom nodes verified to import

- `ComfyUI-Manager`
- `ComfyUI_IPAdapter_plus`
- `comfyui_controlnet_aux`
- `websocket_image_save.py`

DWPose reported ONNX Runtime acceleration providers available during import.

## Z-Image Turbo — VERIFIED PASS

The following exact class of workflow generated a real 1024x1024 image on RX 6900 XT:

```text
Text encoder : qwen_3_4b.safetensors
CLIP type    : lumina2
Diffusion    : z_image_turbo_bf16.safetensors
VAE          : ae.safetensors
Resolution   : 1024 x 1024
Batch        : 1
Steps        : 8
CFG          : 1.0
Sampler      : res_multistep
Scheduler    : simple
Denoise      : 1.0
Seed tested  : 42
Sampling     : completed 8/8
```

A previous run completed sampling but failed at `SaveImage` because the VAE selector was accidentally set to `pixel_space`. Changing it to `ae.safetensors` produced the successful image.

Verified workflow:

`workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json`

## Earlier verified vision workload

The NuovaRicambi Image Cleaner architecture was also proven on this machine using the same TheRock `gfx1030` route:

```text
TheRock ROCm PyTorch / gfx1030
-> DENet watermark/logo mask detection
-> BiRefNet segmentation
-> GPU batch pipeline
```

The key preservation rule from that project still applies: do not install historical model pins such as `torch==1.8.1` / `torchvision==0.9.1` over the working modern runtime.

## What is NOT yet verified

Do not infer success for these just because ComfyUI starts:

- LoRA inference on this exact stack
- LoRA training
- ControlNet generation on this exact stack
- OpenPose-driven generation
- IP-Adapter generation
- FLUX-class workflows
- SDXL on this exact Bootstrap
- RVC/audio workloads
- LLM inference/training

They remain future test items until recorded in `TEST_LEDGER.md`.
