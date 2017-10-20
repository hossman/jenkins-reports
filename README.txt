
####
#### WHAT IS THIS?
####

This repo provides some tools for:
 * fetching the ATOM Feeds from multiple Jenkins instances building Lucene/Solr
 * fetching the logs & test results associated with those builds 
 * crunching the test results to generate some reports

####
#### HOW TO RUN THESE TOOLS
####

To use these tools You must have a copy of the "venus" Blog Planet software -- we use it for the initial heavy lifting.

Assuming you have venus installed in "~/code/venus" you can fetch all data and run the reports via...

    cd jenkins-reports
    python ~/code/venus/planet.py venus.ini
    bash fetch-all-data-files.sh
    bash generate-test-summary-reports.sh

TODO: adding a convinient wrappe script that can be put directly in a crontab

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

TODO: customize the venus template to add some pretty links to the reports & raw job-data

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

 - jenkins-path-id.py: set the mtime of the url.txt files to match the feed entry date?
   - then in our bash scripts, set the mtime of all the files we create to match the mtime of url.txt?
     - ala: touch -d "$(date -R -r url.txt)" new_file.xxx
   - that way all of our other find commands can be accurate relative when the job ran,
     even if there were issues with the downloads of the data files
   - and regardless of the order that fetch-all-data-files does things, it can set the mtime on the
     directories to match url.txt, so they sort properly
 - generate better reports
   - ideally this would compute ratios of fail/pass/skip
   - the ratios are important long term so that "nightly" tests which fail every day don't show up as
     "low" failure count compared to other tests
 - archive/delete older files
   - for builds older then X days, zip up (or just remove?) the CSV files
   - for builders older then X days, do we care about the logs either?
   - we could probably just delete any file older then the 7 days we use for generating the reports?
 - wrapper script ready to go for cron job?
   - take in the venus path as a command line
   - cd to the dirname of the script
   - run everything under set -e
   - redirect all script output to some log file
 - make things pretty?
   - update the venus templates to link to our cached job-data for each entry
   - javascript UI tools to browse the stats?
 - see venus.ini for some notes about requests to Steve & uwe about customizing their feeds to only get lucene jobs
