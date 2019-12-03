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


# Usage: 
#
# cd output/html/reports/ && ../../../gen-failure-graph-data.pl < 7days-failure-rates.csv > failure-rate-history.csv
#
#     ...OR (for a longer period of "recent failures") ...
#
# cd output/html/reports/ && find archive/weekly -name \*failure-rates\* | sort | tail -4 | xargs zcat | ../../../gen-failure-graph-data.pl > failure-rate-history.csv
#
#
#
# NOTE: CWD is important!
# (This script execs `find`)


# TODO: switch to daily stats?  make it togglable with command line arg?


use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use DateTime;
#use Data::Dumper;

# ISO standard weeks are weird...
# https://en.wikipedia.org/wiki/ISO_week_date
# https://stackoverflow.com/a/9423267/689372
sub first_day_of_week {
  my ($year, $week) = @_;
  
  # Week 1 is defined as the one containing January 4:
  return (DateTime
	  ->new( year => $year, month => 1, day => 4 )
	  ->add( weeks => ($week - 1) )
	  ->truncate( to => 'week' ) )->format_cldr("yyyy-MM-dd");
} # end first_day_of_week

# what we want to print out anytime we have a completed row for our graph data table...
sub format_data_row {
    my $columns = shift;
    my $row_data = shift;
    my @row = ($row_data->{'_date'});
    for my $key (@{$columns}) {
	# if we don't have data, it means test had 0 failures rate that week
	push @row, (exists $row_data->{$key} ? $row_data->{$key} : '0');
    }
    return join(',', @row);
}

my @columns; # every 'class.method' that will be a series in our final graph data

my ($pattern_fh, $pattern_file_name) = tempfile(DIR => tempdir( CLEANUP => 1 ));
{
    # build up the set of 'class,method,' patterns for our future zgrep command
    # do this in a way that's easy to dedup, so that we can accept input from multiple weeks
    # (when the same test might have recorded failure rates multiple times)
    my %pattern_set;
    while (<>) {
	my ($class,$method,@extra) = split /,/;
	# ignoring suite level failures for now...
	next if '' eq $method;
	$pattern_set{"$class,$method"} = 1; # no trailing comma yet..
    }
    # now we have a set of every failure we care about, sort it (for some consistency in runs)
    # and dump it to our zgrep pattern file as well as reformatting each for @columns
    for my $pattern (sort keys %pattern_set) {
	print $pattern_fh "$pattern,"; # ...now ensure we have trailing comma so we don't match by prefix
	push @columns, ($pattern =~ s/,/./r);
    }
}
close $pattern_fh;

# zgrep for the class.method pairs we're looking for across all the archive data files.
# note we sort the (week based) filenames before zgreping them, so that the data comes in date order...
open(my $raw, '-|', "find archive/weekly/ -name \*failure-rates.csv.gz | sort | xargs zgrep --with-filename --fixed-strings --file=$pattern_file_name") or die $!;

my %row_data;

# loop over all the archived data that matches the columns we want to output
while (<$raw>) {
    my ($file,$line) = split /:/;
    die "Can't pull YYYY-WW from file: $file" 
	unless ($file =~ m{^.*/weekly/(\d{4})-(\d{2}).failure-rates.csv.gz$});
    my ($year, $week) = ($1, $2);
    my $date = first_day_of_week($year, $week);

    if (! exists $row_data{'_date'}) {
	# this is literally the first row, just output column headings...
	print 'Date,' . join(',', @columns);
    } elsif ($row_data{'_date'} ne $date) {
	# we've reached a new date, we need to output whatever row_data we've accumulated as a new output row
	print format_data_row(\@columns, \%row_data);
	%row_data = ();
    }
    
    # either way, %row_data is about our date (or if it wasn't before, it is now)
    $row_data{'_date'} = $date;

    # populate %row_data with info from the current line
    my ($class, $method, $rate) = (split(",", $line))[0,1,2];
    my $key = "$class.$method";
    die "Got multiple rows for $key from the same date: $date ($rate vs $row_data{$key})" 
	if exists $row_data{$key};
    $row_data{$key} = $rate;

}
close $raw;

# print our last output row...
print format_data_row(\@columns, \%row_data);
