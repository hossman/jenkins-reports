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
Add a 'path-id' to each entry based on the original 'link' and what we know about jenkins build URLs
and then create a directory with that path-id where we create a url.txt (if it doesn't already exist)

NOTE: Due to laziness, this depends on having 'ignore_in_feed = id' configured   (Since it's 
      neccessary for jenkins feed entires to not conflict anyway) as well as each feed having an 
      'id' configured

"""

import os, re, sys, urlparse, xml.dom.minidom

atomNS = 'http://www.w3.org/2005/Atom'
planetNS = 'http://planet.intertwingly.net/'

dom = xml.dom.minidom.parse(sys.stdin)
entry = dom.documentElement

# go get the feed id & entry id (aka: entry URL)
feed_id = entry.getElementsByTagNameNS(planetNS, 'id')[0].firstChild.nodeValue
entry_id = entry.getElementsByTagNameNS(atomNS, 'id')[0].firstChild.nodeValue

path_id_parts = entry_id.split('/')[-3:] # job name + build# + extra slash
path_id_parts.insert(0, feed_id) # prepend feed_id
path_id = '/'.join(path_id_parts)

# add it to the DOM
path_id_element = dom.createElementNS(planetNS, 'path-id')
# fucking hack: https://stackoverflow.com/questions/863774/how-to-generate-xml-documents-with-namespaces-in-python
path_id_element.setAttribute('xmlns', planetNS) 
path_id_element.appendChild(dom.createTextNode(path_id))
entry.appendChild(path_id_element)

# go create the directory & url.txt if they don't exist
url_file_name = '/'.join(('output', 'html', 'job-data', path_id, 'url.txt'));
if not os.path.exists(os.path.dirname(url_file_name)):
    os.makedirs(os.path.dirname(url_file_name))
if not os.path.exists(url_file_name):
    with open(url_file_name, "w") as f:
        f.write(entry_id)

# very last thing we do is write the updated DOM back to venus
print entry.toxml('utf-8')
