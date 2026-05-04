#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
evo_config set plot_backend Agg

OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/euroc

SEQS=(
  V1_01_easy
  V1_02_medium
  V1_03_difficult
  V2_01_easy
  V2_02_medium
  V2_03_difficult
)

for SEQ in "${SEQS[@]}"; do
  OUT="$OUT_ROOT/$SEQ"

  echo "=== $SEQ Sim(3) ==="

  if [ -s "$OUT/traj_gt.tum" ] && [ -s "$OUT/traj_est.tum" ]; then
    evo_ape tum "$OUT/traj_gt.tum" "$OUT/traj_est.tum" \
      -a -s > "$OUT/ape_stats_sim3.txt" || true

    evo_ape tum "$OUT/traj_gt.tum" "$OUT/traj_est.tum" \
      -a -s --plot --save_plot "$OUT/ape_plot_sim3.png" || true
  else
    echo "Missing traj_gt.tum or traj_est.tum" > "$OUT/ape_stats_sim3.txt"
  fi
done