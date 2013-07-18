#!/bin/bash

. /scratch/bamboo/machine_queue/common

if [ "$1" = "-n" ]; then
    echo "2"
    exit 0
fi

ci=$1
jobid=$2

LOG_FILE="$BASE/$jobid/output"
REBOOT_CMD="/tftpboot/vtd2/reboot"
if [ "$ci" = "-c" ]; then
    COMPLETION_TXT=`cat "$BASE/$jobid/completion"`
    INPUT="/dev/null"
else
    COMPLETION_TEXT=""
    INPUT="$BASE/$jobid/input.pipe"
fi

if [ "$ci" = "-r" ]; then
    ssh consoles "console -f vtd2" < $INPUT | tee "$BASE/$jobid/output.pipe"
else
    $REBOOT_CMD $INTERACT $ci "$COMPLETION_TXT" -t -1 -l "$LOG_FILE" -k "$BASE/$jobid/file0" -u "$BASE/$jobid/file1" < $INPUT | tee "$BASE/$jobid/output.pipe"
fi

echo "Success" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$BASE/$jobid/input.pipe"
fi

exit 0
