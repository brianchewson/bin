#!/bin/sh

GCV=$(git describe)
VERSION=${GCV%%-*}
STARHOME=""

if [ -d /home/install3/lin64/STAR-CCM+${VERSION} ]; then
  STARHOME=/home/install3/lin64/STAR-CCM+${VERSION}
elif [ -d /home/install2/lin64/STAR-CCM+${VERSION} ]; then
  STARHOME=/home/install2/lin64/STAR-CCM+${VERSION}
fi

if [ -n "${STARHOME}" ]; then
  make -j 6 STAR_HOME=${STARHOME}
  bin/startest -configure -g custom -starhome ${STARHOME}
  mkdir ~/AlphabeticalOrder/${GCV}
  for XML in bin/linux-x86_64-2.5-gnu4.8.xml bin/master-config.xml; do
    mv ${XML} ~/AlphabeticalOrder/${GCV}
  done
  cat ~/AlphabeticalOrder/${GCV}/linux-x86_64-2.5-gnu4.8.xml | tr '<' '\n' | grep module
else
  echo "No install found for ${VERSION}"
fi
