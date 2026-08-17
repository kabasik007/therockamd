# ComfyUI plan — RX 6900 XT / TheRock

Goal: build a local image-generation lab on RX 6900 XT without sacrificing the already proven AMD runtime.

## Desired capabilities

```text
Base checkpoint
+ LoRA
+ ControlNet
  - OpenPose
  - Depth
  - Canny / Lineart
+ reference image / IP-Adapter
+ img2img
+ inpaint / outpaint
+ face/detail pass
+ upscale
```

## Installation strategy

Do **not** begin from an installer that silently replaces torch.

Preferred sequence:

```text
1. clean Python 3.12 venv
2. TheRock torch[device-gfx1030]
3. run AMD doctor
4. install ComfyUI application dependencies while preserving torch
5. start bare ComfyUI
6. test one base model
7. freeze environment
8. add LoRA
9. add ControlNet/OpenPose
10. add IP-Adapter
11. add optional custom nodes one group at a time
```

## Phase 1 — bare ComfyUI

Acceptance criteria:

- TheRock doctor passes.
- ComfyUI starts.
- GPU remains RX 6900 XT.
- No silent CPU fallback.
- One standard generation completes.
- Record peak VRAM and generation time.

Do not install a large custom-node pack yet.

## Phase 2 — LoRA

Test one known-compatible LoRA and compare:

```text
strength 0.0
strength 0.5
strength 0.8
strength 1.0
```

The output difference confirms the LoRA path is actually active.

## Phase 3 — pose control

Target: ControlNet OpenPose or the current equivalent supported by the selected model family.

Test sequence:

```text
reference human image
-> pose preprocessor
-> pose skeleton
-> ControlNet conditioning
-> generation
```

Record which preprocessor nodes are AMD-safe. Preprocessors can have different dependencies from the diffusion model itself.

## Phase 4 — reference image

Add IP-Adapter/reference conditioning only after ControlNet works.

Test identity/style/composition separately. Do not use five controls simultaneously for the first validation.

## Phase 5 — editing

Add:

- img2img
- inpaint
- outpaint
- detail/face pass
- upscale

Each new feature gets one isolated PASS entry.

## Model-family strategy

Start with the easiest stable family for the current AMD runtime rather than the newest model on day one.

Suggested validation order:

```text
SDXL-class baseline
-> LoRA
-> ControlNet
-> IP-Adapter
-> newer/large models
```

The newest model family can be tested after the mechanics of ComfyUI are proven.

## Dependency red flags

Pause before installing any custom node that automatically requests:

```text
pip install torch
pip install torch==...
pip install torchvision==...
xformers
flash-attn
bitsandbytes
triton package with NVIDIA assumptions
CUDA Toolkit
nvcc
```

Read its requirements and adapt around the TheRock base.

## Windows flags

AMD's current Windows Radeon ROCm docs mention `--lowvram` and `--disable-pinned-memory` as possible ComfyUI aids for lower-memory configurations. RX 6900 XT has 16 GB VRAM, so these are troubleshooting flags, not the mandatory default.

## Promotion to known-good

When this stack passes, add to the test ledger:

```text
ComfyUI commit/version
Python version
torch version
torchvision version
TheRock package/device target
AMD driver version
model/checkpoint
resolution
sampler/steps
VRAM peak
time per image
required launch flags
custom node versions
LoRA PASS
OpenPose PASS
IP-Adapter PASS
```

Then export a frozen known-good environment and never casually mutate it.
