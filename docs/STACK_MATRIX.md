# AMD AI Stack Matrix — RX 6900 XT / gfx1030

Status date: 2026-08-17

This matrix tells future AI agents which route to try first.

| Workload | Preferred route | Status | Notes |
|---|---|---|---|
| PyTorch core | TheRock multi-arch `device-gfx1030` | KNOWN GOOD | Do not replace with plain PyPI torch |
| Vision / segmentation | PyTorch + ROCm/MIOpen | KNOWN GOOD | NuovaRicambi cleaner is the reference workload |
| ComfyUI | Separate venv on TheRock torch | EXPERIMENTAL NEXT | Start minimal; add custom nodes later |
| SDXL inference | ComfyUI / PyTorch ROCm | EXPERIMENTAL NEXT | 16 GB VRAM is suitable for controlled testing |
| LoRA inference | ComfyUI | EXPERIMENTAL NEXT | Install after base SDXL workflow passes |
| ControlNet / OpenPose | ComfyUI | EXPERIMENTAL NEXT | Test one preprocessor/control model at a time |
| IP-Adapter / reference image | ComfyUI | EXPERIMENTAL NEXT | Add only after base generation is stable |
| Diffusers | Separate venv + TheRock torch | EXPERIMENTAL | Watch torch/transformers pins |
| Transformers | Separate venv + TheRock torch | EXPERIMENTAL | Windows ROCm docs recommend current transformers |
| Model training | Linux ROCm preferred | EXPERIMENTAL | AMD Windows ROCm 7.2.x docs state no ML training support in production Windows stack |
| RVC/audio AI | Separate venv | EXPERIMENTAL | Audit CUDA-only dependencies before install |
| llama.cpp | HIP/ROCm backend | LOCALLY USED / RECORD DETAILS | Keep independent from PyTorch environments |
| LM Studio | ROCm/llama.cpp engine where available | LOCALLY USED / RECORD DETAILS | Do not infer PyTorch compatibility from llama.cpp success |
| xformers | Verify wheel/backend first | RISK | Many install paths are NVIDIA/CUDA-oriented |
| bitsandbytes | Verify AMD support for exact version | RISK | Never install CUDA wheel blindly |
| flash-attn | Verify exact backend/build | RISK | CUDA-native assumptions are common |

## Environment separation

Recommended layout:

```text
AI/
  therockamd/
  ComfyUI/
    .venv_comfyui/
  DiffusersLab/
    .venv_diffusers/
  RVC/
    .venv_rvc/
  LLM/
    llama.cpp/
```

Each workload may use the same GPU but must not automatically share Python package state.

## ComfyUI acceptance gates

The ComfyUI stack is promoted to KNOWN GOOD only after these all pass:

1. `scripts/doctor.py` passes in the ComfyUI environment.
2. ComfyUI starts without dependency fallback to CPU.
3. One base checkpoint loads.
4. One 1024x1024 or suitable baseline image is generated.
5. A second generation completes without a memory/runtime crash.
6. LoRA is loaded and visibly affects output.
7. ControlNet/OpenPose completes one controlled-pose generation.
8. IP-Adapter/reference-image workflow completes.

Record exact model names, package versions, command-line flags, VRAM behavior, and timings in `TEST_LEDGER.md`.
