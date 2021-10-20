#!/bin/bash 

AUTO_INST=autoinst.xml
DATE=$(date +%Y-%m-%d-%H%M%s)
INFILE=$1
ISO=${INFILE%.xml}.iso

if [ ! -f "${INFILE}" ]; then
    echo "You didn't specify a file to turn into an iso"
    exit
fi

cp ${INFILE} ${AUTO_INST}

mkisofs -V OEMDRV -o ${ISO} ${AUTO_INST}

rm -f ${AUTO_INST}

scp ${ISO} root@images:/srv/images/SUSE/${ISO}

if [ -d backups ]; then
  mv ${ISO} backups/${DATE}-${ISO}
else
    echo "Deleting ISO"
    rm -f ${ISO}
fi
