#!/bin/sh -ex

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to make a password
-----------------------------------------------------------------------bch
USAGE: $0 [-b ${WORD}] [-f ${WORD}] [-s|-m|-e]
  -b     # OPTIONAL: use this word at the beginning (if not specified a random word will be used)
  -e     # OPTIONAL: put a number at the end of the generated password (DEFAULT)
  -f     # OPTIONAL: use this word at the end (if not specified a random word will be used)
  -m     # OPTIONAL: put a number in the middle of the password 
  -s     # OPTIONAL: put a number at the start of the password
"
  err_echo $*
  exit 1
}

err_echo()
{
  echo "$@" 1>&2
}

random_number()
{
  # take the MAXIMUM_VALUE as input
  MAX_VAL=${1}
  WIDTH=${#MAX_VAL}

  let RET_VAL=MAX_VAL+1
  while [ "${RET_VAL}" -gt "${MAX_VAL}" ]; do 
    # get some lines from urandom
    #                            delete all characters that aren't in 0-9
    #                                        only make as wide as the max value
    #                                                                 take the first line
    #                                                                            trim leading zeroes
    RET_VAL=$(head /dev/urandom | tr -dc 0-9 | fold -w ${WIDTH} | head -n 1 | sed 's/^0*//')
  done
  echo "$RET_VAL"
}

random_separator()
{
  SEPARATORS=',.-=*_+^@'
  
  MAX_VALUE=${#SEPARATORS}

  RAND_CHAR=$(random_number ${MAX_VALUE})

  echo "${SEPARATORS:${RAND_CHAR}:1}"
}

random_word()
{
  # use a local dictionary
  WORD_LIST=/usr/share/dict/linux.words

  # set the maximum value as the number of words in the dictionary
  MAX_VALUE=$(wc -l < ${WORD_LIST})

  RANDOM_LINE=$(random_number ${MAX_VALUE})

  # print the line # from the file, (q)uit, and (d)elete remaining lines to be printed  
  RET_VAL=$(sed "${RANDOM_LINE}q;d" ${WORD_LIST})

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
      -h|--help)
        usage
      ;;
      -b|-B)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Beginning Word flag (-b)"
        fi
        BEGINNING_WORD=$2
        shift
      ;;
      -e|-E)
        PART_ONE=BEGINNING_WORD
        PART_TWO=FINAL_WORD
        PART_THREE=RANDOM_NUMBER
      ;;
      -f|-F)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for Final Word flag (-f)"
        fi
        FINAL_WORD=$2
        shift
      ;;
      -m|-M)
        PART_ONE=BEGINNING_WORD
        PART_TWO=RANDOM_NUMBER
        PART_THREE=FINAL_WORD
      ;;
      -s|-S)
        PART_ONE=RANDOM_NUMBER
        PART_TWO=BEGINNING_WORD
        PART_THREE=FINAL_WORD
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
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi


# pick random values for the words in the password, in case the user doesn't specify any
BEGINNING_WORD=$(random_word)
FINAL_WORD=$(random_word)

# set the print order for the final password to the default
PART_ONE=BEGINNING_WORD
PART_TWO=FINAL_WORD
PART_THREE=RANDOM_NUMBER

#if [ $# -lt 1 ]; then
#  usage "No arguments specified"
#fi

process_arguments "$@"

RANDOM_NUMBER=$(random_number $RANDOM)
SEP_ONE=$(random_separator)
SEP_TWO=$(random_separator)

echo "${!PART_ONE}${SEP_ONE}${!PART_TWO}${SEP_TWO}${!PART_THREE}"
