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

# Loops over all the "recent' url.txt files it can find and execs fetch-data-files.sh on each
# (Ignores failures from fetch-data-files.sh so it can keep going)
#
# In this script 'recent' is defined as 4 days -- if we have a job older then that
# and still couldn't get some of it's data files, it's probably long gone

#######

echo "## Starting Run to Fetch All Data (of recent jobs)"

# NOTE:  using sort -R here to try and reduce how much we request from one server back to back
find output/html/job-data/ -mtime -4 -name url.txt | sort -R |
  while read url_file
  do
    if ./fetch-data-files.sh $url_file;
    then
      # everything worked, set the mtime on all files in the dir to match the url.txt
      touch -d "$(date -R -r $url_file)" $(dirname $url_file)/*
      touch -d "$(date -R -r $url_file)" $(dirname $url_file)
      
    else
      echo "# ... failures from: $url_file"
    fi
    
  done

                                                 
