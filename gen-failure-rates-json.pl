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

use strict;
use warnings;

print "[";
while (<>) {
    chomp;
    print(($. == 1) ? "\n  " : ", ");
    my ($class,$method,$rate,$fail,$runs,$gap,@failed_jobs) = split /,/;
    die "WTF: gap is really $gap" unless ('' eq $gap);
    my %failed_job_counts = ();
    for (@failed_jobs) {
	if (exists $failed_job_counts{$_}) {
	    $failed_job_counts{$_} += 1;
	} else {
	    $failed_job_counts{$_} = 1;
	}
    }
    my $failed_jobs_json = join(", ", map { qq({ "path":"$_","count":$failed_job_counts{$_} }) } keys %failed_job_counts);
    $rate *= 100; # tabulator wants a percentage
    my $suite = ("" eq $method) ? "true" : "false"; #virtual indicator of if this was a suite failure
    print qq[ { "suite":$suite, "class":"$class", "method":"$method", "fail_rate":"$rate", "failures":"$fail", "runs":"$runs", "failed_jobs": [ $failed_jobs_json ]}\n];
}
print "]\n";
