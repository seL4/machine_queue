#!/bin/bash

. /scratch/bamboo/machine_queue/common

Usage () {
    echo "Usage: $0 -r|-i|-c <string> -l logfile -s system -f file1 -f file2 .. -f filen"
}

# Removes the current job from the runqueue
# Assumes lock is already held
RemoveJob () {
rm -rf "$jobdir"
rm -rf "$jobdir"
perl -i -p -e "s/^($jobid .*\n)//m" "$QUEUE"
chown :ertos_src "$QUEUE" 2>&1 > /dev/null
chmod g+rw "$QUEUE" 2>&1 > /dev/null
}

# If the job we enqued is still queued (and not running or completed) then removeit it
# sets a return value for whether the job was running or not
RemoveIfQueued () {
    Lock
    if grep -q "^$jobid QUEUED" "$QUEUE"; then
        RemoveJob
        result="QUEUED"
    else
        result="NOTQUEUED"
    fi
    Unlock
}

CleanupJob () {
    RemoveIfQueued
    if [ "$closeremote" != "" ]; then
        # We need to notify the server. But only if we were running
        # If we weren't running then the server will not be listening
        # so we are done
        # If we were running then don't exit yet so we can try
        # and keep running and get any partial output
        # clear closeremote so that a second signal will definitely kill us
        closeremote=""
        if [ "$result" = "QUEUED" ]; then
            # Pack up and go home
            kill -- -$outpid
            exit 0
        else
            echo "Cleaning up job, please wait a few seconds"
            echo "Close" > $inpipe
        fi
    else
        kill -- -$outpid
        exit 0
    fi
}

# Parse the command line
file_count=0
while [ "$#" -ne 0 ]; do
    case "$1" in
        -l)
            shift
            logfile="$1"
        ;;
        -c)
            shift
            completion="$1"
            if [ "$interact" != "" ]; then
                Usage
                exit -1
            fi
            interact="-c"
        ;;
        -i)
            interact="-i"
            if [ "$completion" != "" ]; then
                Usage
                exit -1
            fi
        ;;
        -r)
            interact="-r"
        ;;
        -f)
            shift
            if [ "$files" != "" ]; then
                files="$files\n"
            fi
            files="$files$1"
            file_count=`expr "$file_count" + 1`
        ;;
        -s)
            shift
            system="$1"
        ;;
        --)
            break
        ;;
        -[A-Za-z]*)
            echo "Unknown option $1"
            Usage
            exit -1
        ;;
        *)
            break
        ;;
    esac
    shift
done

if [ "$logfile" = "" ]; then
    Usage
    exit -1
fi
if [ "$system" = "" ]; then
    Usage
    exit -1
fi
if [ "$interact" = "" ]; then
    Usage
    exit -1
fi

# Check system is valid
system_runner="$BASE/run_""$system"".sh"
if ! [  -x "$system_runner" ]; then
    echo "System $system does not exist"
    exit -1
fi
# Check we got enough files
if [ "$interact" != "-r" ]; then
    system_file_count=`"$system_runner" -n`
    if [ "$file_count" -ne "$system_file_count" ]; then
        echo "Expected $system_file_count files, only $file_count provided"
        exit -1
    fi
fi

# Grab the main lock
Lock

# Increment job ID
last_jobid=`cat "$QUEUE" | cut -f 1 -d' ' | sort | tail -1`
if [ "$last_jobid" == "" ]
then
    jobid="0"
else
    jobid=`expr "$last_jobid" + 1`
fi

echo "Creating Job with ID $jobid"
echo "There are already `wc -l "$QUEUE" | cut -f 1 -d' '` jobs in queue"

# Add job entry to the run queue
echo "$jobid QUEUED $system $USER `date +"%D %T"` $interact" >> $QUEUE

# Make the directory for the job
jobdir="$BASE/$jobid"
mkdir "$jobdir"
# Copy all the files, unless the job is just a reservation
if [ "$interact" != "-r" ]; then
    i=0
    echo -e "$files" | while read file; do
        echo "Copying input file ($i) \"$file\""
        cp "$file" "$jobdir/file$i"
        i=`expr "$i" + 1`
    done
    if [ "$interact" = "-c" ]; then
        echo -e "$completion" > "$jobdir/completion"
    fi
fi

# Construct the output pipe
outpipe="$jobdir/output.pipe"
mkfifo "$outpipe"

inpipe="$jobdir/input.pipe"
mkfifo "$inpipe"

# Create the completion semaphore
lockfile "$jobdir/complete.lock"

# Make sure permissions are sane
chown :ertos_src -R "$jobdir"
chmod g+rw -R "$jobdir"
chmod g+x "$jobdir"

# Setup is done, release the lock
Unlock

echo "Job is queued, notifying bamboo"

# Notify bamboo. This is pretty hard coded and could probably be better abstracted, perhaps
# into the run_<system>.sh scripts?
if [ "$system" = "kzm" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDKZMJOBS'
elif [ "$system" = "beagle" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDBEAGLEJOBS'
elif [ "$system" = "panda" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDPANDAJOBS'
elif [ "$system" = "arndale" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDARNDALEJOBS'
elif [ "$system" = "odroid" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDODROIDJOBS'
elif [ "$system" = "vtd2" ]; then
    curl --user admin:ertos -X POST -d 'JOB1&ExecuteAllStages' 'http://saison.keg.ertos.in.nicta.com.au:8085/rest/api/latest/queue/TOOLS-RUNQUEUEDVTD2JOBS'
fi

# Setup a trap handler that will remove this job and notify the server if we try and quit
trap 'CleanupJob' SIGINT SIGTERM
# Hookup the output pipe
setsid bash -c "trap 'exit 0' SIGINT SIGTERM; while true; do cat \"$outpipe\"; done" &
outpid=$!

# Hook up pipe and wait
if [ "$interact" != "-c" ]; then
    cat > $inpipe
    # Wait on the completion semaphore
    lockfile "$jobdir/complete.lock"
else
    closeremote=true
    # Wait on the completion semaphore
    if ! lockfile "$jobdir/complete.lock"; then
        lockfile "$jobdir/complete.lock"
    fi
    closeremote=""
fi

# Kill the output pipe
kill -- -$outpid
outpid=0

# Everything is cleaned up, no longer need the trap handler
trap '' SIGINT SIGTERM


# Should be complete
echo "Job complete"

# Grab the main lock
Lock

# Verify our job is complete
if ! grep -q "^$jobid COMPLETE" "$QUEUE"; then
    echo "Job failed to complete or missing!"
    Unlock
    exit 1
fi

# Copy the output
echo "Copying output to \"$logfile\""
cp "$jobdir/output" "$logfile"

# Cleanup the job
echo "Cleaning up job"
RemoveJob

# Release the lock and go home
Unlock
echo "Done"
