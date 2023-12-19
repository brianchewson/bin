#!/bin/bash  -x
SELF=$(realpath ${0})
AC_BIN=${SELF%/*}
CLD_JIRA=${1}
AUTH_TOKEN="-s -n ${HOME}/.netrc"
TMPDIR=tmpdir
if [ ! -d ${TMPDIR} ]; then
    mkdir -p ${TMPDIR}
fi

curl -s -n ~/.netrc -X GET "https://siemens-sts.atlassian.net/rest/api/3/issue/${CLD_JIRA}" > ${TMPDIR}/${CLD_JIRA}.json
if [ "$(jq -r '.fields.attachment[].content' ${TMPDIR}/${CLD_JIRA}.json)" != '' ]; then
    ATCH_LIST=${TMPDIR}/${CLD_JIRA}.attachments
    ATCH_DIR=${TMPDIR}/${CLD_JIRA}
    mkdir -p ${ATCH_DIR}

    # get a list of the content link attachments, then fetch the resource links
    jq -r '.fields.attachment[].content' ${TMPDIR}/${CLD_JIRA}.json | while read CONTENT_LINK; do
        curl ${AUTH_TOKEN} -I -X GET "${CONTENT_LINK}" --header 'Accept: application/json' | grep location:
    done > ${ATCH_LIST}
    dos2unix ${ATCH_LIST} 2> /dev/null
    sed -i 's/^.*https:\/\//https:\/\//' ${ATCH_LIST}
    sort -u ${ATCH_LIST} -o ${ATCH_LIST}
    sort -t '=' -k 5 ${ATCH_LIST} -o ${ATCH_LIST}
   

    #jira allows attachments to have the same name! Need to work around tha
    DL_ORDER=1 
    #one by one fetch the attachments
    while read ATCH_FILE; do
        ATCH_NAME="${ATCH_FILE##*&name=}"
        ATCH_NAME="${ATCH_NAME//+/ }"
        #get the attachment
        curl ${AUTH_TOKEN} -k "${ATCH_FILE}" > "${ATCH_DIR}/${DL_ORDER}-${ATCH_NAME}"
        let DL_ORDER+=1
    done < ${ATCH_LIST}
fi
