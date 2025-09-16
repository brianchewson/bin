#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
    err_echo "$0 is a tool to find the office that someone works out of 
-----------------------------------------------------------------------bch
USAGE: $0 -s <SURNAME>
    -s     # put in the user's last name
"
    err_echo $*
    exit 1
}

err_echo()
{
    echo "$@" 1>&2
}

get_the_response()
{
    curl -o ${RESULT} -s "${INFO_URL}${SURNAME//\ /%7C}"
}

print_table()
{
    jq -r ".responseData[] | \"Employee: \(.employeeName)\", \"Office: \(.officeName)\", \"${DISPLAY_URL}/\(.employeeID)\"" ${RESULT}
}

reformat_the_result()
{
    cp ${RESULT}  ${TABLE}
    # delete anything html that isn't the table
    sed -i '/table/!d' ${TABLE}
    # reformat the table so each user is on one line
    sed -i 's/<tr/\n<tr/g' ${TABLE}
    # remove the css, table definition, and unneeded header line
    sed -i '1,3d' ${TABLE}
    # replace all tags with pipes
    sed -i 's/<[^>]*>/|/g' ${TABLE}
    # replace multi-pipes with uni-pipes
    sed -i 's/|\+/|/g' ${TABLE}
    
    dos2unix ${TABLE} 2> /dev/null
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
            -s|-S)
                if [ -z "$2" ]; then
                    usage "Improper number of arguments supplied for SURNAME flag (-s)"
                fi
                SURNAME=$2
                SURNAME=${SURNAME//á/a}
                shift
            ;;
        esac
        shift
    done
    if [ -z "$SURNAME" ]; then
        usage "NO SURNAME specified"
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

INFO_URL="https://corpdir.industrysoftware.automation.siemens.com/plmcorpdirii/api/employees?emp=true&aff=false&searchFields=firstname|lastname|nickname|edsnetid&term="
#DISPLAY_URL="https://corpdir.industrysoftware.automation.siemens.com/PLMCorpDirII/#/employeedetails"
DISPLAY_URL="https://go.industrysoftware.automation.siemens.com/corpdir/employeeDetails"
SURNAME=""
RESULT=/tmp/infotable.json
TABLE=${RESULT}.table

if [ $# -lt 1 ]; then
    usage "No arguments specified"
fi

process_arguments "$@"

get_the_response
#reformat_the_result
print_table
