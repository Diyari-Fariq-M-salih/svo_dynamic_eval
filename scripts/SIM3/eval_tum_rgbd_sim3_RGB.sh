#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
evo_config set plot_backend Agg

OUT_ROOT=/workspaces/svo_dynamic_eval/results/svo/tum_rgbd

for OUT in "$OUT_ROOT"/rgbd_dataset_*; do
  [ -d "$OUT" ] || continue

  SEQ=$(basename "$OUT")

  # skip no-align folders
  if [[ "$SEQ" == *_no_align ]]; then
    continue
  fi

  echo "=== $SEQ Sim(3) ==="

  GT=""
  for CAND in \
    "$OUT/groundtruth.txt" \
    "$OUT/traj_gt.tum" \
    "$OUT/gt.tum"; do
    if [ -s "$CAND" ]; then
      GT="$CAND"
      break
    fi
  done

  if [ -z "$GT" ]; then
    GT=$(find /workspaces/svo_dynamic_eval -type f \( -name "groundtruth.txt" -o -name "traj_gt.tum" \) | grep "$SEQ" | head -1 || true)
  fi

  if [ -n "$GT" ] && [ -s "$OUT/traj_est.tum" ]; then
    echo "GT: $GT"

    evo_ape tum "$GT" "$OUT/traj_est.tum" \
      -a -s > "$OUT/ape_stats_sim3.txt" || true

    evo_ape tum "$GT" "$OUT/traj_est.tum" \
      -a -s --plot --save_plot "$OUT/ape_plot_sim3.png" || true
  else
    echo "Missing GT or traj_est.tum" > "$OUT/ape_stats_sim3.txt"
  fi
done