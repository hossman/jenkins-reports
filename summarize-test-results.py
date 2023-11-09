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

"""
Reads a jenkins (xml) test report from STDIN
Writes a CSV summary of the tests and their statuses to STDOUT

"""

import re, sys
from lxml import etree

# a dictionary of the different raw statuses we might get, and how we treat them
STATUS_MAP = {'FAILED' : 'FAIL',
              'REGRESSION' : 'FAIL',
              'FIXED' : 'PASS',
              'PASSED' : 'PASS',
              # our own special status for jenkins reporting problems (see below)
              'JENKINS_REPORTING_ERROR' : 'SKIP', 
              'SKIPPED': 'SKIP'}


# parse input stream
tree = etree.parse(sys.stdin)

for case in tree.xpath('//case'):
    class_name = case.xpath('./className')[0].text
    test_name = case.xpath('./name')[0].text
    raw_status = case.xpath('./status')[0].text
    
    # special case: suite related failures: record an entry with the test_name blank
    # Older style ant reporting...
    if (class_name == 'junit.framework.TestSuite'):
        class_name = test_name
        test_name = ''
    # Newer style gradle reporting...
    if (test_name == 'classMethod'):
        test_name = ''

    # special case: jenkins level reporting failures (ie: problem writing test results to disk ...
    # no space left on device, corrupt XML file, etc...) show up as class="TEST-*.xml" method="some error"
    # so if we see something like that, we treat it as a "SKIP" for the affected class
    # (leave the error in the method for downstream)
    xml_report_error = re.match('TEST-(.*).xml', class_name)
    if (xml_report_error):
        class_name = xml_report_error.group(1)
        raw_status = 'JENKINS_REPORTING_ERROR'

    # parmeterized tests have their inputs reported as part of the method name
    # strip these so the metrics include all runs of the test
    test_name = re.sub('\s+|\{.*\}', '', test_name)
        
    # summarize the various raw_statuses as a simple status
    status = STATUS_MAP[raw_status]
        
    print ','.join((status, class_name, test_name, raw_status))
