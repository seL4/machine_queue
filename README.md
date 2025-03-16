<!--
     Copyright 2023 UNSW, Sydney

     SPDX-License-Identifier: CC-BY-SA-4.0
-->

Machine Queue
===============

This project contains the scripts to allow remote access to the suite
of machines maintained by the Trustworthy Systems group at UNSW,
Sydney for testing seL4 and systems built on seL4.

Close collaborators and seL4 Foundation members can request access,
and use these scripts to deploy their payloads onto our CI
infrastructure; they are also used by GitHub's
[CI Actions](https://github.com/seL4/ci-actions) for seL4.


Set Up
========

After you have a Trustworthy Systems account set up, clone this
repository, and create a symlink from `mq.sh` to somewhere in your
`$PATH`.

For example, you can do:
  ```
  git clone git@github.com:seL4/machine_queue.git
  H=$(pwd)/mq.sh
  cd ~/bin
  ln -s $H/mq.sh mq
  ```

The mq scripts assume a standard POSIX system, that `/bin/sh` is
POSIX compliant, and that you can use `ssh` to reach
`tftp.keg.cse.unsw.edu.au` without password.  To set up the latter,
add to your `~/.ssh/config`:
 ```
 Host tftp.keg.cse.unsw.edu.au
     ProxyJump login.trustworthy.systems
	 ControlMaster auto
     ControlPersist 300
     ControlPath /home/%u/.ssh/controlmaster/%h-%p-%r.sock
     ServerAliveInterval 60
     TCPKeepAlive yes
 ```
or clauses with similar effect.  The script makes many `ssh`
connections in a row; without the control multiplexing this can get
painfully slow.


Usage
======

`mq` has many subcommands:
 * `run` --- run a payload on a system
 * `systems` --- list available systems
 * `sem` --- interact directly with locks
 * `system-tsv` --- list available systems as tab-separated values
 * `pool-tsv` --- list available pools of systems as tab-separated
   values

`mq run`
--------
`mq.sh run -r|-c` _<string>_ `[-l ` _logfile_ `] -s` _system_ `[-w` _retry-time_ `] [-t `_retry-count_` ] [-n] [-a] [-d` _timeout_ `] [-e` _<string>_`] [-k `_<string>_`] [-L] -f `_file1_ `[-f `_file2_`]
.. [-f` _filen_ `]`

   Acquires a lock for the machine called _system_ (or a machine in
   the pool called _system_), and, once locked, runs the specified job.

   Output from the machine is collected and passed back to the
   user both on stdout and into an optional logfile.

   Jobs can be cancelled at any time with ^C, which will notify the server
   (if the job is running) and remove the job from the queue.

   Returns 0 on success, nonzero if something went wrong

Options:

- `-r`          Reserves the device. Will not reboot or run an image
- `-n`          No lock changes. Checks that you have the lock, and then runs an image. Will not unlock afterwards.
- `-a`          Keep the machine alive after completion or error text
 detected. The console becomes read-write after the text has been found.
- `-c` _TEXT_     Image is run until the specified regular completion
 text.
- `-e` _TEXT_     Image is run until the specified error text is found.
- `-d` _TIME_     Timeout (in seconds) to wait for the completion text (default -1 AKA no timeout)
- `-k` _KEY_      Key for obtaining the lock
- `-l` _FILE_     Optional location to write all the console output to
- `-L`          This is a Linux image not seL4
- `-s` _TEXT_     Specifies which machine this job is for
- `-f` _FILE_ [+] Files to use as the job image.  Most systems need a
    single image file; x86 currently expects two, the kernel and the root task.
- `-w` _TIME_     Number of seconds to wait between each attempt to acquire the lock (default 8)
- `-t` _RETRIES_  Number of retries to perform for acquiring the lock (default -1)


`mq sem dumpall|-signal|-wait|-cancel|-info `_<system>_` [-f] [-w `_retry-time_` ] [-t `_retry-count_` ] [-k `_LOCK_\__KEY_` ] [-T` _timeout_`]`

   Manually manipulate locks for machines. The lock for each system
   can be acquired or released.

   You can forcibly release a lock for a system that you do not
   currently own by using the `-f` flag

 Options:

- `-info` _SYSTEM_     Display lock information for the specified SYSTEM
- `-mr-info` _SYSTEM_  Display lock information for the specified SYSTEM in machine-readable format
- `-signal` _SYSTEM_   Release the lock for the specified SYSTEM
- `-wait` _SYSTEM_     Acquire the lock for the specified SYSTEM
- `-cancel` _SYSTEM_   Cancel `-wait` processes on the server that are waiting for specified SYSTEM and key
- `-w` _TIME_          Number of seconds to wait between each attempt to acquire the lock (default 8)
- `-t` _RETRIES_       Number of retries to perform for acquiring the
 lock (default -1, which means infinity)
- `-f`               Forcefully releases a lock even if you are not the owner
- `-k` _LOCK\_KEY_      Set a key inside the lock
- `-T` _timeout_       Allow lock to be reclaimed after _timeout_ seconds
- `dumpall`            Prints all currently locked systems

`mq systems [help|simple]`

Print list of available systems.  With `simple` just give their names

Two other commands are more for use in scripts:
`mq system-tsv` and `mq pool-tsv` take no arguments, and write to stdout
all the systems, and all the pools (respectively).

