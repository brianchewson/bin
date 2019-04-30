#!/bin/sh -ex

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to pretend to be hubot by shitposting 
-----------------------------------------------------------------------bch
USAGE: $0 <-r ROOM_NAME|-n ROOM_NUMBER> -m \"MESSAGE\"
  -m     # This is the message that you want to send to the room as hubot (wrap in quotes)
  -n     # the room number (if you know it)
  -r     # The name of the room, if you don't know the number
"
  err_echo $*
  exit 1
}

err_echo()
{
  echo "$@" 1>&2
}

make_room_name_to_id_table()
{
  curl -s -o ${NAME_TO_NUMBER_TABLE} "${HIPCHAT_API}/room?${AUTH_TOKEN}"
  sed -i 's/, {"id"/,\n{"id"/g' ${NAME_TO_NUMBER_TABLE}
  sed -i 's/,/\n/g' ${NAME_TO_NUMBER_TABLE}
  sed -i '/\(id\|name\)/!d' ${NAME_TO_NUMBER_TABLE}
  tr -d '\n' < ${NAME_TO_NUMBER_TABLE} > ${NAME_TO_NUMBER_TABLE}.tmp
  mv ${NAME_TO_NUMBER_TABLE}.tmp ${NAME_TO_NUMBER_TABLE}
  sed -i 's/{"id"/\n{"id"/g' ${NAME_TO_NUMBER_TABLE}
  sed -i '/items/d' ${NAME_TO_NUMBER_TABLE}
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
      -m|-M)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for MESSAGE flag (-m)"
        fi
        MESSAGE=$2
        shift
      ;;
      -n|-N)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for ROOM_NUMBER flag (-n)"
        fi
        ROOM_NUMBER=$2
        shift
      ;;
      -r|-R)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for ROOM_NAME flag (-r)"
        fi
        ROOM_NAME=$2
        shift
      ;;
    esac
    shift
  done

  for INPUT in ROOM_NUMBER MESSAGE; do
    if [ -z "${!INPUT}" ]; then
      usage "NO ${INPUT} specified"
    fi
  done

  REQUIRED_FILES=""
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi

AUTH_TOKEN="auth_token=ahlQO0khPC4vb5Nrgzy0k1lAoptBuq7eFKpTcvbG"
HIPCHAT_API="https://api.hipchat.com/v2"
MESSAGE=""
NAME_TO_NUMBER_TABLE="${WORKSPACE}/name_to_id.list"
ROOM_NAME=""
ROOM_NUMBER="385450"

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

if [ ! -f "${NAME_TO_NUMBER_TABLE}" ]; then
  make_room_name_to_id_table
fi

# if you have a name, the user wants to use that name
if [ -n "${ROOM_NAME}" ]; then
  # verify the room exists
  if grep -c "${ROOM_NAME}" ${NAME_TO_NUMBER_TABLE} > /dev/null; then
    ROOM_NUMBER=$(grep "${ROOM_NAME}" ${NAME_TO_NUMBER_TABLE})
    ROOM_NUMBER=${ROOM_NUMBER#*"id": }
    ROOM_NUMBER=${ROOM_NUMBER% "name":*}
  fi
fi


echo "curl -X POST \"${HIPCHAT_API}/room/${ROOM_NUMBER}/notification?${AUTH_TOKEN}\" -H 'Content-type: application/json' -d \"{\"message\":\"${MESSAGE}\",\"color\":\"random\",\"notify\":\"true\"}\""
