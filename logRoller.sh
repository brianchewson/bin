#!/bin/bash 

INFILE=$1
SIZE_NOW=$(stat -c%s $INFILE)
SIZE_THEN=0
WAIT=0
TIMEOUT=1

CLEAR_VAL=$(uname)
if [ $CLEAR_VAL = "Linux" ]; then
  CLEAR_VAL='tput reset'
else
  CLEAR_VAL='echo -e "\ec\e[3J"'
fi

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

get_new_log()
{
  local LOG_LOCATION=$INFILE
  local RESULTS_DIR=${LOG_LOCATION%/testrun*}
  local TIMESTAMP=${RESULTS_DIR##*/}
  
  local LASTTIME=$(\ls -1 ${RESULTS_DIR%/*}|tail -1)

  #when watching logs on a run of startest, the timestamp value will not be a number.
  #if that is the case, then make sure that the LASTTIME and TIMESTAMP values are not equal so the
  #log iterates
  case $TIMESTAMP in
    [a-Z]*)
      TIMESTAMP=ARCH-COMPILER 
    ;;
  esac
  if [ ! "$TIMESTAMP" = "$LASTTIME" ]; then
    INFILE=$(ls -1tr ${RESULTS_DIR%/*}/${LASTTIME}/testrun*/logs/*.log | tail -1)
    TIMEOUT=120
  fi
}

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
      TIMEOUT=120
    fi
  fi

  set_sizes
done
