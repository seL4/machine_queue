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
    ssh consoles "console -f $console" < $INPUT | tee "$BASE/$jobid/output.pipe"
elif [ "$ci" = "-c" ] ; then
    $REBOOT_CMD -c "$COMPLETION_TXT" -t -1 -l "$LOG_FILE" "$BASE/$jobid/file0" < $INPUT | tee "$BASE/$jobid/output.pipe"
else
    # Need to special case -c and -i because you cannot specify a blank command line option after -i
    $REBOOT_CMD -i -t -1 -l "$LOG_FILE" "$BASE/$jobid/file0" < $INPUT | tee "$BASE/$jobid/output.pipe"
fi

echo "Success" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$BASE/$jobid/input.pipe"
fi

exit 0
