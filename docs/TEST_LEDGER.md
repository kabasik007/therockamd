# AMD Test Ledger

This is the canonical history of what was actually tried.

Use one of these statuses:

- `PASS` — locally confirmed working.
- `FAIL` — locally confirmed not working.
- `BLOCKED` — could not complete because of another dependency/problem.
- `UPSTREAM` — documented upstream but not yet locally tested.
- `UNKNOWN` — evidence incomplete.

Do not erase failures. They are useful bootstrap knowledge.

## 2026-08-17 — RX 6900 XT / TheRock PyTorch gfx1030

**Status:** PASS

**Target:** Windows / AMD Radeon RX 6900 XT 16 GB / RDNA2 / gfx1030.

**Install route:**

```bat
pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]"
```

**Evidence:** The supplied `NuovaRicambi_ImageCleaner_RX6900XT_v0.3.0` package uses this as its AMD setup path.

**Reuse:** YES. This is the default Windows PyTorch route for this machine until a newer path is locally proven better.

---

## 2026-08-17 — MIOpen BatchNorm smoke test

**Status:** PASS

**Test pattern:**

```python
import torch
m = torch.nn.BatchNorm2d(8).cuda().eval()
x = torch.randn(1, 8, 64, 64, device="cuda")
y = m(x)
torch.cuda.synchronize()
print(y.shape, float(y.mean()))
```

**Purpose:** Verify that a real GPU neural-network primitive works, not just `import torch`.

**Reuse:** YES. Keep this in every doctor script.

---

## 2026-08-17 — NuovaRicambi Image Cleaner GPU architecture

**Status:** PASS

**Stack:**

```text
TheRock ROCm PyTorch / gfx1030
-> DENet watermark/logo mask detection
-> BiRefNet segmentation
-> GPU batch pipeline
```

**Notes:** The application explicitly raises an error when `torch.cuda.is_available()` is false. It is therefore designed to fail fast rather than silently process on CPU.

**Reuse:** YES. Useful reference implementation for other vision workloads.

---

## 2026-08-17 — DENet historical torch pins

**Status:** FAIL / DO NOT USE

Historical dependency pins:

```text
torch==1.8.1
torchvision==0.9.1
```

**Reason:** They are legacy dependencies and would destroy the current AMD/TheRock runtime if installed blindly.

**Action:** Preserve modern TheRock PyTorch; adapt DENet dependencies around it.

**Reuse:** NO.

---

## 2026-08-17 — AMD official Windows ROCm 7.2.1 production PyTorch route for RX 6900 XT

**Status:** NOT LISTED IN PRODUCTION PYTORCH MATRIX

AMD's current Windows ROCm 7.2.1 Radeon PyTorch matrix lists newer gfx11/gfx12 products and does not list RX 6900 XT/gfx1030.

This is not recorded as a local runtime failure. It is a support-matrix fact.

**Action:** Use TheRock `device-gfx1030` and validate locally.

---

## 2026-08-17 — RX 6900 XT in Windows HIP SDK matrix

**Status:** UPSTREAM SUPPORTED

AMD lists RX 6900 XT as:

```text
RDNA2 / gfx1030
Runtime: supported
HIP SDK: supported
```

This explains why `gfx1030` remains a legitimate Windows HIP target even though the production Windows PyTorch matrix is narrower.

---

# Template for new experiments

## YYYY-MM-DD — experiment name

**Status:** PASS / FAIL / BLOCKED / UPSTREAM / UNKNOWN

**Hardware:**

**OS / driver:**

**Python:**

**torch / torchvision / ROCm package versions:**

**Command:**

```text
...
```

**Result:**

```text
...
```

**Conclusion:**

**Safe to reuse:** YES / NO / WITH CONDITIONS
