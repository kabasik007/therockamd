# Troubleshooting — issues already encountered

## `Missing an argument for parameter 'WorkerArgument'`

**Layer:** Bootstrap logger, not AMD.

The PowerShell wrapper had a mandatory parameter whose value was not correctly supplied by the BAT launcher.

**Rule:** keep the wrapper interface minimal. Current logger launches the BAT with a plain internal `worker` token.

---

## `main.py: error: unrecognized arguments: worker`

**Layer:** Bootstrap launcher, not ComfyUI/AMD.

The internal control token leaked into `%*` and reached ComfyUI.

**Fix:** never forward the Bootstrap worker token to application arguments.

---

## `Cannot bind argument to parameter 'BatPath' because it is an empty string`

**Layer:** Windows BAT semantics.

Root cause: `shift` was executed before `%~f0` was reused. Windows `shift` shifts `%0` too, so the BAT path disappeared.

**Fix:** do not use `shift` in this wrapper before reading `%~f0`.

---

## `ModuleNotFoundError: No module named 'torchaudio'`

**Layer:** protected TheRock dependency set.

The requirements filter correctly protected `torch`/`torchvision` from replacement, but `torchaudio` was absent while current ComfyUI imports it during startup.

**Fix:** install `torchaudio` from the **same TheRock multi-arch index** as the working gfx1030 torch/torchvision packages. The launcher should check and repair it before startup.

---

## `Port 8188 is already in use` + `Could not acquire lock on ... comfyui.db`

**Layer:** process lifecycle.

A previous ComfyUI Python process survived after its console window was closed. Starting a second process caused both the HTTP port collision and SQLite database lock.

**Fix:** use:

```bat
STOP_COMFYUI.bat
```

Do not kill every `python.exe`; the stopper validates that the process belongs to this Bootstrap.

The launcher should have a port preflight and refuse to start a second copy on 8188.

---

## Z-Image template reports missing models

Required official files:

```text
models\text_encoders\qwen_3_4b.safetensors
models\diffusion_models\z_image_turbo_bf16.safetensors
models\vae\ae.safetensors
```

Install with:

```bat
scripts\14_INSTALL_Z_IMAGE_TURBO_MODELS.bat
```

The downloader supports resume, size verification, and SHA-256 verification.

---

## `Cannot handle this data type: (1, 1, 16), |u1`

**Layer:** workflow configuration, not AMD.

Observed chain:

```text
sampling completed 8/8
-> Requested to load PixelspaceConversionVAE
-> SaveImage received 16-channel data
-> Pillow Image.fromarray failed
```

Root cause: the Z-Image workflow `Load VAE` node was set to `pixel_space`.

**Fix:** select:

```text
ae.safetensors
```

Use `workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json` to avoid this mistake.

---

## MIOpen warning: `CK grouped conv library not found for device gfx1030`

This warning was present while the actual `Conv2d/MIOpen path` smoke test passed.

**Current classification:** non-blocking warning for the tested workloads.

Do not reinstall the whole stack solely because of this warning.

---

## `No OpenGL_accelerate module loaded`

Observed during successful ComfyUI startup.

**Current classification:** non-blocking for image generation tested so far.

---

## ComfyUI-Manager cannot connect to registry

Observed behavior:

- API fetch failed / invalid response.
- Manager switched to local/raw GitHub data.
- startup completed.

**Current classification:** network/registry degradation, not AMD GPU failure.

---

## Legacy API deprecation warnings from custom nodes

Examples include imports of old `/scripts/ui.js` and old UI component APIs.

**Current classification:** technical debt in extensions; not a blocker for the verified Z-Image generation.

Update extensions when practical, but do not confuse these warnings with ROCm failure.
