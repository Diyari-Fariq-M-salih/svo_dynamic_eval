# list of quick terminal commands to save time:

### start docker:
- optionally on host xhost +local:root (for rviz)
- docker start svo_noetic
- docker exec -it svo_noetic bash

### with docker running:
----
#### terminal 1 roscore:
```bash
docker exec -it svo_noetic bash
source /opt/ros/noetic/setup.bash
roscore
```
#### terminal 2 SVO mono without IMU:
```bash
docker exec -it svo_noetic bash
source /opt/ros/noetic/setup.bash
source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash

roslaunch svo_ros mono_no_imu.launch \
calib_file:=/workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros/param/calib/bonn_rgbd_640.yaml
```
#### terminal before 3 and after 2 ( if using rivz ):
```bash
docker exec -it svo_noetic bash
source /opt/ros/noetic/setup.bash
source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash
export DISPLAY=:1
export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1
rviz -d /workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros/rviz_config.rviz
```
if RViz does not work, check display:
```bash
echo $DISPLAY
ls /tmp/.X11-unix
```
#### terminal 3 record, ctrl+c after bag finishes playing:
```bash
docker exec -it svo_noetic bash
source /opt/ros/noetic/setup.bash

mkdir -p /workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2

rosbag record -O /workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/svo_pose.bag \
/svo/pose_cam/0
```
#### terminal 4 publish Bonn RGB sequence:
```bash
docker exec -it svo_noetic bash
source /opt/ros/noetic/setup.bash

python3 - <<'PY'
import os, time, cv2, rospy
from cv_bridge import CvBridge
from sensor_msgs.msg import Image

seq = "/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Bonn/rgbd_bonn_person_tracking2"
rgb_txt = os.path.join(seq, "rgb.txt")

rospy.init_node("bonn_rgb_player")
pub = rospy.Publisher("/cam0/image_raw", Image, queue_size=10)
bridge = CvBridge()

entries = []
with open(rgb_txt) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        ts, rel = line.split()[:2]
        entries.append((float(ts), rel))

print("frames:", len(entries))

while pub.get_num_connections() == 0 and not rospy.is_shutdown():
    time.sleep(0.5)

t0_ros = time.time()
t0_seq = entries[0][0]

for ts, rel in entries:
    target = t0_ros + (ts - t0_seq)
    while time.time() < target and not rospy.is_shutdown():
        time.sleep(0.001)

    img = cv2.imread(os.path.join(seq, rel), cv2.IMREAD_GRAYSCALE)
    if img is None:
        continue

    msg = bridge.cv2_to_imgmsg(img, encoding="mono8")
    msg.header.stamp = rospy.Time.from_sec(ts)
    msg.header.frame_id = "cam0"
    pub.publish(msg)

print("done")
time.sleep(2)
PY
```
#### you should find svo_pose.bag, verify with:
```bash
rosbag info /workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/svo_pose.bag
```
### Plot and compare with ground truth:
#### run convert scripts
- pose  bag to tum
- ground truth is already provided in tum

#### stats
```bash
evo_ape tum \
/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Bonn/rgbd_bonn_person_tracking2/groundtruth.txt \
/workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/traj_est.tum \
-a > /workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/ape_stats.txt
```

#### plots
```bash
evo_ape tum \
/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Bonn/rgbd_bonn_person_tracking2/groundtruth.txt \
/workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/traj_est.tum \
-a --plot --save_plot /workspaces/svo_dynamic_eval/results/svo/bonn/rgbd_bonn_person_tracking2/ape_plot.png
```
