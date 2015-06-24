#!/bin/bash

JENKINS_URL="http://starci.lebanon.cd-adapco.com:9090"

SLAVE_LIST=$(curl -s "${JENKINS_URL}/computer/api/xml?tree=computer\[displayName\]" | tr '<' '\n' | grep '^displayName' | cut -d '>' -f 2| tr '\n' ' ')


for SLAVE in $SLAVE_LIST; do
 echo "$(hostname -s) -> $SLAVE"
 ssh test@$SLAVE 'hostname -s'
done

#for SLAVE in $SLAVE_LIST; do
#  for SLAVE_1 in $SLAVE_LIST; do
#    echo "$SLAVE <- $SLAVE_1"
#    ssh test@$SLAVE_1 "ssh test@$SLAVE 'hostname -s'"
#  done
#done
