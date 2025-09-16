#!/bin/bash
INT_FILE=$1
MATCH=$2

git log --pretty=format:"%H" master -- ${INT_FILE} | while read commit_hash; do
  echo "Commit: $commit_hash"
  git show "$commit_hash:${INT_FILE}" | grep "${MATCH}"
done

