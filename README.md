# Lunar Sim Suite

**A low-cost lunar rover testing suite from Type 2 Labs.** Ready-to-run Docker images of open-source
simulation tools: soil and wheels, structures and launch loads, thermal, radio, and full-robot simulation.
You rent a GPU or CPU machine by the hour, run the image, copy your results back, and shut it down.
No local install, no NVIDIA card needed on your own computer.

Every image is built in public by GitHub Actions from a short Dockerfile you can read.

## The images

| Tool | Image | What it's for on a rover | Machine | Build |
|---|---|---|---|---|
| [Project Chrono](https://projectchrono.org) 10.0.0 | `ghcr.io/type-2-labs/chrono:10.0.0-cuda12.8` | Wheel and rover driving on deformable soil (GPU granular "CRM" soil, SCM soil), vehicle and robot dynamics. Python (`pychrono`) and C++ demos | NVIDIA GPU | [![build](https://github.com/type-2-labs/chrono-docker/actions/workflows/build.yml/badge.svg)](https://github.com/type-2-labs/chrono-docker) |
| [Chrono DEM-Engine](https://github.com/projectchrono/DEM-Engine) 3.0.19 | `ghcr.io/type-2-labs/deme:3.0.19-cuda12.8` | Soil as individual grains (discrete element method): wheel/grouser traction, sinkage, digging. A second, independent soil method to check Chrono's | NVIDIA GPU | [![build](https://github.com/type-2-labs/deme-docker/actions/workflows/build.yml/badge.svg)](https://github.com/type-2-labs/deme-docker) |
| [code_aster](https://code-aster.org) 18.1.0 | `simvia/code_aster:18.1.0` (official, by Simvia) | Structural FEM: stress, modes, random vibration and shock for launch loads | CPU | official image |
| [Elmer FEM](https://www.csc.fi/web/elmer) 9.0 | `ghcr.io/type-2-labs/elmer:9.0` | Thermal with radiation (sun, lunar surface, deep space), heat leaks into electronics, multiphysics | CPU | [![build](https://github.com/type-2-labs/elmer-docker/actions/workflows/build.yml/badge.svg)](https://github.com/type-2-labs/elmer-docker) |
| [openEMS](https://openems.de) 0.37.0 | `ghcr.io/type-2-labs/openems:0.37.0` | Antennas and radio (FDTD): antenna patterns on the rover body, link to the lander | CPU | [![build](https://github.com/type-2-labs/openems-docker/actions/workflows/build.yml/badge.svg)](https://github.com/type-2-labs/openems-docker) |
| [NVIDIA Isaac Sim](https://developer.nvidia.com/isaac/sim) 6.2.0.1 | `nvcr.io/nvidia/isaac-sim:6.2.0.1` (official, by NVIDIA) | Photorealistic cameras and sensors, full-robot simulation for autonomy software | NVIDIA **RTX** GPU (needs RT cores; not A100/H100) | official image |

GPU images need a host NVIDIA driver that supports CUDA 12.8 or newer. They are built for these GPU
generations: A100 (8.0), RTX 30xx (8.6), RTX 40xx / L40 (8.9), H100 (9.0), RTX 50xx (12.0).

Chrono and DEM-Engine run without a screen: results are written to files (CSV, VTK, images) and viewed
afterwards, for example in [ParaView](https://www.paraview.org).

## Renting a machine on Vast.ai

[Vast.ai](https://vast.ai) rents GPUs and CPUs by the hour from many hosts. Any provider that runs Docker
images works the same way (see [Other ways to run](#other-ways-to-run)).

1. **Make an account** at vast.ai, add credit, and add your SSH public key (Account → Keys).
2. **Install the command-line tool** and log in with your API key (Account → Keys):

   ```bash
   pip install vastai
   vastai set api-key <your-api-key>
   ```

3. **Find a machine.** For a GPU image, pick one GPU with a new enough driver:

   ```bash
   vastai search offers 'num_gpus=1 cuda_vers>=12.8 reliability>0.98 verified=true disk_space>=40' -o 'dph+'
   ```

   For a CPU image (code_aster, Elmer, openEMS), rank by cores instead, for example
   `'cpu_cores_effective>=16 disk_space>=30' -o 'dph+'`. Isaac Sim needs an RTX card:
   add `gpu_name in [RTX_4090,RTX_3090,RTX_A6000,L40S]` or similar.

4. **Start it with the image you want** (the offer ID is the first column of the search):

   ```bash
   vastai create instance <offer-id> --image ghcr.io/type-2-labs/chrono:10.0.0-cuda12.8 --disk 40 --ssh --direct
   vastai show instances          # wait for "running"; note the SSH host and port
   ```

5. **Copy your files in, run, copy results out:**

   ```bash
   scp -P <port> -r my_sim/ root@<host>:/workspace/
   ssh -p <port> root@<host>
   cd /workspace/my_sim && python3 run.py
   scp -P <port> -r root@<host>:/workspace/my_sim/results ./
   ```

6. **Destroy it when you're done.** A stopped instance still bills for its disk.

   ```bash
   vastai destroy instance <instance-id>
   ```

### What it costs

You pay the host's hourly price while the instance exists. Example from a Vast search on 2026-10-22:
an RTX 3090 with 24 CPU cores at **$0.19 an hour**; an RTX A4000 at $0.13 an hour. Prices change by the
minute, so check the search. The images are free.

## Other ways to run

On any Linux machine with Docker (and, for GPU images, an NVIDIA GPU with the
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)):

```bash
docker run --rm -it --gpus all -v "$PWD":/workspace ghcr.io/type-2-labs/chrono:10.0.0-cuda12.8 bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/type-2-labs/elmer:9.0 bash
```

The CPU images (Elmer, openEMS, code_aster) also run on a laptop with Docker for small cases.

## What's inside each image

| Image | Contents | Source |
|---|---|---|
| chrono | Chrono 10.0.0 built from source: core, Vehicle + vehicle models, FSI with the CRM granular soil (CUDA), postprocess, Python module, C++ demos in `/opt/chrono/demos` | [chrono-docker](https://github.com/type-2-labs/chrono-docker) |
| deme | `deme[cuda12]==3.0.19` from PyPI in `/opt/venv`, DEM-Engine source and Python demos in `/opt/DEM-Engine` | [deme-docker](https://github.com/type-2-labs/deme-docker) |
| elmer | `elmerfem-csc` from CSC's official Ubuntu PPA, gmsh, OpenMPI | [elmer-docker](https://github.com/type-2-labs/elmer-docker) |
| openems | openEMS v0.37.0 + CSXCAD built with the project's own script, Python interface in `/opt/openEMS/venv`, no GUI | [openems-docker](https://github.com/type-2-labs/openems-docker) |

Each build checks itself before it publishes: it imports the Python module or runs the solver, so a
broken image fails in GitHub Actions rather than on a rented machine.

## Licenses

The images package other projects' software under their own licenses: Project Chrono and DEM-Engine
(BSD-3-Clause), Elmer (GPL-2.0 / LGPL-2.1), openEMS (GPL-3.0), code_aster (GPL), and Isaac Sim
(NVIDIA's license, accepted when you use it). The CUDA base images are under NVIDIA's CUDA license.
