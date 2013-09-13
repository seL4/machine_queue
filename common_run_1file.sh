#!/bin/bash

#This file runs a generic machine that has reboot scripts and is on consoles

. /scratch/bamboo/machine_queue/common

if [ "$1" = "-n" ]; then
    echo "1"
    exit 0
fi

ci=$1
jobid=$2
machine=$3
console=$4

LOG_FILE="$BASE/$jobid/output"
REBOOT_CMD="/tftpboot/$machine/reboot"
if [ "$ci" = "-c" ]; then
    COMPLETION_TXT=`cat "$BASE/$jobid/completion"`
    INPUT="/dev/null"
else
    COMPLETION_TEXT=""
    INPUT="$BASE/$jobid/input.pipe"
fi

if [ "$ci" = "-r" ]; then
    echo "Reservations not allowed!" | tee "$BASE/$jobid/output.pipe"
    # spawn console session
#    echo "Spawning console session"
#    mkfifo "$BASE/$jobid/console.pipe"
    # This here almost works, except when I try and kill the pid later I have an invalid pid.
    # why? I have no idea, but if this is executed it will leave console sessions open
    # all over the place
#    setsid bash -c "console -f $console" | tee "$BASE/$jobid/output.pipe" &
#    pid=$!
#    echo "Console session spawned"
#    while read input
#    do
#        echo "Read input line $input"
#        echo $input >> "$BASE/$jobid/console.pipe"
#    done < $INPUT
#    echo "Input terminated, trying to close now"
#    kill -- -$pid
#    ssh consoles "console -f $console" < $INPUT | tee "$BASE/$jobid/output.pipe"
elif [ "$ci" = "-c" ] ; then
    $REBOOT_CMD -c "$COMPLETION_TXT" -t -1 -l "$LOG_FILE" -k "$BASE/$jobid/file0" < $INPUT | tee "$BASE/$jobid/output.pipe"
else
    # Need to special case -c and -i because you cannot specify a blank command line option after -i
    $REBOOT_CMD -i -t -1 -l "$LOG_FILE" -k "$BASE/$jobid/file0" < $INPUT | tee "$BASE/$jobid/output.pipe"
fi

echo "Success" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$BASE/$jobid/input.pipe"
fi

exit 0
