#!/bin/sh
set -e

printf "\n"
echo "============================================"
echo "Docker Build and Sanity Check Run"
echo "============================================"
docker build -t emu8190 .
echo "Expecting help output with client-ca-roots-path line:"
docker run -t emu8190 --help | grep "Connect your databases to multiple consumers with minimal configuration and no libraries needed"
echo "============================================"
echo "Docker Build and Sanity Check Passed"
echo "============================================"
printf "\n\n\n\n\n"
echo "Sanity check passed. Congratulations. Bye!"