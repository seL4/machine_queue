#!/bin/sh

file_to_dir() {
    F="$1"
    while test -h "$F"
    do
	cd $(dirname "$F")
	F=$(readlink "$F")
    done;
    cd $(dirname "$F")
    pwd
}

SCRIPT_PATH=$(file_to_dir "$0")
cmdname=$(basename "$0")

# Include common elements
. "${SCRIPT_PATH}/scripts/common"

Usage () {
    echo "Machine Queue"
    echo
    echo " Commands:"
    echo
    echo "  run         Run a new job on a machine"
    echo "  systems     Query information on available machines"
    echo "  system-tsv  List available machines as tab-separated values"
    echo "  pool-tsv    List available machine pools as tab-separated lists"
    echo "  features    List which boards support non-standard features"
    echo
    echo "  sem         Directly interact with the machine locks"
    echo
    echo "Use '$cmdname COMMAND help' to get detailed help for each command"
}

# Expect command to be run to be the first argument
if [ "$#" -lt 1 ]; then
    Usage
    exit 1
fi

command=$1
shift
case "$command" in
    systems)
        OutputSystemList "$@"
        exit 0
    ;;
    system-tsv)
        OutputSystemTSV
        exit 0
    ;;
    pool-tsv)
        OutputPoolTSV
        exit 0
    ;;
    features)
        OutputFeatureList
        exit 0
    ;;
    help)
        Usage
        exit 0
    ;;
esac


# Check we can talk to the cannonical host
if ! RemoteCommand exit; then
    echo "Unable to ssh to ${HOST}"
    exit 1
fi

# Check the version of our scripts compared to the canonical host
if ! RemoteCommand cat "${BASE}/VERSION" |
	diff "${SCRIPT_PATH}/VERSION" -
then
    echo "Local version of mq.sh appears to differ from version on ${HOST} at ${BASE}"
    exit 1
fi

# Determine the remote user name
REMOTEUSER=$(RemoteCommand whoami)

case "$command" in
    run)
        Enqueue "$@"
        # Should not get here
        exit 1
    ;;
    sem)
        UserLock "$@"
        # Should not get here
        exit 1
    ;;
    help|*)
        Usage
        exit 0
    ;;
esac
