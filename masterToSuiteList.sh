#!/bin/bash

usage()
{
   echo "usage: $0 FILE_NAME
   takes the specified file and converts the xml into a newline separated list of module.suite combinations
   "
}

if [ "$#" -lt "1" ]; then
   usage
   exit
fi

MASTER=$1

if [ ! -f "$MASTER" ]; then
   echo "$0: cannot access $1: No such file"
   usage
   exit 1
fi

CONVERTED=${MASTER}.converted
TEMP=${CONVERTED}.t

if [ -f $CONVERTED ]; then
   echo "file already exists at $CONVERTED, please (re)move before preceeding."
   exit 1
fi

cp $MASTER $CONVERTED

sed -i 's/\.class/\n/g' $CONVERTED
sed -i 's/\//./g' $CONVERTED
sed -i 's/\\/./g' $CONVERTED
sed -i 's/,//g' $CONVERTED

grep Test $CONVERTED>$TEMP
\mv $TEMP $CONVERTED

while read TEST_NAME
do
   echo ${TEST_NAME##*\"}>>$TEMP
done<$CONVERTED

\mv $TEMP $CONVERTED


sort $CONVERTED | uniq >> t.t
mv t.t $CONVERTED
