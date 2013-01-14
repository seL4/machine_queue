#!/bin/bash

. /scratch/bamboo/machine_queue/common

KillChild () {
    kill -- -$pid
}

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 system"
    exit 1
fi
system=$1

Lock

job=`grep "^[0-9]* RUNNING $system" $QUEUE`
if [ "$job" != "" ]; then
    echo "Already have running jobs on $system!"
    Unlock
    exit 1
fi

job=`grep "^[0-9]* QUEUED $system" $QUEUE | head -1`
if [ "$job" = "" ]; then
    echo "No jobs to run on $system"
    Unlock
    exit 0
fi

temp=( $job )
jobid=${temp[0]}
user=${temp[3]}
ci=${temp[6]}

# Set job to running
datetime=`date +"%D %T"`
perl -i -p -e "s/^($jobid .*\n)//m" $QUEUE
echo "$jobid RUNNING $system $user `date +"%D %T"` $ci" >> $QUEUE

# Finished modifying state, can unlock while we actually run the job
Unlock

echo "Starting your job" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-i" ]; then
    echo "Your job is now running interractively. ctrl+d to complete" > "$BASE/$jobid/output.pipe"
    $BASE/run_$system.sh $ci $jobid
else
    echo "Your job is running till completion text. ctrl+c to indicate job failure" > "$BASE/$jobid/output.pipe"
    trap 'KillChild' SIGINT SIGTERM
    setsid $BASE/run_$system.sh $ci $jobid &
    pid=$!
    read result < $BASE/$jobid/input.pipe
    if [ "$result" = "Close" ]; then
        echo "Killing job at user request"
        kill -- -$pid
    else
        wait $pid
    fi
    trap '' SIGINT SIGTERM
fi

# Complete the job
echo "Job $jobid complete"

Lock
perl -i -p -e "s/^($jobid .*\n)//m" $QUEUE
echo "$jobid COMPLETE $system $user `date +"%D %T"` $ci" >> $QUEUE
Unlock

# Delete the completion semaphore to signal job is done
rm -f "$BASE/$jobid/complete.lock"
