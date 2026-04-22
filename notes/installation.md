# SVO Full Installation Guide (ROS Noetic + Docker)

## Overview

This guide installs the full **rpg_svo_pro_open** stack using a clean Docker-based ROS Noetic environment.

This setup includes:

* Full SVO pipeline
* Loop closing
* Pose graph optimization
* Ceres backend

---

## System Requirements

* Ubuntu host (tested on 20.04 / 22.04)
* Docker installed
* ~20GB free disk space
* Internet connection

---

## 1. Create Project Structure (Host Machine)

```bash
cd ~/Documents/GitHub
git clone <your_project_repo> svo_dynamic_eval
cd svo_dynamic_eval
```

---

## 2. Start Clean Docker Container

```bash
docker run -it --name svo_noetic_clean \
  -v ~/Documents/GitHub/svo_dynamic_eval:/workspaces/svo_dynamic_eval \
  osrf/ros:noetic-desktop-full
```

---

## 3. Install Required Tools (Inside Container)

```bash
apt update

apt install -y \
  python3-catkin-tools \
  python3-vcstool \
  python3-osrf-pycommon \
  git \
  wget \
  libtool \
  autoconf \
  automake
```

---

## 4. Create Workspace

```bash
cd /workspaces/svo_dynamic_eval

mkdir svo_full_ws
cd svo_full_ws

catkin config --init --mkdirs \
  --extend /opt/ros/noetic \
  --cmake-args -DCMAKE_BUILD_TYPE=Release -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3
```

---

## 5. Clone SVO Repository

```bash
cd src
git clone https://github.com/uzh-rpg/rpg_svo_pro_open.git
```

---

## 6. Fix Git Authentication (IMPORTANT)

Force HTTPS instead of SSH:

```bash
git config --global url."https://github.com/".insteadOf git@github.com:
```

---

## 7. Import Dependencies

```bash
vcs import < ./rpg_svo_pro_open/dependencies.yaml
```

Expected result: multiple repositories cloned into `src/`

---

## 8. Disable Problematic Python Binding

Upstream issue: `minkindr_python` requires extra ROS Python tooling not needed for SVO.

```bash
touch minkindr/minkindr_python/CATKIN_IGNORE
```

---

## 9. Download Vocabulary (Loop Closing)

```bash
cd rpg_svo_pro_open/svo_online_loopclosing/vocabularies

./download_voc.sh
```

---

## 10. Build Workspace

```bash
cd /workspaces/svo_dynamic_eval/svo_full_ws

catkin build
```

Expected result:

```
[build] Summary: All packages succeeded!
```

---

## 11. Setup Environment

```bash
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
echo "source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash" >> ~/.bashrc

source ~/.bashrc
```

---

## 12. Verify Installation

```bash
rospack list | grep svo
```

You should see:

* svo
* svo_ros
* svo_online_loopclosing
* svo_pgo
* svo_ceres_backend

---

## 13. Record Version (IMPORTANT FOR PAPER)

```bash
cd src/rpg_svo_pro_open
git rev-parse HEAD
```

Example:

```
ca371f304637e7fb355cf4624d0a02da4e3da220
```

Save this in your documentation.

---

## Key Notes

* This is a **full build**, not a minimal/core setup
* No package blacklisting except:

  * `minkindr_python` (safe to disable)
* Loop closing and optimization are enabled
* Ceres builds internally (no manual install needed)

---

## Common Issues & Fixes

### 1. `Permission denied (publickey)`

Fix:

```bash
git config --global url."https://github.com/".insteadOf git@github.com:
```

---

### 2. `wget: command not found`

Fix:

```bash
apt install -y wget
```

---

### 3. `libtoolize: command not found`

Fix:

```bash
apt install -y libtool autoconf automake
```

---

### 4. Partial vocab download

Fix:

```bash
rm -f vocabularies.tar.gz
./download_voc.sh
```

---

## Final Result

You now have a **clean, reproducible SVO installation** suitable for:

* Research experiments
* Benchmarking
* Academic publication

---

## Status

✔ Fully reproducible
✔ Matches upstream repo instructions
✔ Includes full pipeline (not stripped)

---

## Next Step

Run SVO on a dataset (e.g., EuRoC) and export trajectories for evaluation.
