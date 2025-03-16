# Copyright 2021 Proofcraft Pty Ltd
#
# SPDX-License-Identifier: GPL-2.0-only
#
# bash completion for mq.sh
# source this file to use: . ./bash_mq_completion.sh

_mq_systems() {
  mq.sh system-tsv | cut -f 1 | tail -n +2
  mq.sh pool-tsv | cut -f 1
}

_mq_completion() {
  local cur="${COMP_WORDS[$COMP_CWORD]}"

  if [ "$COMP_CWORD" -eq "1" ]; then
    COMPREPLY=($(compgen -W "run sem systems system-tsv pool-tsv" -- "${cur}"))
  else
    local prev="${COMP_WORDS[$(( $COMP_CWORD - 1 ))]}"
    case "${COMP_WORDS[1]}" in
      sem)
        if [ "$COMP_CWORD" -eq "2" ]; then
          COMPREPLY=($(compgen -W "-signal -wait -info -mr-info -cancel dumpall" -- "${cur}"))
        elif [ "$COMP_CWORD" -eq "3" ]; then
          COMPREPLY=($(compgen -W "$(_mq_systems)" -- "${cur}"))
        elif [ "$COMP_CWORD" -eq "4" ]; then
          COMPREPLY=($(compgen -W "-k -f" -- "${cur}"))
        fi
      ;;
      run)
        local mq_run_flags="-r -n -a -c -e -d -k -l -s -f -w -t"
        if [ "$COMP_CWORD" -eq "2" ]; then
          COMPREPLY=($(compgen -W "${mq_run_flags}" -- "${cur}"))
        else
          case "$prev" in
            '-s')
              COMPREPLY=($(compgen -W "$(_mq_systems)" -- "${cur}"))
            ;;
            '-k'|'-c'|'-e'|'-d'|'-k'|'-l'|'-w'|'-t'|'-f')
              # will default to filename completion
              COMPREPLY=()
            ;;
            *)
              COMPREPLY=($(compgen -W "${mq_run_flags}" -- "${cur}"))
            ;;
          esac
        fi
      ;;
      *)
      ;;
    esac
  fi

}

complete -o default -F _mq_completion mq.sh
