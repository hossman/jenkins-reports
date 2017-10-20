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

import sys, libxml2

# a dictionary of the different raw statuses we might get, and how we treat them
STATUS_MAP = {'FAILED' : 'FAIL',
              'REGRESSION' : 'FAIL',
              'FIXED' : 'PASS',
              'PASSED' : 'PASS',
              'SKIPPED': 'SKIP'}


# parse input stream
doc = libxml2.parseDoc(sys.stdin.read())
ctxt = doc.xpathNewContext()

for case in ctxt.xpathEval('//case'):
    ctxt.setContextNode(case);
    class_name = ctxt.xpathEval('./className')[0].getContent()
    test_name = ctxt.xpathEval('./name')[0].getContent()
    raw_status = ctxt.xpathEval('./status')[0].getContent()
    
    # special case: suite related failures get an entry with the test_name blank
    if (class_name == 'junit.framework.TestSuite'):
        class_name = test_name
        test_name = ''

    # summarize the various raw_statuses as a simple status
    status = STATUS_MAP[raw_status]
        
    print ','.join((status, class_name, test_name, raw_status))