#!/bin/bash

. /scratch/bamboo/machine_queue/common

if [ "$1" = "-n" ]; then
    echo "1"
    exit 0
fi

ci=$1
jobid=$2

LOG_FILE="$BASE/$jobid/output"
REBOOT_CMD="/tftpboot/kzm11/reboot"
if [ "$ci" = "-c" ]; then
    COMPLETION_TXT=`cat "$BASE/$jobid/completion"`
    INPUT="/dev/null"
else
    COMPLETION_TEXT=""
    INPUT="$BASE/$jobid/input.pipe"
fi

$REBOOT_CMD $INTERACT $ci "$COMPLETION_TXT" -t -1 -l "$LOG_FILE" "$BASE/$jobid/file0" < $INPUT > "$BASE/$jobid/output.pipe"

echo "Success" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$BASE/$jobid/input.pipe"
fi

exit 0
