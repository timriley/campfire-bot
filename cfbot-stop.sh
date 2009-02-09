#!/bin/bash

# run as cfbot-stop.sh BOT_ENV_NAME
for i in $(ps ajx |  awk "/[b]ot ${1}/ {print \$2;}")
do
  echo "killing pid $i"
  kill -9 $i
done
