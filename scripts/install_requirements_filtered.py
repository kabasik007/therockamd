from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile

BLOCKED_PREFIXES = (
    "torch",
    "torchvision",
    "torchaudio",
    "xformers",
    "triton",
    "flash-attn",
)

BLOCKED_FRAGMENTS = (
    "download.pytorch.org",
    "pytorch.org",
    "cu118",
    "cu121",
    "cu124",
)


def normalize(line: str) -> str:
    return line.strip()


def should_skip(line: str) -> bool:
    stripped = normalize(line)
    if not stripped or stripped.startswith("#"):
        return False

    lowered = stripped.lower()
    for prefix in BLOCKED_PREFIXES:
        if lowered == prefix or lowered.startswith(prefix + "=") or lowered.startswith(prefix + "["):
            return True
    return any(fragment in lowered for fragment in BLOCKED_FRAGMENTS)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: install_requirements_filtered.py <requirements.txt>")
        return 2

    req_path = pathlib.Path(sys.argv[1]).resolve()
    if not req_path.exists():
        print(f"[ERROR] requirements file not found: {req_path}")
        return 1

    lines = req_path.read_text(encoding="utf-8").splitlines()
    kept: list[str] = []
    skipped: list[str] = []

    for raw in lines:
        stripped = normalize(raw)
        if not stripped or stripped.startswith("#"):
            continue
        if should_skip(stripped):
            skipped.append(stripped)
        else:
            kept.append(stripped)

    print(f"[INFO] Source requirements: {req_path}")
    if skipped:
        print("[INFO] Skipping protected GPU packages to preserve TheRock:")
        for item in skipped:
            print(f"  - {item}")
    else:
        print("[INFO] No blocked packages found in requirements file.")

    if not kept:
        print("[INFO] Nothing to install after filtering.")
        return 0

    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as tmp:
        tmp.write("\n".join(kept) + "\n")
        tmp_path = pathlib.Path(tmp.name)

    print(f"[INFO] Installing filtered requirements from {tmp_path}")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "-r", str(tmp_path)], check=True)
    finally:
        try:
            tmp_path.unlink(missing_ok=True)
        except Exception:
            pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
