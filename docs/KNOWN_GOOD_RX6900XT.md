# Known-good baseline — RX 6900 XT / Windows

Status date: 2026-08-17

## Hardware

| Item | Value |
|---|---|
| GPU | AMD Radeon RX 6900 XT |
| VRAM | 16 GB |
| Architecture | RDNA2 |
| LLVM/GFX target | gfx1030 |
| OS | Windows 11 |

## Support reality

### AMD Windows HIP SDK

RX 6900 XT is listed by AMD as:

```text
RDNA2
LLVM target: gfx1030
Runtime: supported
HIP SDK: supported
```

### AMD production PyTorch matrix

The ROCm 7.2.1 Windows PyTorch production matrix currently lists gfx1201/gfx1200/gfx1100/gfx1101 Radeon products, not RX 6900 XT / gfx1030.

This does not invalidate TheRock.

### AMD TheRock

TheRock multi-arch packages separate GPU-specific device kernels from common host packages. The supported device extras include the gfx target selected during installation.

For this machine the working route is:

```bat
pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

Nightlies are not equivalent to AMD's production support guarantee. They must be validated locally.

## Local proven stack

The NuovaRicambi Image Cleaner v0.3.0 archive supplied on 2026-08-17 contains an AMD setup script that installs exactly:

```bat
"torch[device-gfx1030]"
"torchvision[device-gfx1030]"
```

from:

```text
https://rocm.nightlies.amd.com/whl-multi-arch/
```

The same package contains a MIOpen BatchNorm smoke test and application safeguards against legacy DENet torch pins.

This path has therefore moved from theory to **local known-good architecture**.

## Python

Use Python 3.12 x64 as the conservative default for current Windows ROCm work.

Do not upgrade an established working environment to another Python minor version just because the new application itself supports it.

## Minimum acceptance test

A Python environment is not accepted as known-good until all of these pass:

```python
import torch
assert torch.cuda.is_available()
print(torch.__version__)
print(torch.cuda.get_device_name(0))

x = torch.randn(1024, 1024, device="cuda")
y = x @ x
assert y.is_cuda

torch.cuda.synchronize()

m = torch.nn.BatchNorm2d(8).cuda().eval()
z = torch.randn(1, 8, 64, 64, device="cuda")
out = m(z)
torch.cuda.synchronize()
print(out.shape)
```

Expected GPU identity must resolve to RX 6900 XT or the actual AMD adapter, not CPU emulation.

## Preservation rule

Once an environment passes:

```bat
python -m pip freeze > requirements-known-good.txt
python scripts\doctor.py > doctor-known-good.txt
```

Then clone or create a new venv for experiments. Never use a passing environment as a scratchpad.
