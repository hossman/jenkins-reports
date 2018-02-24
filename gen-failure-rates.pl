#!/usr/bin/perl -l

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

use strict;
use warnings;
my $SUITES_ALREADY_SEEN_PER_FILE = {};
my $RESULTS = {};

sub add_run {
    my ($job, $class, $method, $run_inc, $fail_inc) = @_;
    if (exists $RESULTS->{"$class,$method"}) {
	$RESULTS->{"$class,$method"}->{"run"} += $run_inc;
	$RESULTS->{"$class,$method"}->{"fail"} += $fail_inc;
    } else {
	$RESULTS->{"$class,$method"} = { "failed_jobs" => [ ],
					 "run" => $run_inc, 
					 "fail" => $fail_inc };
    }
    if (0 < $fail_inc) {
	push @{$RESULTS->{"$class,$method"}->{"failed_jobs"}}, $job;
    }
}


while (<>) {
    my ($file,$line) = split /:/;
    
    die "Can't pull job from file: $file" unless ($file =~ m{^.*/job-data/(.*)/jenkins.tests.csv$});
    my $job = $1;
    
    my ($status, $class, $method) = (split(",", $line))[0,1,2];
    my $run_inc = ("SKIP" eq $status ? 0 : 1);
    my $fail_inc = ("FAIL" eq $status ? 1 : 0);

    # these method name 'markers' are 2 indications of a suite level failure in the XML files...
    if ('' ne $method && 'initializationError' ne $method) {
	# if this is *not* a suite failure, record an extra psuedo-run for the suite this method is in...
	# if and only if we haven't already done that for this file + suite combo
	if (! exists $SUITES_ALREADY_SEEN_PER_FILE->{$class}) {
	    $SUITES_ALREADY_SEEN_PER_FILE->{$class} = {};
	}
	if (! exists $SUITES_ALREADY_SEEN_PER_FILE->{$class}->{$file}) {
	    $SUITES_ALREADY_SEEN_PER_FILE->{$class}->{$file} = 1;
	    add_run($job, $class, '', 1, 0);
	}
    } else {
	# otherwise: this line indicates a suite level failure (either init or teardown)
	#
	# sanity check: suites should only be in the files if they were failures...
	die "WTF: $_" unless 1 == $fail_inc;
	# don't record the run, just the failure...
	# (we already done a special recording of the run the first time we saw the class name)
	$run_inc = 0;
    }
    add_run($job, $class, $method, $run_inc, $fail_inc);
}
# we're done with this, let it GC...
$SUITES_ALREADY_SEEN_PER_FILE = undef;

while (my ($key, $value) = each %{$RESULTS}) {
    # avoid divide by zero for tests that were skipped 100% of the time
    $value->{"fail_rate"} = (0 < $value->{"run"}
			     ? ($value->{"fail"} / $value->{"run"})
			     : 0);

    # consistency check...
    die "$key has inconsistent fail count" unless ($value->{"fail"} == scalar @{$value->{"failed_jobs"}});
} 
foreach my $key (sort { $RESULTS->{$b}->{"fail_rate"} <=> $RESULTS->{$a}->{"fail_rate"}
			# when the fail_rates are identical, secondary sort on the total number of failures
			|| $RESULTS->{$b}->{"fail"} <=> $RESULTS->{$a}->{"fail"} } keys %{$RESULTS}) {
    # don't bother reporting anything that never failed
    if (0 < $RESULTS->{$key}->{"fail_rate"}) {
	print join(",", 
		   $key, $RESULTS->{$key}->{"fail_rate"}, $RESULTS->{$key}->{"fail"}, $RESULTS->{$key}->{"run"},
		   # Add any new solumns here
		   '', # skip a 'marker' before job list starts to future proof against new columns
		   @{ $RESULTS->{$key}->{"failed_jobs"} });
	;
    }
}
