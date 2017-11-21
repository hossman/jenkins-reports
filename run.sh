#!/bin/bash


# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#######

# Simple script that runs all the tasks in order -- failing fast if any task fails
#
# NOTE: you must pass the ABSOLUTE path to venus/planet.py to this as the command line arg (i'm lazy)

#######

set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ "$#" != "1" ]; then
  echo "THIS SCRIPT REQUIRES EXACTLY ONE COMMAND LINE ARG: THE ABSOLUTE PATH TO planet.py"
  exit -1
fi
planet_py=$1

if [ ! -e $planet_py ]; then
  echo "CAN'T FIND $planet_py (relative to $( pwd ) )"
  exit -1
fi

python $planet_py venus.ini
./fetch-all-data-files.sh
./generate-test-summary-reports.sh

echo "## Cleaning up old job-data"

# NOTE: if changing this, make it's more then generate-test-summary-reports
# (too lazy to be bothered worrying about the "exactly 7")
find output/html/job-data/* -mtime +7 -exec rm -d {} \;
