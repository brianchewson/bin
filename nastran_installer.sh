#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to install Nastran on a nightly basis
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

check_linux_installation()
{   
    IN_DEST=$1
    IN_VERS=$2
    IN_PATCH=$3
    NEXT_PATCH=1
    let NEXT_PATCH=IN_PATCH+1

    if [ "${IN_PATCH}" == "0" ]; then
        DESTINATION_DIR=${IN_DEST}/${IN_VERS}
    else
        DESTINATION_DIR=${IN_DEST}/${IN_VERS}.${IN_PATCH}
    fi
    NEXT_DEST=${IN_DEST}/${IN_VERS}.${NEXT_PATCH}

    if [ -d ${SC_LIN_DEST}/${LIN_VERSION} ]; then
        echo "LINUX VERSION ${LIN_VERSION} HAS ALREADY BEEN INSTALLED"
        
    fi
}

check_transfer_from_plm_complete()
{
  if [ ! -f ${SC_NASTRAN_SOURCE}/COMPLETE.txt ]; then
    err_echo "TRANSFER IS NOT COMPLETE"
  fi
}

get_version()
{
    INFILE=$1
    if [ -s ${INFILE} ]; then
        RET_VAL=$(sed 's/\r//g' ${INFILE})
    else
        err_echo "No VERSION info in ${INFILE}"
    fi
    echo ${RET_VAL}
}

modify_conf_files_with_lic_srv()
{
  # Only add license server if they are not found in the file already
  for CONF_FILE in ${SC_NASTRAN_SOURCE}/*/conf/*; do
      LICENSES=$(grep -c '28000@flexlm' ${CONF_FILE})
      if [ "${LICENSES}" == "0" ]; then
          #add license servers as the 1st line
          sed -i -e '1iauth=28000@flexlm01,28000@flexlm02,28000@flexlm03\' ${CONF_FILE}
      else
          echo "${CONF_FILE} already has licenses listed"
      fi
  done
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

#NB: restrict to machine by IP, listed in NAS03:/etc/exports
LIN_VERSION_FILE=${SC_NASTRAN_SOURCE}/linux/nxn_em64t_id.txt
SC_LIN_DEST="/install/SCNastran/lin64"
SC_NASTRAN_SOURCE="/home/tmp/SC_installer"
SC_WIN_DEST="install:/cygdrive/e/Shares/SCNastran/win64"
WIN_VERSION_FILE=${SC_NASTRAN_SOURCE}/win64/nxn_win64_id.txt

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

check_transfer_from_plm_complete
modify_conf_files_with_lic_srv
LIN_VERSION=$(get_version ${LIN_VERSION_FILE})
# check for the version being already installed
check_linux_installation ${SC_LIN_DEST} ${LIN_VERSION} 0
if [ -d ${SC_LIN_DEST}/${LIN_VERSION} ]; then
    err_echo "LINUX VERSION ${LIN_VERSION} HAS ALREADY BEEN INSTALLED"
fi

IDEA for finding if the install is the same as the installer
find -type f -exec md5sum {} \; | sed 's/\*//g' | sed 's/  / /g' | sort | md5sum


WIN_VERSION=$(get_version ${WIN_VERSION_FILE})
