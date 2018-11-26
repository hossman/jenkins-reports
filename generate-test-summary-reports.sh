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

### first up, get a list of all the test result files in the last 24hrs & 7 days
### we want to ensure a consistent input list for every step after this
#
# we want these in reverse sorted order, so newer files are at the top
# that means that in later reports, recent jobs related to a failure will be listed first
#
# NOTE: if changing any of the -mmin rules, make sure run.sh is updated to not prune files we care about
find output/html/job-data/ -mmin -1440 -name \*.csv -printf "%T@\t%p\n" | sort -nr | perl -ple '$_=(split(/\s+/))[1];' > output/html/reports/24hours-test-results.txt
find output/html/job-data/ -mmin -10080 -name \*.csv -printf "%T@\t%p\n" | sort -nr | perl -ple '$_=(split(/\s+/))[1];'> output/html/reports/7days-test-results.txt

### recent failures at method granularity - sorted, and including the directory for each
# just past 24 hours
cat output/html/reports/24hours-test-results.txt | xargs grep '^FAIL' | perl -nle 'my ($file,$line) = split /:/; $file =~ s{^.*/([^/]+/[^/]+/\d+/).*\.csv$}{$1}; $line = join(",", (split(",", $line))[1,2])  ; print "$line,$file"' | sort > output/html/reports/24hours-method-failures.csv
# past 7 days
cat output/html/reports/7days-test-results.txt | xargs grep '^FAIL' | perl -nle 'my ($file,$line) = split /:/; $file =~ s{^.*/([^/]+/[^/]+/\d+/).*\.csv$}{$1}; $line = join(",", (split(",", $line))[1,2])  ; print "$line,$file"' | sort > output/html/reports/7days-method-failures.csv

### recent failures at a class level - summarized & sorted by by count
# past 7 days
perl -nle '$class = (split(",",$_))[0]; print $class' < output/html/reports/7days-method-failures.csv | uniq -c | sort -rn | perl -ple 's{^\s*(\d+)\s+(\S+)}{$1,$2};' > output/html/reports/7days-top-failing-classes.csv

### recent failure *rates* at both a method and class level (class level listed as method '')
# just past 24 hours
cat output/html/reports/24hours-test-results.txt | xargs grep '^' | perl gen-failure-rates.pl > output/html/reports/24hours-failure-rates.csv
perl gen-failure-rates-json.pl output/html/reports/24hours-failure-rates.csv > output/html/reports/24hours-failure-rates.json
# past 7 days 
cat output/html/reports/7days-test-results.txt | xargs grep '^' | perl gen-failure-rates.pl > output/html/reports/7days-failure-rates.csv
perl gen-failure-rates-json.pl output/html/reports/7days-failure-rates.csv > output/html/reports/7days-failure-rates.json

### archive our reports based on the current date, overwritin any existing files with same name
### as the cron runs multiple times a day, this will result in the "last" run from each day being preserved
mkdir -p output/html/reports/archive/daily
mkdir -p output/html/reports/archive/weekly

gzip -c output/html/reports/24hours-method-failures.csv > output/html/reports/archive/daily/`date -u +%F`.method-failures.csv.gz
gzip -c output/html/reports/7days-method-failures.csv > output/html/reports/archive/weekly/`date -u +%G-%V`.method-failures.csv.gz

gzip -c output/html/reports/24hours-failure-rates.csv > output/html/reports/archive/daily/`date -u +%F`.failure-rates.csv.gz
gzip -c output/html/reports/7days-failure-rates.csv > output/html/reports/archive/weekly/`date -u +%G-%V`.failure-rates.csv.gz
                                                 
### once we have our recent reports, and our archives, we can generate a comparitive
### report of (potentially) suspicious failure rates

# NOTE: if head/tail args are changed, make sure to update info on suspicious-failure-report.html
(cd output/html/reports/archive/weekly/ && ls -1t | grep failure-rates | head -4 | tail -3 | xargs zcat) | ./gen-suspicious-failure-rates-json.pl output/html/reports/7days-failure-rates.csv > output/html/reports/suspicious-failure-rates.json
