# list of quick terminal commands to save time:

### start docker:
- docker start svo_noetic
- docker exec -it svo_noetic bash



### with docker running - SVO vicon_room2 pipeline check:
----
#### terminal 1 roscore:
- docker exec -it svo_noetic bash
- source /opt/ros/noetic/setup.bash
- source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
- roscore

#### terminal 2 SVO mono with rviz:
- docker exec -it svo_noetic bash
- source /opt/ros/noetic/setup.bash
- source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
- LIBGL_ALWAYS_SOFTWARE=1 QT_X11_NO_MITSHM=1 roslaunch svo_ros euroc_vio_mono.launch

#### terminal 3 play the bag:
- docker exec -it svo_noetic bash
- source /opt/ros/noetic/setup.bash
- rosbag play /workspaces/svo_dynamic_eval/external/euroc/vicon_room2/V2_01_easy/V2_01_easy.bag --clock

## Record SVO vicon_room2 - easy bag:
#### terminal 1:
- roscore
#### terminal 2 with rivz:
- source /opt/ros/noetic/setup.bash
- source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
- LIBGL_ALWAYS_SOFTWARE=1 QT_X11_NO_MITSHM=1 roslaunch svo_ros euroc_vio_mono.launch
#### terminal 3 start recording, ctrl+c after bag finishes playing:
- mkdir -p /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy
- rosbag record -O /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/svo_pose.bag /svo/pose_imu
#### terminal 4:
- rosbag play /workspaces/svo_dynamic_eval/external/euroc/vicon_room2/V2_01_easy/V2_01_easy.bag --clock
#### you should find svo_pose.bag

### Plot and compare with ground truth:
#### run convert scripts  - easy
- pose  bag to tum
- ground truth to tum
#### run evo ape:
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/traj_est.tum \
- -a --plot --save_plot /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/ape_plot.pdf

#### SAVE STATS AS TXT IF WANTED:
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/traj_est.tum \
- -a > /workspaces/svo_dynamic_eval/results/svo/euroc/V2_01_easy/ape_stats.txt

## Record SVO vicon_room2 - mid bag:

#### terminal 1:
- roscore
#### terminal 2 with rivz:
- source /opt/ros/noetic/setup.bash
- source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
- LIBGL_ALWAYS_SOFTWARE=1 QT_X11_NO_MITSHM=1 roslaunch svo_ros euroc_vio_mono.launch
#### terminal 3, again, ctrl+c after finishing:
- source /opt/ros/noetic/setup.bash
- mkdir -p /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium
- rosbag record -O /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/svo_pose.bag /svo/pose_imu
#### terminal 4:
- source /opt/ros/noetic/setup.bash
- rosbag play /workspaces/svo_dynamic_eval/external/euroc/vicon_room2/V2_02_medium/V2_02_medium.bag --clock -r 0.5
#### you should find svo_pose.bag

### Plot and compare with ground truth:
#### run convert scripts - medium
- pose  bag to tum
- ground truth to tum
#### run evo ape:
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/traj_est.tum \
- -a --plot --save_plot /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/ape_plot.pdf
#### save stats
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/traj_est.tum \
- -a > /workspaces/svo_dynamic_eval/results/svo/euroc/V2_02_medium/ape_stats.txt

---
#### NOTE: medium bag has a rough accelertion at the start, this causes the estimation to fail catastophically and fly off into the void, playback speed reduced to 0.5
#### TODO: test the limit of playback speed or remove initial acceleration
#### try 
- rosbag play /workspaces/svo_dynamic_eval/external/euroc/vicon_room2/V2_02_medium/V2_02_medium.bag --clock --pause -r 0.5
- start paused, step foward with "S" and press "space" to resume after the initial few seconds
#### failed even with pausing Best practical options:

- let it fail and report it as a medium-sequence instability
- trim the bag and start a few seconds later
- tune SVO params, which is a separate experiment (no)
---

## Record SVO vicon_room2 - hard bag:

#### terminal 1:
- roscore
#### terminal 2 with rivz:
- source /opt/ros/noetic/setup.bash
- source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
- LIBGL_ALWAYS_SOFTWARE=1 QT_X11_NO_MITSHM=1 roslaunch svo_ros euroc_vio_mono.launch
#### terminal 3, again, ctrl+c after finishing:
- source /opt/ros/noetic/setup.bash
- mkdir -p /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult
- rosbag record -O /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/svo_pose.bag /svo/pose_imu
#### terminal 4:
- source /opt/ros/noetic/setup.bash
- rosbag play /workspaces/svo_dynamic_eval/external/euroc/vicon_room2/V2_03_difficult/V2_03_difficult.bag --clock -r 0.5
#### you should find svo_pose.bag

### Plot and compare with ground truth:
#### run convert scripts - hard
- pose  bag to tum
- ground truth to tum
#### run evo ape:
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/traj_est.tum \
- -a --plot --save_plot /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/ape_plot.pdf
#### save stats
- evo_ape tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/traj_gt.tum \
- /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/traj_est.tum \
- -a > /workspaces/svo_dynamic_eval/results/svo/euroc/V2_03_difficult/ape_stats.txt