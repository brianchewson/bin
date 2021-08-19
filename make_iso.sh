#!/bin/bash 

AUTO_INST=autoinst.xml
DATE=$(date +%Y-%m-%d-%H%M%s)
INFILE=$1
ISO=${INFILE%.xml}.iso

cp ${INFILE} ${AUTO_INST}

mkisofs -V OEMDRV -o ${ISO} ${AUTO_INST}

rm -f ${AUTO_INST}

scp ${ISO} root@images:/srv/images/SUSE/${ISO}

if [ -d backups ]; then
  mv ${ISO} backups/${DATE}-${ISO}
fi
