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

# Fetches & converts all the various data files for a single url.txt file (passed on the command line)
# fails fast if any of the downloads / conversions fail.

#######

# set -x

set -e

if [ -z ${1:+x} ]
then
  echo "must specify a url.txt file on the command line"
  exit -1
fi

url_file=$1
dir=$(dirname $url_file)

# NOTE: use tmp files for all curl & gzip command output
# so if the downloads dies in the middle we don't have a partial file
download_tmp_file=$dir/download.tmp.dat
gzip_tmp_file=$dir/gzip.tmp.dat

# summary file for every build
summary_file=$dir/jenkins.summary.xml
if [ ! -e $summary_file ]
then
  curl -f -sS `cat $url_file`/api/xml > $download_tmp_file
  mv $download_tmp_file $summary_file
  echo $summary_file
fi

# if there are no testReports, then no tests were run (git failure, or maybe an artifacts only build)
# in which case we can skip all other steps
if ! grep -L testReport $summary_file > /dev/null 2>&1; then
  no_tests_file=$dir/no_tests.txt
  if [ ! -e $summary_file ]
  then
    touch $no_tests_file
    echo $no_tests_file
  fi
  exit 0
fi

# if we're still here, then tests ran -- download & summarize the test report
tests_csv_file=$dir/jenkins.tests.csv
tests_xml_file=$dir/jenkins.tests.xml
if [ ! -e $tests_csv_file ]
then
  if [ ! -e $tests_xml_file ]
  then
    curl -f -sS `cat $url_file`/testReport/api/xml > $download_tmp_file
    mv $download_tmp_file $tests_xml_file
    echo $tests_xml_file
  fi
  python summarize-test-results.py < $tests_xml_file > $download_tmp_file
  mv $download_tmp_file $tests_csv_file
  echo $tests_csv_file
  rm -f $tests_xml_file

fi

# if there were any test fails, download the full build log
# (don't bother downloading for successful builds to save space)
if ! grep -L '<failCount>0</failCount>' $summary_file > /dev/null 2>&1; then
  log_file=$dir/jenkins.log.txt
  log_gz_file=$log_file.gz
  if [ ! -e $log_gz_file ]
  then
    if [ ! -e $log_file ]
    then
      curl -f -sS `cat $url_file`/consoleText > $download_tmp_file
      mv $download_tmp_file $log_file
      echo $log_file
    fi
    gzip -c $log_file > $gzip_tmp_file
    mv $gzip_tmp_file $log_gz_file
    rm -f $log_file
    echo $log_gz_file
  fi
fi


                                                 
