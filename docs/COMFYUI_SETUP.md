# ComfyUI setup on RX 6900 XT with TheRock

This is the current practical Windows bootstrap for the tested **AMD Radeon RX 6900 XT 16 GB / gfx1030** machine.

Before changing the runtime, read:

- `..\AGENTS.md`
- `KNOWN_GOOD_RX6900XT.md`
- `TEST_LEDGER.md`
- `TROUBLESHOOTING.md`

## Base setup

```bat
scripts\10_SETUP_COMFYUI_RX6900XT.bat
```

The base installer should:

- require Python 3.12 x64 and Git;
- create `workspace\comfyui\.venv`;
- install the protected TheRock trio from the multi-arch index:
  - `torch[device-gfx1030]`
  - `torchvision[device-gfx1030]`
  - `torchaudio`
- clone/update ComfyUI;
- install ComfyUI requirements while filtering packages that could replace the AMD runtime;
- run `scripts\doctor.py`;
- create common model folders.

## Why torch is protected

Do not let a generic requirement reinstall CUDA/NVIDIA or generic PyPI torch over this environment. The tested RX 6900 XT path depends on TheRock `device-gfx1030` packages.

PyTorch still uses API names such as `torch.cuda` and `cuda:0` on ROCm. On the verified machine ComfyUI reports:

```text
Device: cuda:0 AMD Radeon RX 6900 XT : native
```

That is AMD/HIP, not NVIDIA CUDA.

## Optional custom nodes

Manager:

```bat
scripts\12_INSTALL_COMFYUI_MANAGER.bat
```

Basic pose/reference stack:

```bat
scripts\13_INSTALL_BASIC_CUSTOM_NODES.bat
```

This installs:

- `comfyui_controlnet_aux`
- `ComfyUI_IPAdapter_plus`

Both imported successfully on the tested machine. Their actual generation workflows still need separate empirical PASS entries.

## Z-Image Turbo models

```bat
scripts\14_INSTALL_Z_IMAGE_TURBO_MODELS.bat
```

Installs:

```text
models\text_encoders\qwen_3_4b.safetensors
models\diffusion_models\z_image_turbo_bf16.safetensors
models\vae\ae.safetensors
```

## Verified Z-Image Turbo workflow

Use:

```text
workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json
```

Critical setting:

```text
Load VAE = ae.safetensors
```

Do not use `pixel_space`. That exact mistake completed 8/8 sampling and then failed at `SaveImage` because a 16-channel tensor reached Pillow.

## Start / stop

Start:

```bat
scripts\11_LAUNCH_COMFYUI_RX6900XT.bat
```

Default URL:

```text
http://127.0.0.1:8188/
```

Do not rely on Ctrl+C for this Bootstrap. Stop with:

```bat
STOP_COMFYUI.bat
```

The stopper must identify the ComfyUI process belonging to this exact Bootstrap and must not kill unrelated Python processes.

The launcher should refuse to start a second copy when port 8188 is already occupied; this prevents both the observed HTTP conflict and `comfyui.db` SQLite lock.

## Known non-blocking warnings

Observed during successful operation:

- MIOpen CK grouped-conv runtime warning for gfx1030;
- `No OpenGL_accelerate module loaded`;
- Triton backend unavailable;
- ComfyUI-Manager registry/network fallback;
- legacy frontend API warnings from custom nodes.

These are not sufficient reasons to reinstall the AMD stack. Diagnose the operation that actually fails.

## Output

Default generated images:

```text
workspace\comfyui\ComfyUI\output\
```

## Logging policy

BAT wrappers should keep the console open and mirror output to `logs\`. Preserve the newest relevant log and add the result to `docs\TEST_LEDGER.md` instead of blindly reinstalling.
