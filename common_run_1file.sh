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
    # spawn console session
#    mkfifo "$BASE/$jobid/console.pipe"
    # This here almost works, except when I try and kill the pid later I have an invalid pid.
    # why? I have no idea, but if this is executed it will leave console sessions open
    # all over the place. We also redirect the output to 3 different places, which
    # is possibly a little insane
    # There is also no error handling of the console command failing and all the logic will
    # probably get very fucked up / confused if that happens
    setsid bash -c "console -f $console | { while read line; do echo \$line; echo \$line >> \"$BASE/$jobid/output.pipe\"; echo \$line >> $LOG_FILE; done; }" &
    pid=$!
    while read input
    do
#        echo $input >> "$BASE/$jobid/console.pipe"
    done < $INPUT
    kill -- -$pid
    # Reservations cannot fail as it doesn't make sense
    echo "0" > "$BASE/$jobid/return"
elif [ "$ci" = "-c" ] ; then
    $REBOOT_CMD -c "$COMPLETION_TXT" -t -1 -l "$LOG_FILE" -k "$BASE/$jobid/file0" < $INPUT 2>&1 | tee "$BASE/$jobid/output.pipe"
    echo ${PIPESTATUS[0]} > "$BASE/$jobid/return"
else
    # Need to special case -c and -i because you cannot specify a blank command line option after -i
    $REBOOT_CMD -i -t -1 -l "$LOG_FILE" -k "$BASE/$jobid/file0" < $INPUT 2>&1 | tee "$BASE/$jobid/output.pipe"
    echo ${PIPESTATUS[0]} > "$BASE/$jobid/return"
fi

echo "Success" > "$BASE/$jobid/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$BASE/$jobid/input.pipe"
fi

exit 0
