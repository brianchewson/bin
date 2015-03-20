#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  echo "$0 is a tool to determine if a suite has sim files in rel/dev and which cycles
--------------------------------------------------------------------------
USAGE: $0 -m MODULE -a SUITE [-d|-r]
  -a     #SUITE name
  -d     #Look only in the dev archive (skip release)
  -m     #MODULE name
  -r     #Look only in the rel archive (skip development)
"
  echo $*
  exit 1
}

get_a_list_of_sim_files()
{
  for ARCHIVE in ${ARCHIVE_LIST}; do
#    if [ -d ${DATA_DIR}/${ARCHIVE}/${MODULE}/${SUITE} ]; then
      find ${DATA_DIR}/${ARCHIVE}/*/${MODULE}/${SUITE} -type f | grep sim$ >> $SIMLIST
#    fi 
  done
}

get_summary()
{
  BRANCH=$1
  NPS=$2

  if [ "${BRANCH}" = "DEV" ]; then
    MAJOR_GREP="grep -v _[01][02468]_ ${SIMLIST}"
  else
    MAJOR_GREP="grep _[01][02468]_ ${SIMLIST}"  
  fi

  if [ "${NPS}" = "SERIAL" ]; then
    NP_GREP="grep np" #remember here that serial startest finds parallel sims
  else
    NP_GREP="grep -v np"
  fi

  for CYCLE in 0 1 2 3 4; do
  PLUS_FIVE=CYCLE
  let PLUS_FIVE+=5
  if [ $(${MAJOR_GREP}|${NP_GREP}|grep -c "_0[0-9][${CYCLE}${PLUS_FIVE}].sim" ) -ge 1 ]; then
      echo -n "${CYCLE} "
    fi
  done
}

print_out_summary()
{
  echo -n "${MODULE}.${SUITE}
----------------------------------------------
DEV:
  SERIAL BKWD (NP SIMS): "
  get_summary DEV SERIAL
  echo -n "
  PARALLEL BACKWARD    : "
  get_summary DEV PARALLEL
  echo -n "
REL:
  SERIAL BKWD (NP SIMS): "
  get_summary REL SERIAL
  echo -n "
  PARALLEL BACKWARD    : "
  get_summary REL  PARALLEL
  echo ""
}

process_arguments()
{
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
      ;;
      -a|-A)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Suite flag (-a)"
        fi
        SUITE=$2
        shift
      ;;

      -d|-D)
        ARCHIVE_LIST=${ARCHIVE_LIST/release/}
        ARCHIVE_LIST=${ARCHIVE_LIST// /}
      ;;
      -m|-M)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Module flag (-m)"
        fi
        MODULE=$2
        shift
      ;;
      -r|-R)
        ARCHIVE_LIST=${ARCHIVE_LIST/development/}
        ARCHIVE_LIST=${ARCHIVE_LIST// /}
      ;;
    esac
    shift
  done
  for DATA in MODULE SUITE; do
    if [ -z "${!DATA}" ]; then
      usage "NO ${DATA} specified"
    fi
    if [ -z "${ARCHIVE_LIST}" ]; then
      usage "Not scanning any archives, abort"
    fi
  done
}
#==========================================END FUNCTIONS============================================

MODULE=""
SUITE=""

DATA_DIR=/home/testdata

ARCHIVE_LIST="development release"

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

SIMLIST=${MODULE}.${SUITE}.$(date +%s)

get_a_list_of_sim_files
print_out_summary

rm -f ${SIMLIST}

