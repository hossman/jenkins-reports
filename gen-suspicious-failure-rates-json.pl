#!/usr/bin/perl

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

# expects:
#  - a file name with the "recent" failures on command line 
#  - a stream of entries cat'ed to STDIN from "older" files

use strict;
use warnings;
use Data::Dumper;

my %results = ();
my $recent_failure_file_name = shift 
    or die "Must have a single command line arg for the recent failure rates";
open(my $recent_failure_file, "<", $recent_failure_file_name) 
or die "Can't open $recent_failure_file_name: $!";

while (<$recent_failure_file>) {
    chomp;
    my ($class,$method,$rate,$fail,$runs,$gap,@failed_jobs) = split /,/;
    die "WTF: gap is really $gap" unless ('' eq $gap);

    next if ("" eq $method);    # ignore suites since the failure rates are missleading
    next unless (10 <= $runs);  # ignore methods where run data is too small to draw conclusions
    next unless (0.1 <= $rate); # ignore methods where failure rate is (relativly) low
	
    my %failed_job_counts = ();
    for (@failed_jobs) {
	if (exists $failed_job_counts{$_}) {
	    $failed_job_counts{$_} += 1;
	} else {
	    $failed_job_counts{$_} = 1;
	}
    }
    my $failed_jobs_json = join(", ", map { qq({ "path":"$_","count":$failed_job_counts{$_} }) } keys %failed_job_counts);
    $results{"$class,$method"} = { 'rate' => $rate,
				   'fail' => $fail,
				   'runs' => $runs,
				   'failed_jobs_json' => $failed_jobs_json,
				   'historic_fail' => 0,
				   'historic_runs' => 0,
    };
}
close $recent_failure_file;

while (<>) {
    chomp;
    my ($class,$method,$rate,$fail,$runs,$gap,@failed_jobs) = split /,/;

    next if ("" eq $method);    # ignore suites since the failure rates are missleading
    next unless exists $results{"$class,$method"};
    my $record = $results{"$class,$method"};
    $record->{'historic_fail'} += $fail;
    $record->{'historic_runs'} += $runs;
}

my $i = 0;
while (my ($key, $record) = each %results) {
    
    my ($class,$method) = split /,/, $key;
    
    my $fail = $record->{'fail'};
    my $runs = $record->{'runs'};
    
    my $historic_fail = $record->{'historic_fail'};
    my $historic_runs = $record->{'historic_runs'};
    
    # tabulator wants percentages
    my $rate = 100 * $record->{'rate'}; 
    my $historic_rate = 100 * (0 < $historic_runs ? ($historic_fail / $historic_runs) : 0);

    my $delta = $rate - $historic_rate;

    next unless 0 <= $delta; # skip tests where we are improving
    my $failed_jobs_json = $record->{'failed_jobs_json'};
    
    $i++;
    print((1 == $i) ? "[\n " : ",");
    print qq[ { "class":"$class", "method":"$method", "fail_rate":"$rate", "failures":"$fail", "runs":"$runs", "historic_fail_rate":"$historic_rate", "historic_failures":"$historic_fail", "historic_runs":"$historic_runs", "delta_fail_rate":"$delta", "failed_jobs": [ $failed_jobs_json ]}\n];
}

print "]\n";
