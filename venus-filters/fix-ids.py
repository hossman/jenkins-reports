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

NOTE: Due to laziness, this depends on having 'ignore_in_feed = id' configured   (Since it's 
      neccessary for jenkins feeds to not collied anyway) as well as each feed having an 'id' configured

"""

import re, sys, urlparse, xml.dom.minidom

atomNS = 'http://www.w3.org/2005/Atom'
planetNS = 'http://planet.intertwingly.net/'

dom = xml.dom.minidom.parse(sys.stdin)
entry = dom.documentElement

# go get the source id
source = entry.getElementsByTagNameNS(planetNS, 'id')[0].firstChild.nodeValue

orig_id = entry.getElementsByTagNameNS(atomNS, 'id')[0].firstChild.nodeValue

id_parts = orig_id.split('/')[-2:] # job name + build #
id_parts.insert(0, source)

path_id_element = dom.createElementNS(planetNS, 'path-id')
# fucking hack: https://stackoverflow.com/questions/863774/how-to-generate-xml-documents-with-namespaces-in-python
path_id_element.setAttribute("xmlns", planetNS) 
entry.appendChild(path_id_element)
path_id_element.appendChild(dom.createTextNode('/'.join(id_parts)))

print entry.toxml('utf-8')
