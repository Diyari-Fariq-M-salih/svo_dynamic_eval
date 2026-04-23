## le 22 avril 2026 19:50

- Clean SVO environment successfully built using ROS Noetic Docker (full pipeline, no trimming)
- Reproducible installation documented (installation.md)
- Git repository cleaned and structured (ignored build artifacts, external deps, datasets)
- Experiment framework initialized (datasets/, results/, notes/)
- WildGS-SLAM repo cloned for official dataset scripts
- Download of Bonn, TUM RGB-D, and Wild-SLAM (MoCap) datasets started
- SVO verified functional (packages built, launch files available)


## le 23 avril 2026 XX:XX

- DATASET_ROOT=/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets
- rviz not working - X11 / permissions --> use xhost +local:root
- rviz openGL issue --> force software rendering : export LIBGL_ALWAYS_SOFTWARE=1 | export QT_X11_NO_MITSHM=1
- 1st data set to test bonn/rgbd_bonn_balloon || depth folder not useful for monocular SVO
- NOTE: bonn data set does not provide full IMU, SVO expectes camera and IMU, doing a quick sanity check using vicon_room2
- vicon_room2 DATASET_ROOT=/workspaces/svo_dynamic_eval/external/euroc
#### vicon_room2 tests
- SVO achieved stable performance on EuRoC V2_01_easy with APE ≈ 0.1 m after initialization.
- On EuRoC V2_02_medium, SVO remains operational but exhibits increased drift and reduced stability compared to the easy sequence, with APE rising to ~0.15–0.2 m given a playback speed of (0.5).
- Under the current laptop + Docker setup, SVO becomes unstable on more dynamic EuRoC sequences at full playback rate, but remains usable at reduced playback speed (0.5), indicating sensitivity to motion dynamics and real-time compute constraints.
#### vicon_room2 test medium and hard full playback