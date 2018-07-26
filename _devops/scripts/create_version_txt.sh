#!/bin/sh
GIT_COMMIT=$(git rev-parse HEAD | xargs echo -n)
echo "COMMIT:\t${GIT_COMMIT}" > build_version/version.txt
echo "BUILD:\t$(date)" >> build_version/version.txt