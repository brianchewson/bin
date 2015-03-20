#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  echo "$0 is a tool to convert an xml config file into a newline separated list of module.suites
-----------------------------------------------------------------------bch
USAGE: $0 -i FILENAME [-o FILENAME]
  -i     #Specifies the file to convert
  -o     #OPTIONAL: specify the output filename, default is to replace xml extension with .converted 
"
  echo $*
  exit 1
}


process_arguments()
{
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
      ;;
      -i|-I)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Input File flag (-i)"
        fi
        INFILE=$2
        shift
      ;;
      -o|-O)
        if [ -z "$2" ]; then 
          usage "Improper number of arguments supplied for Output File flag (-o)"
        fi
        OUTFILE=$2
        shift
      ;;
    esac
    shift
  done
  if [ -z "$INFILE" ]; then
    usage "No FILENAME specified"
  fi
  if [ ! -f "$INFILE" ]; then
    usage "File $INFILE doesn't exist"
  fi
  if [ -z "${OUTFILE}" ]; then
    OUTFILE=${INFILE%.xml}.converted
  fi
  if [ -f "${OUTFILE}" ]; then
    usage "file already exists at ${OUTFILE}, please (re)move before preceeding."
  fi
}
#==========================================END FUNCTIONS============================================

INFILE=""
OUTFILE=""
TEMP_FILE=""

if [ $# -lt 1 ]; then
  usage "No arguments specified"
fi

process_arguments "$@"

TEMP_FILE=${OUTFILE}.t

cp ${INFILE} ${OUTFILE}

sed -i 's/\.class/\n/g' ${OUTFILE}
sed -i 's/\//./g' ${OUTFILE}
sed -i 's/\\/./g' ${OUTFILE}
sed -i 's/,//g' ${OUTFILE}

grep Test ${OUTFILE}>${TEMP_FILE}
\mv ${TEMP_FILE} ${OUTFILE}

while read TEST_NAME; do
   echo ${TEST_NAME##*\"}>>${TEMP_FILE}
done<${OUTFILE}
\mv ${TEMP_FILE} ${OUTFILE}

sort ${OUTFILE} | uniq >> ${TEMP_FILE}
mv ${TEMP_FILE} ${OUTFILE}
