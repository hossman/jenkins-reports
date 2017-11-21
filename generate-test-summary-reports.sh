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

# NOTE: if changing any of the -mmin rules, make sure run.sh is updated to not prune files we care about

#######

echo "## Generating Summary Reports..."

mkdir -p output/html/reports

# TODO: a create a "recent-test-results.csv.gz"
#  ... should looks like recent-method-failures.csv -- but with the FAIL/PASS still included

### recent failures at method granularity - sorted, and including the directory for each
# just past 24 hours
find output/html/job-data/ -mmin -1440 -name \*.csv | xargs grep '^FAIL' | perl -nle 'my ($file,$line) = split /:/; $file =~ s{^.*/([^/]+/[^/]+/\d+/).*\.csv$}{$1}; $line = join(",", (split(",", $line))[1,2])  ; print "$line,$file"' | sort > output/html/reports/24hours-method-failures.csv
# past 7 days
find output/html/job-data/ -mmin -10080 -name \*.csv | xargs grep '^FAIL' | perl -nle 'my ($file,$line) = split /:/; $file =~ s{^.*/([^/]+/[^/]+/\d+/).*\.csv$}{$1}; $line = join(",", (split(",", $line))[1,2])  ; print "$line,$file"' | sort > output/html/reports/7days-method-failures.csv

### recent failures at a class level - summarized & sorted by by count
# past 7 days
perl -nle '$class = (split(",",$_))[0]; print $class' < output/html/reports/7days-method-failures.csv | uniq -c | sort -rn | perl -ple 's{^\s*(\d+)\s+(\S+)}{$1,$2};' > output/html/reports/7days-top-failing-classes.csv

### archive our reports based on the current date, overwritin any existing files with same name
### as the cron runs multiple times a day, this will result in the "last" run from each day being preserved
mkdir -p output/html/reports/archive/daily
mkdir -p output/html/reports/archive/weekly
gzip -c output/html/reports/24hours-method-failures.csv > output/html/reports/archive/daily/`date -u +%F`.method-failures.csv.gz
gzip -c output/html/reports/7days-method-failures.csv > output/html/reports/archive/weekly/`date -u +%G-%V`.method-failures.csv.gz
                                                 
