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

# Loops over all the 'url.txt' files it can find and execs fetch-data-files.sh on each
# (Ignores failures from fetch-data-files.sh so it can keep going)

#######



# TODO: change this find output to be limited by date (bash script param)...
# ...so as the # of builds grows, we aren't constantly rechecking old builds
#
# NOTE:  using sort -R here to try and reduce how much we request from one server back to back
find output/html/job-data/ -name url.txt | sort -R |
  while read url_file
  do
    echo "# $url_file"
    bash ./fetch-data-files.sh $url_file
  done

                                                 
