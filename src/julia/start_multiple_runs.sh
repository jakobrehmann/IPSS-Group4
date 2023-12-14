#!/bin/sh

#SBATCH -N 1
#SBATCH -t 01:30:00
#SBATCH -A bzz0020

module load julia

OUTPUT_FOLDER_NAME=sensitivity_rec_0.5

mkdir $OUTPUT_FOLDER_NAME

for prob in `seq 0.1 0.05 .3`; do
        julia run_on_cluster.jl $prob 0 $OUTPUT_FOLDER_NAME &
        julia run_on_cluster.jl $prob 1 $OUTPUT_FOLDER_NAME &
        julia run_on_cluster.jl $prob 2 $OUTPUT_FOLDER_NAME &
done

wait