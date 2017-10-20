

You must have a copy of the "venus" Blog Planet software -- we use it for the initial heavy lifting.

Assuming you have venus installed in "~/code/venus" you can run this report ala...

    cd jenkins-reports
    python ~/code/venus/planet.py venus.ini
    bash fetch-all-data-files.sh


A few things to note about configuringng the "sources" in venus.ini....

 * every source should have a "name" that's short & human readable 
 * every source *MUST* have an 'id' that's unique
   - Jenkins ATOM Feed GUIDs all look like "hudson.dev.java.net,2017,JOB_NAME,#BUILD"
   - which means if multiple jenkins instances all have a job named "Lucene-Solr-master-Windows"
     venus gets confused
   - so we use a custom filter to rewrite things using the 'id' assignedin the config.


TODO:

 - have a script that combines the CSV files from the most recent X builds
 - fetch-data-files.sh needs to play nice with builds that don't run tests
   - Example: if a build failed because of git errors before any tests run,
              then: the /testReport/api/xml URL returns 404
 - fetch-all-data-files.sh's find command should be configurable, only look for files modified since X
 - wrapper script ready to go for cron job?
   - take in the venus path as a command line
   - cd to the dirname of the script
   - run everything under set -e
   - redirect all script output to some log file
 - make things pretty?
   - update the venus templates to link to our cached job-data for each entry
   - javascript UI tools to browse the stats?
