#!/bin/bash

# Determine root directory of script. This is some black magic found on stackoverflow
pushd . > /dev/null
SCRIPT_PATH="${BASH_SOURCE[0]}";
if ([ -h "${SCRIPT_PATH}" ]) then
  while([ -h "${SCRIPT_PATH}" ]) do cd `dirname "$SCRIPT_PATH"`; SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi
cd `dirname ${SCRIPT_PATH}` > /dev/null
SCRIPT_PATH=`pwd`;
popd  > /dev/null

# Include common elements
. "${SCRIPT_PATH}/scripts/common"

Usage () {
    echo "Machine Queue"
    echo
    echo "General user commands:"
    echo
    echo "run      Run a new job on a machine"
    echo "enqueue  Enqueue a job to be collected later"
    echo "systems  Query information on available machines"
    echo
    echo "Management commands:"
    echo
    echo "Server commands:"
    echo
    echo "dequeue  Run a job in the queue"
    echo
}

# Expect command to be run to be the first argument
if [ "$#" -lt 1 ]; then
    Usage
    exit -1
fi

command=$1
shift
case "$command" in
    run)
        EnqueueSynchronous "$@"
        # Should not get here
        exit -1
    ;;
    dequeue)
        Dequeue "$@"
        # Should not get here
        exit -1
    ;;
    help|*)
        Usage
        exit 0
    ;;
esac
