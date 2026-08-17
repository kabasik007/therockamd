# TheRock AMD Bootstrap — AI Agent Contract

Read this file before changing the AMD AI stack.

## Target machine

- OS: Windows 11 x64
- GPU: AMD Radeon RX 6900 XT 16 GB
- GPU architecture: RDNA2 / gfx1030
- Python baseline: 3.12 x64
- Primary GPU runtime: AMD TheRock multi-arch PyTorch / ROCm packages
- Primary UI: ComfyUI

## Non-negotiable rules

1. Do **not** assume the official AMD production PyTorch support matrix is the same thing as TheRock multi-arch support.
2. For this RX 6900 XT machine, preserve the proven TheRock `gfx1030` stack.
3. Never replace the working torch stack with generic PyPI CUDA/NVIDIA wheels.
4. Treat `torch`, `torchvision`, and `torchaudio` as one protected stack and install them from the same TheRock multi-arch index.
5. `torch.cuda` and `cuda:0` are historical PyTorch compatibility names on ROCm. They do not imply an NVIDIA GPU.
6. Before blaming ComfyUI, a model, or a custom node, run `scripts\doctor.py`.
7. Do not run a second ComfyUI instance on port 8188. Use `STOP_COMFYUI.bat` to terminate the instance belonging to this Bootstrap.
8. Keep separate venvs for unrelated AI applications. Do not destroy a known-good environment to test another project.
9. Record PASS / FAIL / BLOCKED experiments in `docs/TEST_LEDGER.md`.
10. Never promote a path to KNOWN GOOD without an actual local successful workload.

## Current proven stack

The following has been proven locally:

- TheRock PyTorch recognizes RX 6900 XT / gfx1030.
- GPU matmul: PASS.
- FP16 matmul: PASS.
- Conv2d / MIOpen path: PASS.
- ComfyUI starts on native AMD/HIP.
- DynamicVRAM is enabled.
- ComfyUI-Manager imports.
- ComfyUI_IPAdapter_plus imports.
- comfyui_controlnet_aux imports.
- Z-Image Turbo text-to-image: PASS at 1024x1024, 8 sampling steps.

See `docs/KNOWN_GOOD_RX6900XT.md` for exact observed versions.

## Known traps already encountered

Do not repeat these:

- Logger wrapper parameter mismatch (`WorkerArgument`).
- Internal `worker` token leaking into `ComfyUI main.py`.
- Windows BAT `shift` changing `%0`, making `%~f0` empty.
- Missing `torchaudio` after protecting torch packages from ComfyUI requirements.
- Starting a second ComfyUI instance, causing port 8188 conflict and SQLite lock.
- Z-Image template missing model files.
- Z-Image workflow selecting `pixel_space` instead of `ae.safetensors`, producing a 16-channel tensor that `SaveImage` cannot save.

See `docs/TROUBLESHOOTING.md` and `docs/TEST_LEDGER.md` before proposing a fix.

## Z-Image Turbo golden path

Use:

- `qwen_3_4b.safetensors` — `models\text_encoders`
- `z_image_turbo_bf16.safetensors` — `models\diffusion_models`
- `ae.safetensors` — `models\vae`

Critical: `Load VAE` must select **`ae.safetensors`**, not `pixel_space`.

A verified workflow is included at:

`workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json`

## Warnings that were observed but were not blockers

- `CK grouped conv library not found for device gfx1030` from MIOpen, while the actual Conv2d smoke test still passes.
- ComfyUI-Manager registry/network fetch failures that fall back to local/raw GitHub data.
- Legacy API deprecation warnings from custom node UI extensions.
- Missing `OpenGL_accelerate` while ComfyUI still starts and generates.
- Triton backend unavailable while HIP/eager backends remain available.

Do not treat these as root causes unless the actual workload fails at the same subsystem.

## Validation hierarchy

When something fails, isolate the layer in this order:

```text
1. Driver / Windows
2. Python architecture/version
3. TheRock torch import
4. torch.cuda.is_available()
5. GPU identity
6. basic tensor op
7. MIOpen convolution / BatchNorm
8. application import
9. one minimal model
10. optional plugin/custom node
```

Do not jump directly to reinstalling the whole stack.

## Earlier proven vision workload

The NuovaRicambi Image Cleaner stack is also a canonical local example:

```text
TheRock ROCm PyTorch / gfx1030
-> DENet watermark/logo mask detection
-> BiRefNet segmentation
-> GPU batch pipeline
```

Its historical DENet pins (`torch==1.8.1`, `torchvision==0.9.1`) must **not** be installed over the modern TheRock runtime.

## Recording new findings

Every meaningful test must be added to `docs/TEST_LEDGER.md` with:

- date
- workload
- exact environment
- exact command/settings
- result: PASS / FAIL / BLOCKED / UNKNOWN
- error if any
- action taken
- whether it is safe to reuse

## Sources that outrank assumptions

Priority order:

1. Local PASS/FAIL ledger in this repository
2. Exact installed package versions from the working machine
3. AMD ROCm / Radeon documentation
4. AMD TheRock release documentation and CI state
5. Upstream application documentation
6. Community reports
7. AI memory

If sources disagree, record the discrepancy instead of silently choosing one.
