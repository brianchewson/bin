#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
    err_echo "$0 is a tool to generate a list of all the possible words that could be used
-----------------------------------------------------------------------bch
USAGE: $0 -l [LETTERS]
    -l     # the list of letters to anagramize
"
    err_echo $*
    exit 1
}

err_echo()
{
    echo "$@" 1>&2
}

permute()
{
    tiles=$1
    tiles=${tiles,,}
    
    grep -iE "^[$tiles]{1,${#tiles}}$" $DICTIONARY | while read -r word; do
        possible=true
        temp_tiles=$tiles

        for (( i=o; i<${#word}; i++ )); do
            letter=${word:$i:1}
            if [[ "${temp_tiles}" == *"$letter"* ]]; then
                temp_tiles="${temp_tiles/"${letter}"/}"
            else
                possible=false
                break
            fi
        done
        
        if [ "$possible" = true ]; then
            echo "${#word} ${word^^}" >> ${OUTFILE}
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
            -l|-L)
                if [ -z "$2" ]; then
                    usage "Improper number of arguments supplied for LETTERS flag (-l)"
                fi
                LETTERS=$2
                shift
            ;;
        esac
        shift
    done
    if [ -z "$LETTERS" ]; then
        usage "NO LETTERS specified"
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

DICTIONARY=/usr/share/dict/linux.words
LETTERS=""
OUTFILE=/tmp/$(date +%y%m%d%H%M%S)
> ${OUTFILE}

if [ $# -lt 1 ]; then
    usage "No arguments specified"
fi

process_arguments "$@"

permute "${LETTERS}"

sort -rn ${OUTFILE} -o ${OUTFILE}

head ${OUTFILE} | cut -d ' ' -f 2
