#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  echo "$0 is a tool to watch the logs in a directory, tailing the most recent
-----------------------------------------------------------------------bch
USAGE: $0 -i FILENAME
  -i     #The filename of the first log you'd like to tail.
"
  echo $*
  exit 1
}

get_new_log()
{
  
}

set_sizes()
{
  SIZE_THEN=$SIZE_NOW
  SIZE_NOW=$(stat -c%s $INFILE)
}

show_log()
{
  $CLEAR_VAL
  tail $INFILE
}

process_arguments()
{
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
      ;;
      -i|-I)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for FILENAME flag (-i)"
        fi
        INFILE=$2
        shift
      ;;
    esac
    shift
  done
  if [ -z "$INFILE" ]; then
    usage "No FILE specified"
  fi
  if [ ! -f "$INFILE" ]; then
    usage "File $INFILE doesn't exist"
  fi
}
#==========================================END FUNCTIONS============================================

INFILE=""

CLEAR_VAL=$(uname)
if [ $CLEAR_VAL = "Linux" ]; then
  CLEAR_VAL='tput reset'
else
  CLEAR_VAL='echo -e "\ec\e[3J"'
fi
SIZE_NOW=0
SIZE_THEN=0
TIMEOUT=1
WAIT=0

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"
INFILE=$(readlink -f ${INFILE})
set_sizes

while [ 1 ];
do
  if [ $WAIT -eq $TIMEOUT ]; then
    show_log
    echo "CHECKING FOR NEW LOG"
    sleep 1
    get_new_log
    WAIT=0
    TIMEOUT=10
  else
    if [ $SIZE_THEN -eq $SIZE_NOW ]; then
      show_log
      echo "NO CHANGE...WAITING ${WAIT}(s) FOR CHANGE..."
      sleep 1
      WAIT=$(($WAIT + 1))
    else
      show_log
      WAIT=0
    fi
  fi

  set_sizes
done

