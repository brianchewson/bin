#!/bin/bash 

AUTO_INST=autoinst.xml
DATE=$(date +%Y-%m-%d-%H%M%s)
INFILE=$1
ISO=${INFILE%.xml}.iso

cp ${INFILE} ${AUTO_INST}

mkisofs -V OEMDRV -o ${ISO} ${AUTO_INST}

rm -f ${AUTO_INST}

scp ${ISO} root@images:/srv/images/SUSE/${ISO}

if [ -d autoinst-bak]; then
  mv ${ISO} autoinst-bak/${DATE}-${ISO}
fi
