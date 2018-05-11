#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to get a preventive notification in case of new linux release
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
#  if [ -z "$DO_O" ]; then
#    usage "NO DIR specified"
#  fi
#  if [ ! -d "$DO_O" ]; then
#    usage "DIR $DO_O doesn't exist"
#  fi

  REQUIRED_FILES=""
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi

CENTOS_URL="centos"
CENTOS_VERSION="CentOS 7-1804"
OPENSUSE_URL="opensuse"
OPENSUSE_VERSION="openSUSE 42.3"
REDHAT_URL="redhat"
REDHAT_VERSION="Red Hat Enterprise Linux 7.5"
SLES_URL="sle"
SLES_VERSION="SUSE Linux Enterprise 12 SP3"


process_arguments "$@"
for OS in CENTOS OPENSUSE REDHAT SLES; do
  URL=$(eval echo "\$${OS}_URL")
  VERSION=$(eval echo "\$${OS}_VERSION")
  
  CURRENT_VERSION=$(curl -s "https://distrowatch.com/table.php?distribution=${URL}" | tr '<' '\n' | grep -m 1 'Distribution Release:' 2> /dev/null)
  CURRENT_VERSION="${CURRENT_VERSION#*Release: }"
  if [ "${VERSION}" = "${CURRENT_VERSION}" ]; then
    CURRENT_VERSION="UP TO DATE - ${CURRENT_VERSION}"
  else
    CURRENT_VERSION="WARNING: ${CURRENT_VERSION} - EXPECTED: ${VERSION} "
  fi
  
  echo "${OS}: ${CURRENT_VERSION}"
 
done
