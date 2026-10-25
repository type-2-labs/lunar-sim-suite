# OmniLRS on Vast

[OmniLRS](https://github.com/OmniLRS/OmniLRS) v3.0.0 (BSD-3) is a lunar surface simulator built on NVIDIA Isaac Sim:
procedural lunar yards, south-pole scenes from real LOLA elevation maps, sun and Earth placement from ephemeris,
rovers driven over ROS 2.

The Vast template starts NVIDIA's official `nvcr.io/nvidia/isaac-sim:5.0.0` image and runs `setup.sh` on boot, which
installs OmniLRS into `/workspace/omnilrs` (about 10 minutes; progress in `/var/log/omnilrs-setup.log`, done when
`/workspace/omnilrs/.ready` exists). NVIDIA's software comes straight from NVIDIA under its own license; using the
template means accepting the [NVIDIA Isaac Sim license](https://docs.isaacsim.omniverse.nvidia.com/latest/common/NVIDIA_Omniverse_License_Agreement.html).

Needs an RTX card (RT cores): RTX 3090/4090/5090, RTX A5000/A6000, L40S. Not A100 or H100.

## Check it renders

```bash
omnilrs snapshot.py lunaryard_20m /workspace/snapshots
```

Writes three 1280×720 views of the 20 m lunar yard (with OmniLRS's default rover) to `/workspace/snapshots`, about
5 minutes including Isaac Sim's start-up. Tested on an RTX 3090, 2026-10-24.

## Run a scene

```bash
omnilrs run.py environment=lunaryard_20m mode=ROS2 rendering.renderer.headless=True
```

`omnilrs` runs a script from `/workspace/omnilrs` with Isaac Sim's Python and the ROS 2 settings (also in
`/workspace/omnilrs/env.sh`).

Other scenes are in `cfg/environment/`. South-pole `largescale` scenes need the elevation maps: boot with
`OMNILRS_DEMS=1`, or run `./scripts/install_docker.sh` in `/workspace/omnilrs`.

## Known problem

OmniLRS v3.0.0's synthetic-data mode (`mode=SDG`) renders almost black images on Isaac Sim 5.0 (tested 2026-10-24).
`setup.sh` fixes the out-of-date setting that stopped it starting at all, but the lighting problem is upstream.
Use `run.py` in ROS 2 mode, or `snapshot.py`, for images.
