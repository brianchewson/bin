#!/bin/sh -ex

#============================================FUNCTIONS==============================================
usage()
{
  echo "$0 is a tool to copy a bundle of sims based on the failure message
-----------------------------------------------------------------------bch
USAGE: $0 -f FAILURE_MESSAGE -m MODULE -s STARTEST_DIR [-t]
  -f     # the message that you're looking for in the logs (use 'single quotes')
  -m     # module or module.Suite, 
           you can specify multiple -m values 
             and/or 
           you can specify multiple modules with module.Suite1~module.Suite2
  -s     # specify which startest instance you want to pull the results out of (eg '~/dev2')
  -t     # get the sim files into your workspace
"
  echo $*
  exit 1
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
      -f|-F)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for FAILURE_MESSAGE flag (-f)"
        fi
        FAILURE_MESSAGE=$2
        shift
      ;;
      -m|-M)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for MODULE flag (-m)"
        fi
        MODULES="${MODULES} ${2//\~/ }"
        shift
      ;;
      -s|-S)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for STARTEST_DIR flag (-s)"
        fi
        STARTEST_DIR=$2
        shift
      ;;
      -t|-T)
        TRANSMOGRIFY=TRUE
      ;;
    esac
    shift
  done
  for VERIFY in FAILURE_MESSAGE MODULES STARTEST_DIR; do
    if [ -z "${!VERIFY}" ]; then
      usage "NO ${VERIFY} specified"
    fi
  done
  if [ ! -d "${STARTEST_DIR}" ]; then
    usage "DIR ${STARTEST_DIR} doesn't exist"
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

FAILURE_MESSAGE=""
MODULES=""
STARTEST_DIR=""
TRANSMOGRIFY=FALSE
YEAR="$(date +%Y)"

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

for MODULE in ${MODULES}; do
  #get all of the logs that mention the failure
  LOGS=${WORKSPACE}/${MODULE}.logs
  SIMS=${WORKSPACE}/${MODULE}.sims
  SELECTED=${WORKSPACE}/${MODULE}.selected

  DELETE_LIST="LOGS SIMS SELECTED"

  grep -l "^${FAILURE_MESSAGE}" ${STARTEST_DIR}/startest/results/linux-x86_64-2.*/${YEAR}*/testrun_1*/testbag_*/user/startest.backward*ReportSaveTest/test_*_${MODULE/\./_}_*/*.log > ${LOGS}

  while read LOG; do
    grep 'Loading object database:' ${LOG} >> ${SIMS}
  done < ${LOGS}

  sed -i 's/Loading object database: //g' ${SIMS}

  while read SIM; do
    if [ -f ${SIM} ]; then
      echo ${SIM} >> ${SELECTED}
    fi
  done < ${SIMS}

  if [ "$TRANSMOGRIFY" = "TRUE" ]; then
    for ARCHIVE in release archives; do 
      for NP in "np" "-v np"; do 
        grep /${MODULE}/ ${SELECTED}  | grep ${ARCHIVE} | grep ${NP}| sort -R | head -n 2 | while read SELECTED_SIM; do 
          transmogrifier -f ${SELECTED_SIM}
        done
      done
    done
  fi

  echo "RESETTING FILE STORAGE"
  for FILE in ${DELETE_LIST}; do 
    rm -fv ${!FILE}
  done

  
done
