#!/bin/bash
#SBATCH -J FastQC
#SBATCH -p batch
#SBATCH --ntasks=12
#SBATCH --mem 50gb
#SBATCH -t 140:00:00
#SBATCH --output=/scratch/drt83172/Wallace_lab/Mapping_and_QTL/Mapping_and_QTL/Outfiles/FastQC.%j.out
#SBATCH -e /scratch/drt83172/Wallace_lab/Mapping_and_QTL/Mapping_and_QTL/Outfiles/FastQC.%j.err
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user drt83172@uga.edu

echo "This JobID for this job is ${SLURM_JOB_ID}."
sleep 5
echo "Done."

sacct -j $SLURM_JOB_ID --format=JobID,JobName,AllocCPUS,Elapsed,ExitCode,State,MaxRSS,TotalCPU

module load FastQC/0.11.9-Java-11
module load parallel/20230722-GCCcore-12.2.0

./RunFastQC.sh /scratch/drt83172/Wallace_lab/Mapping_and_QTL/Mapping_and_QTL/Data/Flex_Data/Sequences
