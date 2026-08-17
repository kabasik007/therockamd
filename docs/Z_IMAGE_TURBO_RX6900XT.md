# Z-Image Turbo on RX 6900 XT — verified recipe

Status: **PASS**

## Required model files

```text
models\text_encoders\qwen_3_4b.safetensors
models\diffusion_models\z_image_turbo_bf16.safetensors
models\vae\ae.safetensors
```

Install them with:

```bat
scripts\14_INSTALL_Z_IMAGE_TURBO_MODELS.bat
```

## Critical VAE setting

The workflow must use:

```text
Load VAE -> ae.safetensors
```

Do **not** use `pixel_space` for this workflow. That path completed sampling but produced a 16-channel tensor that `SaveImage` could not convert to a normal image.

## Verified settings

```text
Resolution   1024 x 1024
Batch        1
Seed         42
Steps        8
CFG          1.0
Sampler      res_multistep
Scheduler    simple
Denoise      1.0
Model shift  3
```

Models:

```text
CLIP loader  qwen_3_4b.safetensors
CLIP type    lumina2
UNET         z_image_turbo_bf16.safetensors
weight dtype default
VAE          ae.safetensors
```

## Verified execution behavior

The first almost-successful run proved the expensive part already worked:

```text
ZImageTEModel prepared
Lumina2 prepared
8 / 8 sampling completed
```

It then failed only because `pixel_space` was selected as VAE.

After switching to `ae.safetensors`, ComfyUI decoded and displayed a real 1024x1024 image successfully.

## Verified workflow file

Use:

`workflows\Z_IMAGE_TURBO_RX6900XT_VERIFIED.json`

This file is based on the exact tested workflow with the VAE selection corrected to `ae.safetensors`.
