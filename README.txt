
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


###
### TODO LIST:
###

# Small Stuff...

 - set longer timeouts for all curl commands: --max-time <seconds> --connect-timeout <seconds>
 
 - change the directory structure since most people don't care about the venus generated output
   - venus should use a new dir for it's output (ex: "feed-data" and "feed-data/index.html")
   - we should have a much smaller top level level "index.html"
     - move exist top matter content in the customized venus-theme/index.html.xslt
   - new index.html and our failure-report html/js should no longer live in venus-theme
     - probably have some sort of src-html with a trivial script to copy to output/html ?

 - fetch-data-files.sh should generate a small index.html for each dir...
   - link to the original job (from url.txt)
   - link to download the ziped log file
     - set the 'download' attr on the <a href/> tag to match the job name with '/' replaced by "_" ?
   - key bits from jenkins.summary.xml ... or use jquery to fetch & render?
   - link to the jenkins.tests.csv
     - link should mention the number of failures/runs in the file


# Suite level failure rate accuracy (HARD)

 - suite level failure rates are bogus ( see note at bottom of failure-report.html )
   - w/data available in the current data files, a suite failure rate of 100% in past 24 hours, might mean:
      - 7 jenkins jobs ran the suite once each and all 7 failed w/a single failure msg from each
      - 5 jenkins jobs ran the suite once each and one run logged 5 diff suite failure msgs
      - 1 jenkins job ran the suite 3 times: the first one had a single suite failure msg and then when
        that same jenkins job tried to run it 2 more times to repro the failure, it passed both other times.
 - i thought i could fix this by "improving" some scripts:
   - fetch-data-files.sh - ask forsuite level info, not just //case
   - summarize-test-results.py - record a line for every suite run, either PASS/FAIL
   - gen-failure-rates.pl - expect a line for every suite run, no hueristic
 - but the root problem is that the 'testReport' XML structure can't tell us how many times a suite was run
   - if the jenkins build re-runs a TestCase 5 times, there's still only one section for that suite
 - Is there a better way to get this info from jenkins?
   - Ick ... parse the logs?
 - GOAL:
   - the suite failure rate should work just like the method failure rate
   - we should definitively know how many times the suite ran, even if it ran more then once in a
     single jenkins job, and how many of those runs had *ONE OR MORE* failures
   - ie: should be impossible for suite failure rates to be > 100%

# failure-report.html

 - the suggested filename from the download button should include info about the selection
   - 7days/24hours prefix
   - name of any class/method/suite filtering applied

# new comparative report

 - in addition to 24hours/7days, there should be a way to compare the past 24 hours with the past 7 days
   - or the past 7days with the prior 7days from the archive dir (likewise 0-24, vs prior 24)
 - implementation ideas:
   - generate-test-summary-reports.sh
     - start archiving the failure-rates.json files (uncompressed)
     - after archiving the files, but up a JSON of all archive/*/*failure-rates.json files
   - new HTML tabulator screen
     - use ajax to fetch the json list of all archive file names,
     - use that JSON to populate two select pulldowns.
     - when a user slects 2 files, use ajax to fetch them and in javascript compute the deltas in memory
     - use tabulator to graph the in memory deltas data set & auto-sort by what has the highest delta "increase"

