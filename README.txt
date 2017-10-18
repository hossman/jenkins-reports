

You must have a copy of the "venus" Blog Planet software -- we use it for the heavy lifting.

Assuming you have venus installed in "~/code/venus" you can run this report ala...

    cd jenkins-reports; python ~/code/venus/planet.py venus.ini


A few things to note about configing the "sources"....

 * every source should have a "name" that's short & human readable 
 * every source *MUST* have an 'id' that's unique
   - Jenkins ATOM Feed GUIDs all look like "hudson.dev.java.net,2017,JOB_NAME,#BUILD"
   - which means if multiple jenkins instances all have a job named "Lucene-Solr-master-Windows"
     venus gets confused
   - so we use a custom filter to rewrite things using the 'id' assignedin the config.


TODO:
 - use the original link from each entry to fetch & write to disk...
   - /api/xml?pretty=true
   - /testReport/api/xml?pretty=true
   - /consoleText
 - parse & crunch the testReport data writting out a csv file per job
 - have a script that combines the CSV files from the most recent X builds
 - make things pretty?
   - update the venus templates to link to our cached data for each job
   - javascript UI tools to browse the stats?
