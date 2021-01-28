#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to write the shopping list that your wife sends you
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
          usage "Improper number of arguments supplied for OUTFILE flag (-o)"
        fi
        OUTFILE=$2
        shift
      ;;
    esac
    shift
  done
  if [ -z "$OUTFILE" ]; then
    usage "NO FILE specified"
  fi
  if [ -d "$OUTFILE" ]; then
    usage "FILE $OUTFILE exists, rename, move, or delete before proceeding again"
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

N=1
OUTFILE="/home/brianh/ShoppingList.html"
SOURCEFILE="/home/brianh/MasterList.html"

process_arguments "$@"

#header info
echo -e "<html>\n<body>\n<center>\n<table border=\"1\">\n" > ${OUTFILE}

# read the first item outside the loop
read -p "Item ${N}: " ITEM
#sanitize ITEM
ITEM="${ITEM//<*>/ }"

# add the item to the list, read the next item
while [ -n "$ITEM" ]; do
    if grep -q "${ITEM}" ${SOURCEFILE}; then
        grep "${ITEM}" ${SOURCEFILE}
        grep "${ITEM}" ${SOURCEFILE} >> ${OUTFILE}
    else
        echo "I don't have a record for ${ITEM}"
        echo "<tr><td>${ITEM}</td><td>&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td></tr>" >> ${OUTFILE}
    fi
  let N+=1
  read -p "Item ${N}: " ITEM
  #sanitize ITEM
  ITEM="${ITEM//<*>/ }"
done

#footer info
echo -e "</table>\n</center>\n</body>\n</html>" >> ${OUTFILE}
