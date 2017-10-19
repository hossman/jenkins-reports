#!/bin/bash

set -e
# NOTE: use tmp files for all curl commands
# so if the downloads dies in the middle we don't have a partial file

# TODO: change this find output to be limited by date (bash script param)...
# ...so as the # of builds grows, we aren't constantly rechecking old builds
find output/html/job-data/ -name url.txt |
  while read url_file
  do
    #echo $url_file
    dir=$(dirname $url_file)
    download_tmp_file=$dir/download.tmp.dat
    gzip_tmp_file=$dir/gzip.tmp.dat
    
    summary_file=$dir/jenkins.summary.xml
    if [ ! -e $summary_file ]
    then
      curl -sS `cat $url_file`/api/xml > $download_tmp_file
      mv $download_tmp_file $summary_file
      echo $summary_file
    fi
    
    log_file=$dir/jenkins.log.txt
    log_gz_file=$log_file.gz
    if [ ! -e $log_gz_file ]
    then
      if [ ! -e $log_file ]
      then
        curl -sS `cat $url_file`/consoleText > $download_tmp_file
        mv $download_tmp_file $log_file
        echo $log_file
      fi
      gzip -c $log_file > $gzip_tmp_file
      mv $gzip_tmp_file $log_gz_file
      rm $log_file
      echo $log_gz_file
    fi
    
    tests_file=$dir/jenkins.tests.xml
    if [ ! -e $tests_file ]
    then
      curl -sS `cat $url_file`/testReport/api/xml > $download_tmp_file
      # TODO: script to crunch the data into a more compact CSV, then gzip (and rm) the XML
      mv $download_tmp_file $tests_file
      echo $tests_file
    fi
  done

                                                 
