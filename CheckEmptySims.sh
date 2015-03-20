#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  echo "$0 is a tool to say why the sims aren't in the current test loop
-----------------------------------------------------------------------bch
USAGE: $0 -j JOB_NAME -v VERSION
  -j     #One of the Jenkins jobs that tests backward compatibility
  -v     #The version for the backward testing that you'd like to find the cause of missing sims
"
  echo $*
  exit 1
}

get_all_of_the_suites_with_no_sims()
{
  PATH_TO_RESULT=${JENKINS_HOME}/jobs/${JOB}
  PATH_TO_RESULT=${PATH_TO_RESULT}/builds/${JOB_BLD_NUMBER}
  PATH_TO_RESULT=${PATH_TO_RESULT}/archive/startest/results
  PATH_TO_RESULT=${PATH_TO_RESULT}/linux*/testrun_*/testbag_*
  PATH_TO_RESULT=${PATH_TO_RESULT}/htmlresults/testbag.html
  grep -h "${SUITE_WITH_NO_SIMS}" ${PATH_TO_RESULT} > ${SUITE_LIST}
  tr '<>' '\n' < ${SUITE_LIST} > ${SUITE_LIST}.t
  grep -v html ${SUITE_LIST}.t > ${SUITE_LIST}
  grep '[a-Z0-9]\.[a-Z]' ${SUITE_LIST} > ${SUITE_LIST}.t
  sort -u ${SUITE_LIST}.t -o ${SUITE_LIST}
  rm -rf ${SUITE_LIST}.t
}

get_latest_job_number()
{
  JOB_BLD_NUMBER=$(${WORKSPACE}/get_job_number.sh -j ${JOB} -v ${VERSION})
}

search_the_archives_for_each_suite()
{
  while read SUITE; do
    MODULE=${SUITE%.*}
    SUITE=${SUITE#*.}
    SUITE=${SUITE%Test}
    isSimInCycle.sh -m ${MODULE} -a ${SUITE} || true
  done < ${SUITE_LIST}
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
      -j|-J)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for JOB NAME flag (-j)"
        fi
        JOB=$2
        shift
      ;;
      -v|-V)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Version flag (-v)"
        fi
        case $2 in
          [0-9].0[1-6].[01][0-9][0-9]|[0-9][0-9].0[1-6].[01][0-9][0-9])
            VERSION=$2
          ;;
          *)
            usage "Version number supplied is not of the correct format XX.YY.ZZZ"
          ;;
        esac
        shift
      ;;
    esac
    shift
  done
  for VARIABLE in JOB VERSION; do
    if [ -z "${!VARIABLE}" ]; then
      usage "NO ${VARIABLE} specified"
    fi
  done
  
  if [ ! -d "${JENKINS_HOME}/jobs/${JOB}" ]; then
    usage "No such Jenkins job: ${JOB}"
  fi

  REQUIRED_FILES="isSimInCycle.sh get_job_number.sh"
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi
if [ -z "${JENKINS_HOME}" ]; then
  HUDSON_MNT=/home/hudson/cfg/default
  STARCI_MNT=/homd/starci-jenkins/cfg/default
  if [ -d "${HUDSON_MNT}" ]; then
    JENKINS_HOME=${HUDSON_MNT}
  elif [ -d "${STARCI_MNT}" ]; then
    JENKINS_HOME=${STARCI_MNT}
  else
    usage "No Home for Hudson found"
  fi
fi

DATE="$(date +%s)"
SUITE_LIST=${WORKSPACE}/${DATE}.suites
VERSION=""
JOB=""
JOB_BLD_NUMBER=""
SUITE_WITH_NO_SIMS="</A></TD><TD>0</TD>"


if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

get_latest_job_number
get_all_of_the_suites_with_no_sims
search_the_archives_for_each_suite
