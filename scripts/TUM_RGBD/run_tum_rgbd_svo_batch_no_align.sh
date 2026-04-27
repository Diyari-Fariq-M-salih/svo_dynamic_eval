set -e

source /opt/ros/noetic/setup.bash
source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash

CALIB=/workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros/param/calib/tum_freiburg3_rgbd_640.yaml
DATA_ROOT=/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/TUM_RGBD
OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/tum_rgbd

SEQS=(
  rgbd_dataset_freiburg3_sitting_static
)

for SEQ in "${SEQS[@]}"; do
  echo "======================================"
  echo "Running $SEQ (NO ALIGNMENT)"
  echo "======================================"

  DATA="$DATA_ROOT/$SEQ"
  OUT="$OUT_ROOT/${SEQ}_no_align"
  mkdir -p "$OUT"

  rm -f "$OUT/svo_pose.bag" "$OUT/traj_est.tum" "$OUT/ape_stats_no_align.txt" "$OUT/ape_plot_no_align.png"

  roslaunch svo_ros mono_no_imu.launch calib_file:=$CALIB &
  SVO_PID=$!
  sleep 4

  rosbag record -O "$OUT/svo_pose.bag" /svo/pose_cam/0 &
  REC_PID=$!
  sleep 1

  python3 - <<PY
import os, time, cv2, rospy
from cv_bridge import CvBridge
from sensor_msgs.msg import Image

seq = "$DATA"
rgb_txt = os.path.join(seq, "rgb.txt")

rospy.init_node("tum_rgbd_player", anonymous=True)
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
    print("waiting for subscriber on /cam0/image_raw ...")
    time.sleep(0.5)

t0_ros = time.time()
t0_seq = entries[0][0]

for i, (ts, rel) in enumerate(entries):
    target = t0_ros + (ts - t0_seq)
    while time.time() < target and not rospy.is_shutdown():
        time.sleep(0.001)

    img = cv2.imread(os.path.join(seq, rel), cv2.IMREAD_GRAYSCALE)
    if img is None:
        print("failed:", rel)
        continue

    msg = bridge.cv2_to_imgmsg(img, encoding="mono8")
    msg.header.stamp = rospy.Time.from_sec(ts)
    msg.header.frame_id = "cam0"
    pub.publish(msg)

    if i % 100 == 0:
        print("published", i, "/", len(entries))

print("done publishing")
time.sleep(2)
PY

  sleep 2
  kill -INT $REC_PID || true
  sleep 2
  kill -INT $SVO_PID || true
  sleep 4

  python3 - <<PY
import rosbag

inbag = "$OUT/svo_pose.bag"
outtum = "$OUT/traj_est.tum"

count = 0
with rosbag.Bag(inbag, 'r') as bag, open(outtum, 'w') as f:
    for _, msg, _ in bag.read_messages(topics=['/svo/pose_cam/0']):
        ts = msg.header.stamp.to_sec()
        p = msg.pose.position
        q = msg.pose.orientation
        f.write(f"{ts:.9f} {p.x:.9f} {p.y:.9f} {p.z:.9f} {q.x:.9f} {q.y:.9f} {q.z:.9f} {q.w:.9f}\\n")
        count += 1

print("converted poses:", count)
PY

  if [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      > "$OUT/ape_stats_no_align.txt" || true

    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      --plot --save_plot "$OUT/ape_plot_no_align.png" || true
  else
    echo "No valid trajectory generated." > "$OUT/ape_stats_no_align.txt"
  fi

  echo "Finished $SEQ (NO ALIGN)"
done

echo "All TUM RGB-D sequences processed (NO ALIGNMENT)."