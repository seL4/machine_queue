#!/bin/bash

. /home/adanis/machine_queue/common

if [ "$1" = "-n" ]; then
    echo "1"
    exit 0
fi

ci=$1
jobid=$2

jobdir="$BASE/$jobid"

# find prefix for host
case $(hostname) in
    duvel|consoles)
        COMMAND_PREFIX=
    ;;
    *)
        COMMAND_PREFIX="ssh -t consoles"
    ;;
esac

DEVICE_NAME="beagle1"
LOG_FILE="$jobdir/output"
REBOOT_CMD="/tftpboot/powerbar $DEVICE_NAME --cycle"
if [ "$ci" = "-c" ]; then
    COMPLETION_TXT=`cat "$jobdir/completion"`
    INPUT="/dev/null"
else
    INTERACT="-i"
    INPUT="$jobdir/input.pipe"
fi
FILE_DST="/tftpboot/$DEVICE_NAME/seL4-image"
FILE_SRC="$jobdir/file0"
scp "$FILE_SRC" "consoles:$FILE_DST"

readelf -h "$FILE_SRC" > /dev/null 2>&1
NOT_ELF=$?

expect -c "
# Initialise our global pid variables
set con_pid    0

# cleanup function
proc abort {retval} {
  global con_pid
  log_file
  close \$con_pid 
  exit \$retval
}

# open the console
spawn $COMMAND_PREFIX console -f $DEVICE_NAME
set con_pid \$spawn_id
log_file $LOG_FILE

# reboot the machine
spawn $COMMAND_PREFIX $REBOOT_CMD
set ret [ wait ]
if { [lindex \$ret 2] != 0 || [lindex \$ret 3] != 0 } {
    abort 1;
}

# wait for uboot prompt
expect -i \$con_pid \
  \"OMAP3 beagleboard.org #\" { } \
  default { abort 1 }

# load the image file via dfu-util
set timeout 60
spawn $COMMAND_PREFIX dfu-util -D $FILE_DST
expect \
eof { } \
default { abort 1 }

# load image through tftpboot
send -i \$con_pid \"dhcp\n\"

# check the return value
set ret [ wait ]
if { [lindex \$ret 2] != 0 || [lindex \$ret 3] != 0 } {
  abort 1;
}

# boot the image file
sleep 1
if { $NOT_ELF } {
  send -i \$con_pid \"bootm\n\"
} else {
  send -i \$con_pid \"bootelf\n\"
}
expect -i \$con_pid \
  \"## Starting application\" { } \
  \"## Booting kernel from Legacy Image\" { } \
  default { abort 1 }

#done

if { \"$COMPLETION_TXT\" != \"\" } {
  # Wait for completion text
  expect -i \$con_pid \
   \"$COMPLETION_TXT\" { } \
   default { abort 1 }
}

if { \"$INTERACT\" != \"\" } {
  # Make the console interactive
  interact -i \$con_pid
}

abort 0" < $INPUT > "$jobdir/output.pipe"

echo "Success" > "$jobdir/output.pipe"

if [ "$ci" = "-c" ]; then
    echo "Done" > "$jobdir/input.pipe"
fi

exit 0
