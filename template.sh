#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to
-----------------------------------------------------------------------bch
USAGE: $0 -o [OPTIONAL]
  -o     # this is what -o does
"
  err_echo $*
  exit 1
}

err_echo()
{
  echo "$@" 1>&2
}


verify_dependencies()
{	
  for REQUIRED_FILE in ${REQUIRED_FILES}; do
    if [ ! -f ${WORKSPACE}/${REQUIRED_FILE} ]; then
      usage "${0##*/} requires a missing file, ${REQUIRED_FILE}, to run,
Please add ${REQUIRED_FILE} to ${WORKSPACE} to continue"
    fi
  done
}

process_arguments()
{
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
      ;;
      -o|-O)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for OPTIONAL flag (-o)"
        fi
        DO_O=$2
        shift
      ;;
    esac
    shift
  done
  if [ -z "$DO_O" ]; then
    usage "NO DIR specified"
  fi
  if [ ! -d "$DO_O" ]; then
    usage "DIR $DO_O doesn't exist"
  fi

  REQUIRED_FILES=""
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi


DO_O=""

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"
