# Upstream sources

Last reviewed: 2026-08-17

This file exists so future agents verify changing upstream facts instead of treating old chat memory as current truth.

## AMD TheRock

Primary release/install documentation:

https://github.com/ROCm/TheRock/blob/main/RELEASES.md

Relevant current facts at review time:

- TheRock uses multi-arch packaging with per-device extras.
- RX 6900 XT / RX 6800 XT are mapped to `gfx1030` / `device-gfx1030`.
- Windows PyTorch Python packages are available in the multi-arch release system.
- PyTorch packages automatically depend on compatible ROCm packages.
- Nightly packages may be unstable and should be validated locally.

## AMD Radeon Windows PyTorch compatibility

https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityrad/windows/windows_compatibility.html

Relevant fact at review time:

The ROCm 7.2.1 Windows production PyTorch matrix does not list RX 6900 XT / gfx1030.

This is a production support matrix statement, not proof that TheRock cannot run on gfx1030.

## AMD HIP SDK Windows hardware support

https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/shared/hipsdk/reference/system-requirements.html

Relevant fact at review time:

RX 6900 XT is listed as RDNA2 / gfx1030 with Runtime and HIP SDK support.

## AMD Windows ROCm limitations

https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/limitations/limitationsrad.html

Relevant facts at review time include:

- Windows production ROCm support is narrower than Linux.
- Python 3.12 is the supported Python baseline for the current Windows PyTorch release.
- AMD documents no ML training support for the current Windows production stack.
- `--lowvram` and `--disable-pinned-memory` may help some ComfyUI configurations.

## Update policy

Before making a major change such as:

- moving away from TheRock,
- changing Python minor version,
- changing torch major/minor version,
- adopting a new ROCm Windows release,
- enabling training on Windows,
- replacing the ComfyUI backend,

re-check these sources and add a dated note to `TEST_LEDGER.md`.
