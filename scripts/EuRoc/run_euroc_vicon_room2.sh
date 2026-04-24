#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
source /workspaces/svo_dynamic_eval/svo_full_ws/devel/setup.bash

DATA_ROOT=/workspaces/svo_dynamic_eval/external/euroc/vicon_room2
OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/euroc

SEQS=(
  V2_01_easy
  V2_02_medium
  V2_03_difficult
)

RATES=(
  1.0
  1.0
  1.0
)

for i in "${!SEQS[@]}"; do
  SEQ="${SEQS[$i]}"
  RATE="${RATES[$i]}"

  echo "======================================"
  echo "Running $SEQ at rate $RATE"
  echo "======================================"

  DATA="$DATA_ROOT/$SEQ"
  OUT="$OUT_ROOT/$SEQ"
  mkdir -p "$OUT"

  rm -f "$OUT/svo_pose.bag" "$OUT/traj_est.tum" "$OUT/ape_stats.txt" "$OUT/ape_plot.png"

  roslaunch svo_ros euroc_vio_mono.launch &
  SVO_PID=$!

  sleep 5

  rosbag record -O "$OUT/svo_pose.bag" /svo/pose_imu &
  REC_PID=$!

  sleep 2

  rosbag play "$DATA/$SEQ.bag" --clock -r "$RATE"

  sleep 2
  kill -INT "$REC_PID" || true
  sleep 2
  kill -INT "$SVO_PID" || true
  sleep 5

  echo "Bag info:"
  rosbag info "$OUT/svo_pose.bag" || true

  python3 - <<PY
import rosbag

inbag = "$OUT/svo_pose.bag"
outtum = "$OUT/traj_est.tum"

count = 0
with rosbag.Bag(inbag, "r") as bag, open(outtum, "w") as f:
    for _, msg, _ in bag.read_messages(topics=["/svo/pose_imu"]):
        ts = msg.header.stamp.to_sec()
        p = msg.pose.pose.position
        q = msg.pose.pose.orientation
        f.write(f"{ts:.9f} {p.x:.9f} {p.y:.9f} {p.z:.9f} {q.x:.9f} {q.y:.9f} {q.z:.9f} {q.w:.9f}\\n")
        count += 1

print("converted poses:", count)
PY

  if [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$OUT/traj_gt.tum" "$OUT/traj_est.tum" \
      -a > "$OUT/ape_stats.txt" || true

    evo_ape tum "$OUT/traj_gt.tum" "$OUT/traj_est.tum" \
      -a --plot --save_plot "$OUT/ape_plot.png" || true
  else
    echo "No valid trajectory generated." > "$OUT/ape_stats.txt"
  fi

  echo "Finished $SEQ"
done

echo "All EuRoC Vicon Room 2 sequences processed."