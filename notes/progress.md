## le 22 avril 2026 19:50

- Clean SVO environment successfully built using ROS Noetic Docker (full pipeline, no trimming)
- Reproducible installation documented (installation.md)
- Git repository cleaned and structured (ignored build artifacts, external deps, datasets)
- Experiment framework initialized (datasets/, results/, notes/)
- WildGS-SLAM repo cloned for official dataset scripts
- Download of Bonn, TUM RGB-D, and Wild-SLAM (MoCap) datasets started
- SVO verified functional (packages built, launch files available)


## le 23 avril 2026 18:10

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
- Performance degradation at full playback speed is primarily due to real-time processing limits, leading to frame drops and increased inter-frame motion, which negatively impacts tracking stability.
#### vicon_room2 test medium and hard full playback
## Key Findings:

- Medium Difficulty: Consistently diverges ("flies into the void") at both 0.5x and 1.0x speeds.

- Hard Difficulty: Surprisingly produces stable estimation results at 1.0x speed, despite initial assumptions that reduced playback speed (0.5x) would be required.

- Corrected the previous testing assumption that hard difficulty would inherently perform worse than medium.

## No IMU patch
- sed -n '430,530p' /workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros/src/svo_interface.cpp
- the command above shows image and IMU are handled in separate loops, so IMU is not inherently fused into the same subscriber.
- grep -R "subscribeImu()" -n /workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros
- the 2nd command shows that subscribeImu() is always called so to test Bonn/TUM/Wilds without IMU, we’ll need a small code or launch adaptation

```bash
F0423 06:37:14.194885  3699 frame.cpp:62] Check failed: img.cols == static_cast<int>(cam_->imageWidth()) (640 vs. 752) 
*** Check failure stack trace: ***
    @     0x7f048b289703  google::LogMessage::Fail()
    @     0x7f048b28e4ab  google::LogMessage::SendToLog()
    @     0x7f048b2893ff  google::LogMessage::Flush()
    @     0x7f048b289c2f  google::LogMessageFatal::~LogMessageFatal()
    @     0x7f048b318970  svo::Frame::initFrame()
    @     0x7f048b318e33  svo::Frame::Frame()
    @     0x7f048b568c78  svo::FrameHandlerBase::addImageBundle()
    @     0x7f048bfb96be  svo::SvoInterface::processImageBundle()
    @     0x7f048bfbc191  svo::SvoInterface::monoCallback()
    @     0x7f047c0f024f  image_transport::RawSubscriber::internalCallback()
    @     0x7f048b8d1162  boost::detail::function::void_function_obj_invoker1<>::invoke()
    @     0x7f047c0f451d  ros::SubscriptionCallbackHelperT<>::call()
    @     0x7f048c1d3549  ros::SubscriptionQueue::call()
    @     0x7f048c181302  ros::CallbackQueue::callOneCB()
    @     0x7f048c182d73  ros::CallbackQueue::callAvailable()
    @     0x7f048bfbd5cb  svo::SvoInterface::monoLoop()
    @     0x7f048be6adf4  (unknown)
    @     0x7f048c02d609  start_thread
    @     0x7f048bca6353  clone
[svo-1] process has died [pid 3692, exit code -6, cmd /workspaces/svo_dynamic_eval/svo_full_ws/devel/.private/svo_ros/lib/svo_ros/svo_node --v=0 __name:=svo __log:=/root/.ros/log/97f934c0-3ede-11f1-b57b-f8ac6559bc1c/svo-1.log].
log file: /root/.ros/log/97f934c0-3ede-11f1-b57b-f8ac6559bc1c/svo-1*.log
all processes on machine have died, roslaunch will exit
shutting down processing monitor...
... shutting down processing monitor complete
```
- the output above shows that The Bonn RGB camera is documented as 640×480, need to make a seperate config.yaml for it


## le 24 avril 2026
- Monocular SVO (no IMU) achieves ~0.12–0.16 m RMSE on Bonn ballon and ballon2 sequences, with stable tracking but expected sparse/low-quality mapping.

- for bonn crowd data, Without alignment, the estimated trajectory diverges significantly from the ground truth, reaching errors above 2 meters. While the motion remains locally smooth, the global trajectory is incorrect due to scale ambiguity and drift accumulation. Temporary error reductions are caused by incidental spatial proximity rather than true correction.

- for bonn crowd 2 SVO initialized but tracking stopped after approximately 1.2 seconds. Recorded only 39 pose messages on /svo/pose_cam/0. This sequence is treated as a tracking failure. APE evaluation is not considered meaningful due to insufficient trajectory length.

- In moderately dynamic scenes (person tracking), SVO maintains stable tracking with moderate accuracy degradation (~0.33 m RMSE). However, performance is significantly worse than in static environments, confirming sensitivity to moving objects. SVO survives dynamics when enough static structure remains

- final bonn sequence, rgbd_bonn_person_tracking2: Partial tracking only. SVO produced 91 pose messages over 3.1 s. Aligned APE RMSE = 0.022 m, but this is not representative of the full sequence. Status: partial / early tracking loss.

## SVO Evaluation — RGB-Bonn Dataset

