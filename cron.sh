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

# script suitable for cron that runs each of the subtasks and redirects everything to a cron.log
#
# Example:  17 */3 * * * /home/hossman/jenkins-reports/cron.sh /home/hossman/venus/planet.py
#
# NOTE: you must pass the ABSOLUTE path to venus/planet.py to this as the command line arg (i'm lazy)

#######

cd "$( dirname "${BASH_SOURCE[0]}" )"

source /home/hossman/python-virtualenvs/p2.7_venus/bin/activate

if [ "$#" != "1" ]; then
  echo "THIS SCRIPT REQUIRES EXACTLY ONE COMMAND LINE ARG: THE ABSOLUTE PATH TO planet.py"
  exit -1
fi
planet_py=$1
mkdir -p output
echo "### STARTING RUN " `date` >> output/cron.log.txt

./run.sh $planet_py &>> output/cron.log.txt


echo "### ENDING RUN " `date` >> output/cron.log.txt

