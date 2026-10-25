#!/bin/bash
# Installs OmniLRS v3.0.0 on NVIDIA's official Isaac Sim 5.0.0 image (nvcr.io/nvidia/isaac-sim:5.0.0) at
# start-up, so NVIDIA's software is pulled from NVIDIA rather than republished. Mirrors the steps of OmniLRS's own
# omnilrs.docker/Dockerfile (v3.0.0). Run as root. Log: /var/log/omnilrs-setup.log. Done when /workspace/omnilrs/.ready
# exists. SUITE_REF picks the lunar-sim-suite commit that snapshot.py is fetched from. Set OMNILRS_DEMS=1 to also
# download the LOLA south-pole elevation maps (several GB) for LargeScale scenes.
set -euo pipefail
exec >> /var/log/omnilrs-setup.log 2>&1
echo "setup start $(date -u)"
OMNILRS_VERSION=${OMNILRS_VERSION:-v3.0.0}
PY=/isaac-sim/python.sh
export DEBIAN_FRONTEND=noninteractive

echo 'Etc/UTC' > /etc/timezone && ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
apt-get update
apt-get install -q -y --no-install-recommends tzdata apt-utils dirmngr gnupg2 curl libglib2.0-0 tmux vim nano \
    build-essential pkg-config git git-lfs wget ca-certificates
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    > /etc/apt/sources.list.d/ros2.list
apt-get update
apt-get install -y ros-humble-ros-core gdal-bin libgdal-dev ros-humble-vision-msgs ros-humble-tf2-msgs g++

$PY -m pip install --upgrade pip
$PY -m pip install "numpy==1.26.4" "packaging==23.0"
$PY -m pip install skyfield zfpy numba gdown em lark yamcs-client pandas
$PY -m pip install omegaconf hydra-core eclipse-zenoh asyncio_for_robotics msgspec
$PY -m pip install --no-deps opencv-python
$PY -m pip install "gdal==$(gdal-config --version)"

mkdir -p /workspace
if [ ! -d /workspace/omnilrs ]; then
    git clone --recursive --branch "$OMNILRS_VERSION" https://github.com/OmniLRS/OmniLRS.git /workspace/omnilrs
fi
cd /workspace/omnilrs
git lfs pull || true
# v3.0.0's SDG scenes still use the old deformation key; its DeformationEngineConf renamed it to `delay`.
sed -i "s/render_deform_inv: 10/delay: 1.0/" cfg/environment/lunaryard_20m4SDG.yaml cfg/environment/lunalab4SDG.yaml
if [ "${OMNILRS_DEMS:-0}" = "1" ]; then ./scripts/install_docker.sh; fi
curl -fsSL "https://raw.githubusercontent.com/type-2-labs/lunar-sim-suite/${SUITE_REF:-main}/omnilrs/snapshot.py" -o snapshot.py || true

cat >> /root/.bashrc <<'RC'
export ACCEPT_EULA=Y PRIVACY_CONSENT=Y OMNILRS_ROOT=/workspace/omnilrs
export isaac_sim_package_path=/isaac-sim RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export ROS_DISTRO=humble LD_LIBRARY_PATH=/isaac-sim/exts/isaacsim.ros2.bridge/humble/lib
alias isaacpy='/isaac-sim/python.sh'
RC
touch /workspace/omnilrs/.ready
echo "setup done $(date -u)"
