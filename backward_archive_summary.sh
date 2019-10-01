#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to collect all of the files of a backward compatibility archive and 
summarize the contents per file type and version, showing the user count or size
-----------------------------------------------------------------------bch
USAGE: $0 [-d|-r] [-c|-s]
  -c     # output a count of the files found
  -d     # summarize the development archives DEFAULT
  -r     # summarize the release archives
  -s     # output the size of the files found DEFAULT
"
  err_echo $*
  exit 1
}

err_echo()
{
  echo "$@" 1>&2
}

break_out_files_by_version()
{
    while read VERSION; do 
        grep ${VERSION} ${ALL_FILES_LIST} > ${WORKSPACE}/${VERSION}.files
    done < ${VERSION_LIST}
}

get_list_of_all_files()
{   
    echo "Finding all files, this will take some time"
    ssh -n root@nas04 "cd ${ARCHIVE_PATH}; find -mindepth 1 -maxdepth 1 -type d | grep -v broken-symlinks-we-want-keep | cut -d / -f 2  | sort -h | while read VERS; do find \${VERS} -type f -exec stat -c \"%s %n\" {} \;;done >> /tmp/${ARCHIVE_BRANCH}.${DATE}"
    echo "Transferring list"
    scp root@nas04:/tmp/${ARCHIVE_BRANCH}.${DATE} ${ALL_FILES_LIST}
}

get_list_of_file_types()
{
    rev ${ALL_FILES_LIST} > ${ALL_FILES_LIST}.rev
    cut -d '/' -f 1 ${ALL_FILES_LIST}.rev > gloft.tmp
    cut -d '.' -f 1 gloft.tmp > ${FILE_TYPES}.rev
    rev ${FILE_TYPES}.rev > ${FILE_TYPES}
    sort -u ${FILE_TYPES} -o ${FILE_TYPES}
}

get_list_of_versions()
{
    cut -d ' ' -f 2 ${ALL_FILES_LIST} > ${ALL_FILES_LIST}.names
    cut -d '/' -f 1 ${ALL_FILES_LIST}.names > ${VERSION_LIST}
    sort -uV ${VERSION_LIST} -o ${VERSION_LIST}
}

print_table()
{
    #output a top line
    echo "VERSION,$(tr '\n' ',' < ${FILE_TYPES})"
    #output all of the middle lines
    while read VERSION; do
        echo "${VERSION}$(summarize ${VERSION} ${OUTPUT_TYPE})"
    done < ${VERSION_LIST}
    #output a line for the all_list
    echo "TOTAL$(summarize all ${OUTPUT_TYPE})"
}

round()
{
    IN=$1
    OUT=${IN::-1}
    if [ "${OUT}" -lt 10 ]; then
        OUT="${IN:0:1}.${IN:1:1}"
    elif [ "${IN: -1}" -gt 4 ]; then
        let OUT+=1
    fi
    echo ${OUT}
}

summarize()
{
    IN_V=$1
    OUT_T=$2
    RET_VAL=""
    while read FT; do 
        FILE_COUNT=$(grep -c "${FT}$" ${WORKSPACE}/${IN_V}.files || true)
        
        if [ "${OUT_T}" = "COUNT" ]; then
            RET_VAL="${RET_VAL},${FILE_COUNT}"
        else
            if [ "${FILE_COUNT}" -eq 0 ]; then 
                RET_VAL="${RET_VAL},0B"
            else
                FILE_BYTES=$(grep "${FT}$" ${WORKSPACE}/${IN_V}.files | awk '{n+=$1} END {print n}')
                case ${#FILE_BYTES} in
                    [1-3])
                        FILE_SIZE="${FILE_BYTES}B"
                    ;;
                    [4-6])
                        FILE_SIZE="$(round ${FILE_BYTES::-2})K"
                    ;;
                    [7-9])
                        FILE_SIZE="$(round ${FILE_BYTES::-5})M"
                    ;;
                    1[0-2])
                        FILE_SIZE="$(round ${FILE_BYTES::-8})G"
                    ;;
                    *)
                        FILE_SIZE="$(round ${FILE_BYTES::-11})T"
                    ;;
                esac
                RET_VAL="${RET_VAL},${FILE_SIZE}"
            fi
        fi
    done < ${FILE_TYPES}
    echo "${RET_VAL}"
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
      -c|-C)
        OUTPUT_TYPE="COUNT"
      ;;
      -d|-D)
        ARCHIVE_BRANCH="development"
      ;;
      -h|--help)
        usage
      ;;
      -r|-R)
        ARCHIVE_BRANCH="release"
      ;;
      -s|-S)
        OUTPUT_TYPE="SIZE"
      ;;
    esac
    shift
  done

  REQUIRED_FILES=""
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
DATE=$(date +%s)
if [ -z "${WORKSPACE}" ]; then
    WORKSPACE=/tmp/${DATE}
fi
if [ ! -d "${WORKSPACE}" ]; then
    mkdir ${WORKSPACE}   
fi

ARCHIVE_BRANCH="development"
OUTPUT_TYPE="SIZE"

#if [ $# -lt 1 ]; then
#  usage "No arguments specified"
#fi

process_arguments "$@"

ARCHIVE_PATH="/srv/testdata/backward/${ARCHIVE_BRANCH}"
ALL_FILES_LIST=${WORKSPACE}/all.files
FILE_TYPES=${WORKSPACE}/file.types
VERSION_LIST=${WORKSPACE}/version.list

get_list_of_all_files
get_list_of_file_types
get_list_of_versions
break_out_files_by_version
print_table 
