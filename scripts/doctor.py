from __future__ import annotations

import platform
import sys
import traceback


def line(name: str, value) -> None:
    print(f"{name}: {value}")


def fail(message: str, code: int = 1) -> int:
    print(f"[FAIL] {message}")
    return code


def main() -> int:
    print("=" * 68)
    print("TheRock AMD Doctor - RX 6900 XT / gfx1030 smoke test")
    print("=" * 68)
    line("Python", sys.version.replace("\n", " "))
    line("Executable", sys.executable)
    line("Platform", platform.platform())

    try:
        import torch
    except Exception as exc:
        traceback.print_exc()
        return fail(f"Cannot import torch: {exc}")

    line("torch", getattr(torch, "__version__", "unknown"))
    line("torch.version.hip", getattr(torch.version, "hip", None))
    line("torch.version.cuda", getattr(torch.version, "cuda", None))

    try:
        import torchaudio
        line("torchaudio", getattr(torchaudio, "__version__", "unknown"))
    except Exception as exc:
        traceback.print_exc()
        return fail(f"Cannot import torchaudio: {exc}. Current ComfyUI startup imports torchaudio.")

    if not torch.cuda.is_available():
        return fail("torch.cuda.is_available() is False. TheRock/HIP GPU backend is not active.")

    try:
        count = torch.cuda.device_count()
        line("GPU count", count)
        if count < 1:
            return fail("PyTorch reports no GPU devices.")

        props = torch.cuda.get_device_properties(0)
        name = torch.cuda.get_device_name(0)
        line("GPU 0", name)
        line("VRAM", f"{props.total_memory / (1024**3):.2f} GiB")

        a = torch.randn((1024, 1024), device="cuda", dtype=torch.float32)
        b = torch.randn((1024, 1024), device="cuda", dtype=torch.float32)
        c = a @ b
        torch.cuda.synchronize()
        line("Matmul", f"PASS mean={c.mean().item():.6f}")

        conv = torch.nn.Conv2d(3, 16, kernel_size=3, padding=1).to("cuda")
        x = torch.randn((2, 3, 256, 256), device="cuda")
        y = conv(x)
        torch.cuda.synchronize()
        line("Conv2d/MIOpen path", f"PASS shape={tuple(y.shape)}")

        try:
            ah = torch.randn((512, 512), device="cuda", dtype=torch.float16)
            bh = torch.randn((512, 512), device="cuda", dtype=torch.float16)
            ch = ah @ bh
            torch.cuda.synchronize()
            line("FP16 matmul", f"PASS mean={ch.float().mean().item():.6f}")
        except Exception as exc:
            line("FP16 matmul", f"WARN {type(exc).__name__}: {exc}")

        del a, b, c, conv, x, y
        try:
            del ah, bh, ch
        except Exception:
            pass
        torch.cuda.empty_cache()

    except Exception as exc:
        traceback.print_exc()
        return fail(f"GPU smoke test failed: {exc}")

    print("[PASS] AMD PyTorch GPU backend is working.")
    print("NOTE: PyTorch keeps the historical 'torch.cuda' API name on ROCm/HIP.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
