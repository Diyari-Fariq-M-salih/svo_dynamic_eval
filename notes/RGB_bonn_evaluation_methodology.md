## SVO Evaluation, Methodology Summary

### Pipeline Overview
The evaluation of SVO (monocular, no IMU) on the Bonn RGB-D dataset followed a consistent pipeline:

1. **Data Playback**
   - RGB images were published to:
     ```
     /cam0/image_raw
     ```
   - Original timestamps were preserved for correct timing.

2. **Pose Estimation**
   - SVO processed incoming images and estimated camera poses.
   - Output topic:
     ```
     /svo/pose_cam/0
     ```

3. **Pose Recording**
   - Estimated poses were recorded using ROS:
     ```bash
     rosbag record /svo/pose_cam/0
     ```

4. **Conversion to TUM Format**
   - Recorded poses were converted to TUM format:
     ```
     timestamp tx ty tz qx qy qz qw
     ```

5. **Ground Truth**
   - Provided directly by the dataset (`groundtruth.txt`) in TUM format.

---

### Evaluation Method

- Tool used: `evo`
- Metric: **Absolute Pose Error (APE)**

```bash
evo_ape tum groundtruth.txt traj_est.tum -a
```

### Evaluation was performed using SE(3) Umeyama alignment:

Translation
Rotation
Scale (important for monocular systems)

This means:

The estimated trajectory is transformed to best match the ground truth before computing error.

As a result:

Reported RMSE reflects relative trajectory accuracy
Absolute scale errors are not directly measured
Alignment may reduce apparent error, especially in monocular SLAM

### Reported Metrics (All in meters)
- RMSE (primary metric)
- Mean
- Median
- Maximum error
- Standard deviation

### Extra notes
- Monocular SVO does not estimate true scale.
- Alignment compensates for this limitation.
- Short or failed trajectories may produce misleadingly low RMSE values.