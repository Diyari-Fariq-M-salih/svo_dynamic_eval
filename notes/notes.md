## SVO setup
- Environment: Docker container based on `osrf/ros:noetic-desktop-full`
- Workspace: `svo_full_ws`
- Build method: upstream `rpg_svo_pro_open` README flow using `vcs import`
- Built successfully with all 34 packages
- Included modules: `svo`, `svo_ros`, `svo_online_loopclosing`, `svo_pgo`, `svo_ceres_backend`
- `minkindr_python` was disabled via `CATKIN_IGNORE` as recommended by the upstream flow
- Vocabulary downloaded for `svo_online_loopclosing`
- SVO commit: [ca371f304637e7fb355cf4624d0a02da4e3da220]