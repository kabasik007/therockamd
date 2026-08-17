# AMD Test Ledger — RX 6900 XT / TheRock / ComfyUI

This is the canonical empirical history. Future agents should read it before trying a new installation path.

## Status meanings

- **PASS** — actually worked on the target machine.
- **FAIL** — actually failed; root cause identified or still under investigation.
- **FIXED** — failed first, then a concrete Bootstrap change solved it.
- **BLOCKED** — could not be tested because of an external dependency.
- **UPSTREAM** — documented upstream but not yet locally tested.
- **UNKNOWN** — evidence incomplete.

Do not erase failures. They are useful bootstrap knowledge.

## 2026-08-17 / 2026-08-18 — ComfyUI / Z-Image session ledger

| Seq | Area | Result | Observation / root cause | Resolution |
|---:|---|---|---|---|
| 1 | Python | PASS | Python 3.12.8 x64 available | Keep 3.12 baseline |
| 2 | TheRock torch gfx1030 | PASS | RX 6900 XT detected; GPU kernels execute | Preserve TheRock multi-arch stack |
| 3 | GPU matmul | PASS | GPU matmul succeeds | doctor gate |
| 4 | FP16 matmul | PASS | FP16 workload succeeds | doctor gate |
| 5 | Conv2d / MIOpen | PASS | Conv2d works despite CK grouped-conv warning | warning classified non-blocking |
| 6 | BAT logger v0.1.1 | FAIL/FIXED | PowerShell `WorkerArgument` required but launch supplied no usable value | removed brittle parameter design |
| 7 | BAT worker token | FAIL/FIXED | internal `worker` reached `main.py`; ComfyUI rejected `unrecognized arguments: worker` | consume worker internally / never forward it to app args |
| 8 | BAT `shift` | FAIL/FIXED | `shift` also shifted `%0`; `%~f0` became empty; logger got empty `BatPath` | never use `shift` before reading `%~f0` in this wrapper |
| 9 | ComfyUI dependency | FAIL/FIXED | `ModuleNotFoundError: torchaudio` because protected requirements filter skipped it | install/repair torchaudio from same TheRock multi-arch index |
| 10 | ComfyUI launch | PASS | server reached `http://127.0.0.1:8188` on native AMD/HIP | baseline accepted |
| 11 | Custom nodes | PASS | Manager, IPAdapter Plus, controlnet_aux import | baseline accepted |
| 12 | Duplicate ComfyUI instance | FAIL/FIXED | port 8188 already in use + SQLite `comfyui.db` lock | add reliable STOP switch; add launch port preflight |
| 13 | ComfyUI-Manager network | DEGRADED/PASS | registry fetch sometimes failed and fell back to local/raw GitHub list | not a GPU blocker |
| 14 | Z-Image template models | FAIL/FIXED | qwen + diffusion model missing; VAE also required | add script 14 official model installer |
| 15 | Z-Image sampling | PASS | Lumina2/Z-Image completed all 8 sampling steps at 1024x1024 | GPU/model path validated |
| 16 | Z-Image SaveImage | FAIL/FIXED | `Load VAE = pixel_space` returned 16-channel data; Pillow error `(1,1,16), |u1` | set `Load VAE = ae.safetensors` |
| 17 | Z-Image full generation | PASS | 1024x1024 image successfully decoded and displayed/saved | Z-Image Turbo promoted to VERIFIED |

## Important evidence from the successful path

The successful path is not merely “ComfyUI opened”. It passed these increasingly strong gates:

```text
TheRock import
  -> GPU detected
  -> matmul PASS
  -> FP16 PASS
  -> Conv2d/MIOpen PASS
  -> ComfyUI native HIP startup PASS
  -> custom nodes import PASS
  -> Z-Image text encoder load PASS
  -> Z-Image diffusion model load PASS
  -> 8/8 sampling PASS
  -> real VAE decode with ae.safetensors PASS
  -> Save Image PASS
```

## Earlier 2026-08-17 — NuovaRicambi Image Cleaner

### RX 6900 XT / TheRock PyTorch gfx1030

**Status:** PASS

**Install route:**

```bat
pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

**Reuse:** YES. This is the default Windows PyTorch route for this machine until a newer path is locally proven better.

### MIOpen BatchNorm smoke test

**Status:** PASS

```python
import torch
m = torch.nn.BatchNorm2d(8).cuda().eval()
x = torch.randn(1, 8, 64, 64, device="cuda")
y = m(x)
torch.cuda.synchronize()
print(y.shape, float(y.mean()))
```

Purpose: verify a real GPU neural-network primitive, not just `import torch`.

### NuovaRicambi Image Cleaner GPU architecture

**Status:** PASS

```text
TheRock ROCm PyTorch / gfx1030
-> DENet watermark/logo mask detection
-> BiRefNet segmentation
-> GPU batch pipeline
```

### DENet historical torch pins

**Status:** FAIL / DO NOT USE

```text
torch==1.8.1
torchvision==0.9.1
```

Reason: legacy dependencies would destroy the current AMD/TheRock runtime if installed blindly. Preserve modern TheRock PyTorch and adapt the old dependency set around it.

## Support-matrix facts recorded during the session

### AMD official Windows ROCm 7.2.1 production PyTorch route for RX 6900 XT

**Status:** NOT LISTED IN PRODUCTION PYTORCH MATRIX

This is a support-matrix fact, not a local runtime failure. The practical local route is TheRock `device-gfx1030` plus empirical validation.

### RX 6900 XT in Windows HIP SDK matrix

**Status:** UPSTREAM SUPPORTED

Recorded as:

```text
RDNA2 / gfx1030
Runtime: supported
HIP SDK: supported
```

## Known non-blocking messages seen during successful operation

- MIOpen `CK grouped conv library not found for device gfx1030` while Conv2d passes.
- `No OpenGL_accelerate module loaded`.
- Triton backend unavailable.
- ComfyUI-Manager registry/API fetch error with fallback.
- Legacy frontend API deprecation warnings from custom nodes.

Do not reinstall the AMD runtime solely because one of these messages appears.

## Next experiments to record

- LoRA inference
- ControlNet Canny
- ControlNet Depth
- OpenPose / DWPose generation
- IP-Adapter reference-image guidance
- inpainting
- upscaling
- SDXL
- additional diffusion architectures
- model training / fine-tuning
- RVC / audio workloads
- LLM workloads

# Template for new experiments

## YYYY-MM-DD — experiment name

**Status:** PASS / FAIL / BLOCKED / UPSTREAM / UNKNOWN

**Hardware:**

**OS / driver:**

**Python:**

**torch / torchvision / ROCm package versions:**

**Command / workflow settings:**

```text
...
```

**Result:**

```text
...
```

**Conclusion:**

**Safe to reuse:** YES / NO / WITH CONDITIONS
