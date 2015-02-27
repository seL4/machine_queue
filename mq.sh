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
    echo "run      Run a new job on a machine"
    echo "systems  Query information on available machines"
    echo
    echo "sem      Directly interact with the machine locks"
}

# Check the version of our scripts compared to the cannonical host
if ! diff "${SCRIPT_PATH}/VERSION" <(RemoteCommand cat "${BASE}/VERSION" | tr -d '\r'); then
    echo "Local version of mq.sh appears to differ to version on ${HOST} at ${BASE}"
    exit -1
fi

# Expect command to be run to be the first argument
if [ "$#" -lt 1 ]; then
    Usage
    exit -1
fi

command=$1
shift
case "$command" in
    run)
        Enqueue "$@"
        # Should not get here
        exit -1
    ;;
    systems)
        SystemList
        exit 0
    ;;
    help|*)
        Usage
        exit 0
    ;;
esac
