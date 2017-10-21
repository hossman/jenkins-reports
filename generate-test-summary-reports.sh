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

# Loops over all the recent '*.csv' files it can find (in job-data) and produces
# some summary reports

#######

echo "## Generating Summary Reports..."

mkdir -p output/html/reports

# TODO: a create a "recent-test-results.csv.gz"
#  ... should looks like recent-method-failures.csv -- but with the FAIL/PASS still included

### recent failures at method granularity - sorted, and including the directory for each
find output/html/job-data/ -mtime -7 -name \*.csv | xargs grep '^FAIL' | perl -nle 'my ($file,$line) = split /:/; $file =~ s{^.*/([^/]+/[^/]+/\d+/).*\.csv$}{$1}; $line = join(",", (split(",", $line))[1,2])  ; print "$line,$file"' | sort > output/html/reports/recent-method-failures.csv

### recent failures at a class level - summarized & sorted by by count
perl -nle '$class = (split(",",$_))[0]; print $class' < output/html/reports/recent-method-failures.csv | uniq -c | sort -rn | perl -ple 's{^\s*(\d+)\s+(\S+)}{$1,$2};' > output/html/reports/recent-top-failing-classes.csv

                                                 
