TheRock AMD / RX 6900 XT / ComfyUI Bootstrap
Version 0.1.8

THIS VERSION IS A KNOWLEDGE CHECKPOINT
--------------------------------------
This repository records the complete successful Windows RX 6900 XT session:
what worked, what failed, why it failed, and what must not be repeated.

READ FIRST
----------
  AGENTS.md
  docs\KNOWN_GOOD_RX6900XT.md
  docs\TEST_LEDGER.md
  docs\TROUBLESHOOTING.md

CURRENT VERIFIED MACHINE STATE
------------------------------
- AMD Radeon RX 6900 XT / gfx1030: PASS.
- Python 3.12.8 x64: PASS.
- TheRock PyTorch gfx1030: PASS.
- GPU matmul: PASS.
- Conv2d/MIOpen path: PASS.
- FP16 matmul: PASS.
- ComfyUI native AMD/HIP startup: PASS.
- DynamicVRAM: enabled.
- ComfyUI-Manager: imports.
- ComfyUI_IPAdapter_plus: imports.
- comfyui_controlnet_aux: imports.
- Z-Image Turbo 1024x1024 / 8 steps: VERIFIED PASS with a real output image.

Z-IMAGE TURBO GOLDEN RULE
-------------------------
Correct VAE:

  ae.safetensors

Do NOT select:

  pixel_space

The pixel_space mistake was tested and causes SaveImage to fail with a
16-channel array after sampling has already completed.

START / STOP
------------
Start:

  scripts\11_LAUNCH_COMFYUI_RX6900XT.bat

Stop reliably:

  STOP_COMFYUI.bat

IMPORTANT NON-BLOCKING WARNINGS OBSERVED
----------------------------------------
- MIOpen CK grouped-conv warning on gfx1030 while Conv2d passes.
- Missing OpenGL_accelerate.
- Triton unavailable.
- ComfyUI-Manager registry/network fallback.
- Legacy custom-node frontend API deprecation warnings.

Do not reinstall the AMD stack merely because one of these warnings appears.
Look for the actual failing operation first.
