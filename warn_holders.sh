#!/bin/sh
export PATH=/usr/local/lib/machine_queue:$PATH
now=`date +'%s'`
timeLimit=7200

warn() {
    mail -a 'From: LockBot@trustworthy.systems' $1@trustworthy.systems -s "Lock for $2 held for a long time" <<EOF
    Hi $1,
    You have now held the machine queue lock for $2 for 
    over `expr $diff / 3600` hours.  That's OK if you're still using $2, 
    but otherwise,  please release the lock 

    The Lockbot will remind you every four hours ...
    Your friendly lockbot.
EOF
}

mq.sh sem dumpall |
    while read system lockstate user day time zone key
    do
	[ $lockstate = FREE ] && continue
	secs=$(date -d "$day $time $zone" +'%s')
	diff=$(expr $now - $secs)
	[ $diff -gt $timeLimit ] && warn "$user" "$system" "$diff"
    done
