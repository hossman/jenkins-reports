
####
#### WHAT IS THIS?
####

This repo provides some tools for:
 * fetching the ATOM Feeds from multiple Jenkins instances building Lucene/Solr
 * fetching the logs & test results associated with those builds 
 * crunching the test results to generate some reports

You can view the (ongoing) results here:

  http://fucit.org/solr-jenkins-reports/
  http://fucit.org/solr-jenkins-reports/reports/


####
#### HOW TO RUN THESE TOOLS
####

To use these tools You must have a copy of the "venus" Blog Planet software -- we use it for the initial heavy lifting.

Assuming you have venus installed in "~/code/venus" you can fetch all data and run the reports via...

    cd jenkins-reports
    ./run.sh ~/code/venus/planet.py

A convinience wrapper script that appends all output to "output/cron.log.txt" is available...

    17 */3 * * * /home/hossman/jenkins-reports/cron.sh /home/hossman/venus/planet.py

####
#### WHAT YOU GET
####

Once the above commands have been run...

    output/html/index.html
     - the Venus generated "planet" of recent jenkins jobs across all sources
    output/html/reports
     - some CSV summary reports of test failures in the past 7 days
    output/html/job-data/
     - more details about any failure mentioned in the /reports...
     - CSV with detailed list of test (method) results (PASS and FAIL) ... if and only if tests were run
     - full build logs ... if and only if at least one test failure occured (to save space)
     - NOTE: the file modification times of all files in this dir (should) match when the job was run,
       (acording to the feed) even if we fetched those files much later
    output/cron.log.txt
     - infinitely appended output from each run of cron.sh 

####
#### NOTES ON MAINTAINING THIS
####

A few things to note about configuring the "sources" in venus.ini....

 * every source should have a "name" that's short & human readable 
 * every source *MUST* have an 'id' that's unique
   - Jenkins ATOM Feed GUIDs all look like "hudson.dev.java.net,2017,JOB_NAME,#BUILD"
   - which means if multiple jenkins instances all have a job named "Lucene-Solr-master-Windows"
     venus gets confused
   - so we use a custom filter to rewrite things using the URL...
   - ...and use the 'source id' assigned in the config to organize the data files we download for each build

You will notice warnings from venus about "Duplicate subscription" .. this is because the feed level
GUID used in all jenkins feeds is identical -- you can safely ignore this WARNING.



TODO LIST:

 - generate better reports
   - ideally we should compute ratios of fail/pass/skip
   - the ratios are important long term so that some "nightly" tests which might fail every day
     actually shows up "high" in our report, instead of "low" just because it's absolute fail count is small
 - make things pretty?
   - javascript UI tools to browse the stats?
 - see venus.ini for some notes about requests to Steve & uwe about customizing their feeds to only get lucene jobs
