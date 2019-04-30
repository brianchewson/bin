ISSUE="$@"
WORKFLOW_LIST=""
WORKFLOW_LIST="${WORKFLOW_LIST} Initial_Design"
WORKFLOW_LIST="${WORKFLOW_LIST} Pre-implementation_Review"
WORKFLOW_LIST="${WORKFLOW_LIST} Implementation"
WORKFLOW_LIST="${WORKFLOW_LIST} Pull_Request"
WORKFLOW_LIST="${WORKFLOW_LIST} Integration_Testing"
WORKFLOW_LIST="${WORKFLOW_LIST} Rollout"

for BIT in ${WORKFLOW_LIST}; do
    echo "${ISSUE} - ${BIT//_/ }"
done

