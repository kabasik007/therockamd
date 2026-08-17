#!/usr/bin/env python3
"""Minimal AMD/TheRock PyTorch health check for RX 6900 XT / gfx1030.

No third-party dependencies beyond torch.
"""

from __future__ import annotations

import json
import platform
import sys
import traceback


def line(name: str, value) -> None:
    print(f"{name}: {value}")


def main() -> int:
    print("=" * 72)
    print("TheRock AMD Doctor")
    print("=" * 72)
    line("Python", sys.version.replace("\n", " "))
    line("Executable", sys.executable)
    line("Platform", platform.platform())
    line("Machine", platform.machine())

    try:
        import torch
    except Exception:
        print("\n[FAIL] import torch")
        traceback.print_exc()
        return 10

    print("\n[PyTorch]")
    line("torch.__version__", torch.__version__)
    line("torch.version.cuda", getattr(torch.version, "cuda", None))
    line("torch.version.hip", getattr(torch.version, "hip", None))
    line("torch.cuda.is_available()", torch.cuda.is_available())

    if not torch.cuda.is_available():
        print("\n[FAIL] GPU backend is not available through torch.cuda.")
        print("For ROCm PyTorch, torch.cuda is the normal compatibility namespace.")
        return 20

    try:
        device_count = torch.cuda.device_count()
        line("device_count", device_count)
        for idx in range(device_count):
            props = torch.cuda.get_device_properties(idx)
            print(f"\n[Device {idx}]")
            line("name", torch.cuda.get_device_name(idx))
            line("total_memory_GiB", round(props.total_memory / 1024**3, 2))
            line("properties", props)
    except Exception:
        print("\n[FAIL] GPU enumeration")
        traceback.print_exc()
        return 30

    try:
        print("\n[Test 1] Tensor allocation + matmul")
        x = torch.randn((1024, 1024), device="cuda")
        y = x @ x
        torch.cuda.synchronize()
        line("shape", tuple(y.shape))
        line("device", y.device)
        line("mean", float(y.mean()))
        print("[PASS] Tensor/matmul")
    except Exception:
        print("[FAIL] Tensor/matmul")
        traceback.print_exc()
        return 40

    try:
        print("\n[Test 2] MIOpen-style BatchNorm smoke test")
        m = torch.nn.BatchNorm2d(8).cuda().eval()
        z = torch.randn((1, 8, 64, 64), device="cuda")
        out = m(z)
        torch.cuda.synchronize()
        line("shape", tuple(out.shape))
        line("mean", float(out.mean()))
        print("[PASS] BatchNorm")
    except Exception:
        print("[FAIL] BatchNorm / MIOpen path")
        traceback.print_exc()
        return 50

    try:
        free_b, total_b = torch.cuda.mem_get_info()
        print("\n[Memory]")
        line("free_GiB", round(free_b / 1024**3, 2))
        line("total_GiB", round(total_b / 1024**3, 2))
    except Exception as exc:
        line("Memory query warning", repr(exc))

    print("\n" + "=" * 72)
    print("[PASS] AMD PyTorch base is healthy.")
    print("If an application still fails, debug the application/dependency layer first.")
    print("=" * 72)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
