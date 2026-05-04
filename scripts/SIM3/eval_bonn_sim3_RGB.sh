#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
evo_config set plot_backend Agg

DATA_ROOT=/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Bonn
OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/bonn

SEQS=(
  rgbd_bonn_balloon
  rgbd_bonn_balloon2
  rgbd_bonn_crowd
  rgbd_bonn_crowd2
  rgbd_bonn_person_tracking
  rgbd_bonn_person_tracking2
  rgbd_bonn_moving_nonobstructing_box
  rgbd_bonn_moving_nonobstructing_box2
)

for SEQ in "${SEQS[@]}"; do
  DATA="$DATA_ROOT/$SEQ"
  OUT="$OUT_ROOT/$SEQ"

  echo "=== $SEQ Sim(3) ==="

  if [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      -a -s > "$OUT/ape_stats_sim3.txt" || true

    evo_ape tum "$DATA/groundtruth.txt" "$OUT/traj_est.tum" \
      -a -s --plot --save_plot "$OUT/ape_plot_sim3.png" || true
  else
    echo "Missing traj_est.tum" > "$OUT/ape_stats_sim3.txt"
  fi
done