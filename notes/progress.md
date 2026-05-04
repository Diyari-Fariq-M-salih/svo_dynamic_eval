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

## le 28 avril 2026
- Wilds data set failed to run, fundmentally different from last datasets, has JSON and no yaml, camera config is different, from intrinsics.json we get:
```JSON
width: 1280
height: 720
fx: 647.2167
fy: 646.4154
cx: 643.1209
cy: 365.5596
coeffs: [-0.0550, 0.0656, -0.0005, 0.00047, -0.0217]
```
- SVO expects 4 distortion params, but we have 5
- generated svo_full_ws/src/rpg_svo_pro_open/svo_ros/param/calib/wild_rgbd_1280x720.yaml:
```yaml
cameras:
- camera:
    distortion:
      parameters:
        cols: 1
        rows: 4
        data: [-0.05501496, 0.06560786, -0.00050613, 0.00047713]
      type: radial-tangential
    image_height: 720
    image_width: 1280
    intrinsics:
      cols: 1
      rows: 4
      data: [647.2167, 646.4155, 643.1210, 365.5596]
    label: cam0
    line-delay-nanoseconds: 0
    type: pinhole
  T_B_C:
    cols: 4
    rows: 4
    data: [1., 0., 0., 0.,
           0., 1., 0., 0.,
           0., 0., 1., 0.,
           0., 0., 0., 1.]
  serial_no: 0
  calib_date: 0
  description: 'wild_rgbd_1280x720'
label: wild_rgbd_1280x720
```
- Created run_wild_svo_batch.sh, both aligned and non aligned run in the same script to reduce file redundancy, as well as:
- - aligned RMSE
- - no-align RMSE
- - raw/map plots saved automatically
- - all sequences under scene1/* and scene2/*
- - automatic YAML generation from each intrinsics.json
- Wild_SLAM_Mocap is much harder than TUM/Bonn. SVO still tracks most sequences, but aligned RMSE rises to ~0.4–1.5 m, showing that real-world dynamics and non-controlled motion significantly degrade accuracy.

## SVO Evaluation || Wild_SLAM_Mocap

| Sequence | Poses | RMSE Aligned (m) | RMSE No Align (m) | Status | Key Insight |
|---|---:|---:|---:|---|---|
| scene1_table_tracking1 | 531 | 1.162 | 2.423 | Poor | Significant drift despite successful tracking |
| scene1_ball | 924 | 0.771 | 2.365 | Moderate | Real-world object motion degrades accuracy |
| scene1_table_tracking2 | 322 | 0.777 | 2.611 | Moderate | Shorter tracking, moderate trajectory error |
| scene1_umbrella | 447 | 0.440 | 2.860 | Moderate | Best Wild result, still worse than TUM/Bonn |
| scene1_crowd | 1244 | 0.845 | 2.673 | Poor | Dynamic crowd scene reduces reliability |
| scene1_person_tracking | 978 | 1.453 | 3.500 | Failed/Poor | Strong dynamic subject causes major degradation |
| scene1_stones | 941 | 0.595 | 2.803 | Moderate | Tracks but retains substantial drift |
| scene1_racket | 951 | 1.192 | 2.813 | Poor | Fast/dynamic object motion hurts tracking |
| scene2_ANYmal1 | 644 | 0.633 | 3.233 | Moderate | Robot motion/general scene still challenging |
| scene2_ANYmal2 | 1168 | 1.509 | 2.171 | Failed/Poor | High aligned error despite many poses |

- in current commit, use the following to echo out the RMSE for wilds_rgbd:
```bash
cd /workspaces/svo_dynamic_eval/results/svo/wild_slam_mocap

for SEQ in scene1_table_tracking1 \
           scene1_ball \
           scene1_table_tracking2 \
           scene1_umbrella \
           scene1_crowd \
           scene1_person_tracking \
           scene1_stones \
           scene1_racket \
           scene2_ANYmal1 \
           scene2_ANYmal2; do
  echo "=== $SEQ ==="
  echo -n "poses: "
  cat "$SEQ/converted_poses.txt" 2>/dev/null || echo "NA"
  grep rmse "$SEQ/ape_stats.txt" 2>/dev/null
  grep rmse "$SEQ/ape_stats_no_align.txt" 2>/dev/null
  echo
done
```

## Experimental Conclusion

| Dataset              | Conditions            | Result                |
| -------------------- | --------------------- | --------------------- |
| **EuRoC (with IMU)** | controlled + inertial | best stability        |
| **TUM RGB-D**        | controlled, no IMU    | very accurate locally |
| **Bonn**             | semi-dynamic          | moderate degradation  |
| **Wild (MoCap)**     | real-world dynamic    | strong degradation    |

### aligned RMSE trend
```
EuRoC      → ~0.05–0.2 m
TUM        → ~0.02–0.3 m
Bonn       → ~0.1–0.5 m
Wild       → ~0.4–1.5 m
```
- As scene realism and dynamics increase, monocular SVO accuracy degrades significantly.
### non aligned RMSE trend
```
~2–4 meters across ALL datasets
```
- Scale drift is independent of dataset type, So:

- not caused by dynamics
- not caused by calibration
- not caused by noise
- this is monocular scale ambiguity

### Bottlenecks of SVO
```
A. No IMU → scale drift
proven across all datasets

B. Dynamic scenes → feature corruption
Bonn + Wild confirm this

C. Real-world conditions → accuracy collapse
Wild dataset clearly shows this

D. Camera model limitations
mismatch (5 coeffs → 4 coeffs)
contributes to Wild degradation

conclusion: SVO does not generalize well to real-world dynamic environments
```

### Subtle pose count insight
- From data logs, high pose count BUT high error, ergo Tracking != accuracy, SVO keeps tracking, but drifts and misestimates

## Comparison with SVO Paper

| Metric | SVO Paper | Our Results |
|-------|----------|------------|
| Relative Drift | ~0.005 m/s | (not computed) |
| Scale Drift | up to 8% | visible (high no-align RMSE) |
| Aligned RMSE | low | low (0.02–0.5 m) |
| Non-aligned RMSE | high | high (2–4 m) |
| Trajectory Shape | correct | correct |

The behavior of our system is consistent with the original SVO paper. While absolute trajectory error appears high without alignment, the relative motion estimation is accurate, as confirmed by the similarity in trajectory shape and reduced error after alignment. This matches the expected scale drift and lack of global consistency in monocular visual odometry.

### One paragraph summary
Monocular SVO achieves high relative accuracy in controlled environments, but its performance degrades systematically with increasing scene dynamics and realism. While tracking remains operational in most cases, absolute accuracy deteriorates due to scale ambiguity, motion complexity, and model limitations. Monocular SVO accurately captures relative motion, but fails to maintain global consistency. which is what sim(3) alignment tries to fix.

## le 5 mai 2026
- under supervisor feedvack, will change from SE3 to SIM3 alignment
- current SVO repo does not contain RGB-D file to use, which is the next step of testing
- for now, will convert all past results, in RGB, to use SIM3 alignment
- noticeable results were observed with Bonn dataset, but not much in vicon rooms 1 and 2
```bash
for SEQ in rgbd_bonn_balloon rgbd_bonn_balloon2 rgbd_bonn_crowd rgbd_bonn_crowd2 rgbd_bonn_person_tracking rgbd_bonn_person_tracking2; do
  echo "=== $SEQ ==="
  grep rmse $SEQ/ape_stats_sim3.txt 2>/dev/null
done
```
```bash
=== rgbd_bonn_balloon ===
      rmse	0.111795
=== rgbd_bonn_balloon2 ===
      rmse	0.099591
=== rgbd_bonn_crowd ===
      rmse	0.065953
=== rgbd_bonn_crowd2 ===
      rmse	0.002001
=== rgbd_bonn_person_tracking ===
      rmse	0.203751
=== rgbd_bonn_person_tracking2 ===
      rmse	0.010634
```

```bash
for SEQ in V1_01_easy V1_02_medium V1_03_difficult V2_01_easy V2_02_medium V2_03_difficult; do
  echo "=== $SEQ ==="
  grep rmse $SEQ/ape_stats_sim3.txt 2>/dev/null
done
```
```bash
=== V1_01_easy ===
      rmse	0.049059
=== V1_02_medium ===
      rmse	0.123500
=== V1_03_difficult ===
      rmse	0.118132
=== V2_01_easy ===
      rmse	0.192176
=== V2_02_medium ===
      rmse	2.256184
=== V2_03_difficult ===
      rmse	0.185936
```