| Sequence                  | RMSE Aligned (m) | RMSE No Align (m) | Status        | Key Insight |
|---------------------------|------------------|-------------------|--------------|-------------|
| rgbd_bonn_balloon         | 0.161            | 2.558             | Successful    | Good tracking, clear scale drift        |
| rgbd_bonn_balloon2        | 0.127            | 2.611             | Successful    | Strong relative accuracy                |
| rgbd_bonn_crowd           | 0.535            | 2.148             | Degraded      | Dynamic scene affects tracking          |
| rgbd_bonn_crowd2          | 0.020            | 2.170             | Misleading    | Very short trajectory, not representative |
| rgbd_bonn_person_tracking | 0.332            | 2.302             | Moderate      | Motion introduces instability           |
| rgbd_bonn_person_tracking2| 0.022            | 2.084             | Misleading    | Partial tracking (~3s), artificially low RMSE |

## Automation scripts
- after tests were done and pipeline became familiar, automation scripts were created, in both scripts/Bonn and scripts/EuRoc - for both aligned and non aligned results. 
- for redundancy, vicon_room1 was installed and tested using automated scripts, as expected, when IMU data is given, results become more stable


## SVO Evaluation — EuRoC Vicon Room 1 & 2

| Sequence           | RMSE Aligned (m) | RMSE No Align (m) | Status        | Key Insight |
|------------------|------------------|-------------------|--------------|-------------|
| V1_01_easy       | 0.050            | 3.998             | Successful    | Excellent relative tracking, large scale drift |
| V1_02_medium     | 0.124            | 3.655             | Successful    | Stable but increasing drift                    |
| V1_03_difficult  | 0.118            | 3.350             | Successful    | Robust but slightly degraded accuracy          |
| V2_01_easy       | 0.197            | 2.258             | Moderate      | Acceptable tracking, noticeable scale error    |
| V2_02_medium     | 12167.356        | 15917.890         | Failed        | Complete divergence                            |
| V2_03_difficult  | 0.187            | 1.847             | Moderate      | Stable tracking, moderate scale drift          |

## with current commit and setup, use these commands to extract RMSE automatically from vicon and RGB_bonn repectively:
```bash
cd /workspaces/svo_dynamic_eval/results/svo/euroc

for SEQ in V1_01_easy V1_02_medium V1_03_difficult \
           V2_01_easy V2_02_medium V2_03_difficult; do
  echo "=== $SEQ ==="
  grep rmse $SEQ/ape_stats.txt 2>/dev/null
  grep rmse ${SEQ}_no_align/ape_stats_no_align.txt 2>/dev/null
  echo
done
```

```bash
cd /workspaces/svo_dynamic_eval/results/svo/bonn

for SEQ in rgbd_bonn_balloon \
           rgbd_bonn_balloon2 \
           rgbd_bonn_crowd \
           rgbd_bonn_crowd2 \
           rgbd_bonn_person_tracking \
           rgbd_bonn_person_tracking2; do

  echo "=== $SEQ ==="

  # aligned
  grep rmse $SEQ/ape_stats.txt 2>/dev/null

  # no-align
  grep rmse ${SEQ}_no_align/ape_stats_no_align.txt 2>/dev/null

  echo
done
```

## le 27 avril 2026
- validated a pipeline for tum_rgbd, continuing tests.

## SVO Evaluation — TUM RGB-D

| Sequence                                      | RMSE Aligned (m) | RMSE No Align (m) | Status        | Key Insight |
|-----------------------------------------------|------------------|-------------------|--------------|-------------|
| rgbd_dataset_freiburg2_desk_with_person       | 0.730            | 2.238             | Moderate     | Dynamic scene degrades tracking stability |
| rgbd_dataset_freiburg3_sitting_halfsphere     | 0.308            | 2.821             | Moderate     | Smooth motion but noticeable drift |
| rgbd_dataset_freiburg3_sitting_rpy            | 0.055            | 3.156             | Successful   | Strong local tracking, large global offset |
| rgbd_dataset_freiburg3_sitting_static         | 0.035            | 3.403             | Successful   | Very stable, near-ideal static performance |
| rgbd_dataset_freiburg3_sitting_xyz            | 0.182            | 3.381             | Moderate     | Translation motion increases drift |
| rgbd_dataset_freiburg3_walking_halfsphere     | 0.475            | 3.082             | Moderate     | Dynamic motion reduces accuracy |
| rgbd_dataset_freiburg3_walking_rpy            | 0.075            | 3.112             | Successful   | Robust tracking despite rotation |
| rgbd_dataset_freiburg3_walking_static         | 0.017            | 3.625             | Successful   | Best-case tracking, minimal relative error |
| rgbd_dataset_freiburg3_walking_xyz            | 0.249            | 3.370             | Moderate     | Drift accumulates with translational motion |

- SVO achieves high relative accuracy (<5 cm) in controlled/static scenes, but consistently exhibits large global drift (~3 m) due to monocular scale ambiguity.

- In current commit, use the following command in bash to extract the results from tum_rgbd automated scripts

```bash
cd /workspaces/svo_dynamic_eval/results/svo/tum_rgbd

for SEQ in rgbd_dataset_freiburg2_desk_with_person \
           rgbd_dataset_freiburg3_sitting_halfsphere \
           rgbd_dataset_freiburg3_sitting_rpy \
           rgbd_dataset_freiburg3_sitting_static \
           rgbd_dataset_freiburg3_sitting_xyz \
           rgbd_dataset_freiburg3_walking_halfsphere \
           rgbd_dataset_freiburg3_walking_rpy \
           rgbd_dataset_freiburg3_walking_static \
           rgbd_dataset_freiburg3_walking_xyz; do

  echo "=== $SEQ ==="

  grep rmse $SEQ/ape_stats.txt 2>/dev/null
  grep rmse ${SEQ}_no_align/ape_stats_no_align.txt 2>/dev/null

  echo
done
```