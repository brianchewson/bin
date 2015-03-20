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

print_out_summary()
{
  echo -n "${MODULE}.${SUITE}
----------------------------------------------
DEV:
  SERIAL BKWD (NP SIMS): "
  for CYCLE in 0 1 2 3 4; do
    PLUS_FIVE=CYCLE
    let PLUS_FIVE+=5
    if [ $(grep -v '\.[01][02468]\.' ${SIMLIST} | grep np | grep -c "_0[0-9][${CYCLE}${PLUS_FIVE}].sim" ) -ge 1 ]; then
      echo -n "${CYCLE} "
    fi
  done

  echo -n "
  PARALLEL BACKWARD    : "
  for CYCLE in 0 1 2 3 4; do
    PLUS_FIVE=CYCLE
    let PLUS_FIVE+=5
    if [ $(grep -v '\.[01][02468]\.' ${SIMLIST} | grep -v np | grep -c "_0[0-9][${CYCLE}${PLUS_FIVE}].sim" ) -ge 1 ]; then
      echo -n "${CYCLE} "
    fi
  done

  echo -n "
REL:
  SERIAL BKWD (NP SIMS): "
  if [ $(grep '\.[01][02468]\.' ${SIMLIST} | grep -c np ) -ge 1 ]; then
    echo -n "PRESENT"
  else
    echo -n "NONE"
  fi

  echo -n "
  PARALLEL BACKWARD    : "
  if [ $(grep '\.[01][02468]\.' ${SIMLIST} | grep -v np | wc -l ) -ge 1 ]; then
    echo -n "PRESENT"
  else
    echo -n "NONE"
  fi

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
