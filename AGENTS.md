# AGENTS.md — AMD / ROCm Operating Contract

This file is the first thing an AI agent should read before changing, installing, debugging, or recommending anything related to AMD GPU compute on this machine.

## Primary target

- GPU: AMD Radeon RX 6900 XT 16 GB
- Architecture: RDNA2
- GFX target: gfx1030
- OS: Windows 11
- Current preferred Python baseline: 3.12 x64
- Preferred PyTorch route: AMD TheRock multi-arch packages

## Critical distinction

There are two different questions:

1. Is RX 6900 XT listed in AMD's official production PyTorch support matrix for a given ROCm release?
2. Is gfx1030 supported by a usable TheRock multi-arch package?

These are **not the same thing**.

As of 2026-08-17:

- AMD's Windows ROCm 7.2.1 production PyTorch matrix does not list RX 6900 XT / gfx1030.
- AMD's Windows HIP SDK matrix does list RX 6900 XT as RDNA2 / gfx1030 with Runtime and HIP SDK support.
- AMD TheRock multi-arch packaging supports per-device extras and provides a `device-gfx1030` route.
- TheRock Windows PyTorch packages are available, but nightly packages can be unstable.

Therefore:

> Do not reject RX 6900 XT simply because the production PyTorch compatibility table omits it. Check the TheRock path and the local test ledger first.

## Known-good install command

```bat
py -3.12 -m venv .venv
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

## Mandatory preflight

Before changing packages, run:

```bat
.venv\Scripts\python.exe scripts\doctor.py
.venv\Scripts\python.exe -m pip freeze > before-change-freeze.txt
```

If the doctor passes, assume the AMD/PyTorch base is healthy until the application layer is proven otherwise.

## Forbidden default behavior

An AI agent must NOT automatically:

- replace TheRock torch with plain `pip install torch`;
- install NVIDIA CUDA Toolkit as a fix for a ROCm/HIP issue;
- assume `torch.cuda` means NVIDIA CUDA;
- downgrade torch just because an old repository pins CUDA-era versions;
- install an old project's historical torch/torchvision pins before checking compatibility;
- destroy a working venv to test a new framework;
- mix unrelated ComfyUI, RVC, LLM, vision, and training dependencies in one environment;
- claim RX 6900 XT is unsupported without stating which support layer is meant;
- claim a new stack is known-good without recording a local successful test.

## Dependency policy

Each application gets its own venv:

```text
.venv_comfyui
.venv_diffusers
.venv_rvc
.venv_llm
.venv_vision
```

If a project ships requirements that pin torch, torchvision, xformers, triton, bitsandbytes, flash-attn, CUDA extensions, or another GPU runtime, inspect those pins before installation.

Prefer:

```text
install TheRock torch first
-> install application deps without replacing torch
-> smoke test
-> only then add optional accelerators/custom nodes
```

## CUDA-language translation

Many Python projects use CUDA terminology even when running on AMD.

Examples:

```python
torch.cuda.is_available()
torch.cuda.get_device_name(0)
tensor.cuda()
```

With ROCm PyTorch these APIs can be valid on AMD. Do not rewrite them purely because the machine has no NVIDIA card.

But native CUDA dependencies are different. Treat these as suspicious until verified:

- custom `.cu` extensions
- nvcc build steps
- NVIDIA-only xformers wheels
- bitsandbytes CUDA wheels
- flash-attn CUDA builds
- TensorRT
- CUDA graphs/extensions that explicitly require NVIDIA

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

## Known local proof

The NuovaRicambi Image Cleaner project used the following setup command:

```bat
pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

Its doctor includes a GPU BatchNorm smoke test. The project also explicitly protects the environment from DENet's historical `torch==1.8.1 / torchvision==0.9.1` pins.

That is a canonical example of how old model repositories should be integrated: preserve the modern working GPU runtime and adapt the old dependency set around it.

## Recording new findings

Every meaningful test must be added to `docs/TEST_LEDGER.md` with:

- date
- workload
- exact environment
- exact command
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
