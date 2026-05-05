#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash

DATA_ROOT=/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Wild_SLAM_Mocap
OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/wild_slam_mocap
CALIB_ROOT=/workspaces/svo_dynamic_eval/svo_full_ws/src/rpg_svo_pro_open/svo_ros/param/calib/wild_generated

mkdir -p "$OUT_ROOT" "$CALIB_ROOT"

SEQS=(
  scene1/table_tracking1
  scene1/ball
  scene1/table_tracking2
  scene1/umbrella
  scene1/crowd
  scene1/person_tracking
  scene1/stones
  scene1/racket
  scene2/ANYmal1
  scene2/ANYmal2
)

for SEQ in "${SEQS[@]}"; do
  SAFE_SEQ="${SEQ//\//_}"
  DATA="$DATA_ROOT/$SEQ"
  OUT="$OUT_ROOT/$SAFE_SEQ"
  CALIB="$CALIB_ROOT/${SAFE_SEQ}.yaml"

  echo "======================================"
  echo "Running Wild: $SEQ"
  echo "Output: $OUT"
  echo "======================================"

  mkdir -p "$OUT"

  rm -f "$OUT/svo_pose.bag" \
        "$OUT/svo_pose.bag.active" \
        "$OUT/traj_est.tum" \
        "$OUT/ape_stats.txt" \
        "$OUT/ape_stats_no_align.txt" \
        "$OUT/ape_plot_raw.png" \
        "$OUT/ape_plot_map.png" \
        "$OUT/ape_plot_no_align_raw.png" \
        "$OUT/ape_plot_no_align_map.png"

  # Generate SVO calibration YAML from intrinsics.json
  python3 - <<PY
import json
from pathlib import Path

intr = Path("$DATA/intrinsics.json")
out = Path("$CALIB")

j = json.loads(intr.read_text())
c = j["color"]

width = int(c["width"])
height = int(c["height"])
fx = float(c["fx"])
fy = float(c["fy"])
cx = float(c["ppx"])
cy = float(c["ppy"])
coeffs = c.get("coeffs", [0,0,0,0])
k1, k2, p1, p2 = coeffs[:4]

yaml = f"""cameras:
- camera:
    distortion:
      parameters:
        cols: 1
        rows: 4
        data: [{k1:.9f}, {k2:.9f}, {p1:.9f}, {p2:.9f}]
      type: radial-tangential
    image_height: {height}
    image_width: {width}
    intrinsics:
      cols: 1
      rows: 4
      data: [{fx:.9f}, {fy:.9f}, {cx:.9f}, {cy:.9f}]
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
  description: 'wild_{Path("$SEQ").name}'
label: wild_{Path("$SEQ").name}
"""
out.write_text(yaml)
print("Generated calib:", out)
PY

  roslaunch svo_ros mono_no_imu.launch calib_file:="$CALIB" &
  SVO_PID=$!
  sleep 4

  rosbag record -O "$OUT/svo_pose.bag" /svo/pose_cam/0 &
  REC_PID=$!
  sleep 3

  python3 - <<PY
import os, time, cv2, rospy
from cv_bridge import CvBridge
from sensor_msgs.msg import Image

seq = "$DATA"
rgb_txt = os.path.join(seq, "rgb.txt")

rospy.init_node("wild_rgb_player", anonymous=True)
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

  kill -INT "$REC_PID" || true
  sleep 5

  kill -INT "$SVO_PID" || true
  sleep 4

  if [ -f "$OUT/svo_pose.bag.active" ]; then
    echo "WARNING: bag still active/corrupt for $SEQ" | tee "$OUT/status.txt"
    continue
  fi

  python3 - <<PY
import rosbag, os

inbag = "$OUT/svo_pose.bag"
outtum = "$OUT/traj_est.tum"

count = 0
if os.path.exists(inbag):
    with rosbag.Bag(inbag, 'r') as bag, open(outtum, 'w') as f:
        for _, msg, _ in bag.read_messages(topics=['/svo/pose_cam/0']):
            ts = msg.header.stamp.to_sec()
            p = msg.pose.position
            q = msg.pose.orientation
            f.write(f"{ts:.9f} {p.x:.9f} {p.y:.9f} {p.z:.9f} {q.x:.9f} {q.y:.9f} {q.z:.9f} {q.w:.9f}\\n")
            count += 1

print("converted poses:", count)
open("$OUT/converted_poses.txt", "w").write(str(count) + "\\n")
PY

  if [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      -a > "$OUT/ape_stats.txt" || true

    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      -a --plot --save_plot "$OUT/ape_plot.png" || true

    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      > "$OUT/ape_stats_no_align.txt" || true

    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      --plot --save_plot "$OUT/ape_plot_no_align.png" || true
  else
    echo "No valid trajectory generated." > "$OUT/ape_stats.txt"
    echo "No valid trajectory generated." > "$OUT/ape_stats_no_align.txt"
  fi

  echo "Finished $SEQ"
done

echo "All Wild sequences processed."
