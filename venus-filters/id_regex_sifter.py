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
Sift entries based on a regex against the Atom entry 'id'
"""

import sys, re, xml.dom.minidom

atomNS = 'http://www.w3.org/2005/Atom'
planetNS = 'http://planet.intertwingly.net/'

# parse options
options = dict(zip(sys.argv[1::2],sys.argv[2::2]))

# parse entry
dom = xml.dom.minidom.parse(sys.stdin)
entry = dom.documentElement

data = entry.getElementsByTagNameNS(atomNS, 'id')[0].firstChild.nodeValue

# process requirements
if options.has_key('--require'):
  for regexp in options['--require'].split('\n'):
     if regexp and not re.search(regexp,data): sys.exit(1)

# process exclusions
if options.has_key('--exclude'):
  for regexp in options['--exclude'].split('\n'):
     if regexp and re.search(regexp,data): sys.exit(1)


# if we get this far, the feed is to be included
print entry.toxml('utf-8')
