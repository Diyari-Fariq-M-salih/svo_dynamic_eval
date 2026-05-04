#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
evo_config set plot_backend Agg

DATA_ROOT=/workspaces/svo_dynamic_eval/external/WildGS-SLAM/scripts_downloading/datasets/Wild_SLAM_Mocap
OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/wild_slam_mocap

declare -A DATA_PATHS=(
  [scene1_ball]="scene1/ball"
  [scene1_crowd]="scene1/crowd"
  [scene1_person_tracking]="scene1/person_tracking"
  [scene1_racket]="scene1/racket"
  [scene1_stones]="scene1/stones"
  [scene1_table_tracking1]="scene1/table_tracking1"
  [scene1_table_tracking2]="scene1/table_tracking2"
  [scene1_umbrella]="scene1/umbrella"
  [scene2_ANYmal1]="scene2/ANYmal1"
  [scene2_ANYmal2]="scene2/ANYmal2"
)

for SEQ in "${!DATA_PATHS[@]}"; do
  OUT="$OUT_ROOT/$SEQ"
  DATA="$DATA_ROOT/${DATA_PATHS[$SEQ]}"
  GT="$DATA/groundtruth.txt"

  echo "=== $SEQ Sim(3) ==="
  echo "GT: $GT"

  if [ -s "$GT" ] && [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$GT" "$OUT/traj_est.tum" \
      -a -s > "$OUT/ape_stats_sim3.txt" || true

    evo_ape tum "$GT" "$OUT/traj_est.tum" \
      -a -s --plot --save_plot "$OUT/ape_plot_sim3.png" || true
  else
    echo "Missing GT or traj_est.tum" > "$OUT/ape_stats_sim3.txt"
  fi
done