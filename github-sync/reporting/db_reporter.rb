# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'yaml'

class DbReporter

  # intended to be overridden
  # returns strings in xml format
  # Either:
  #   <db-reporting type='ExampleDbReporter'>DATA</db-reporting>\n"
  # Or:
  #   <db-reporting type='ExampleDbReporter'><field>DATA</field><field>DATA2</field></db-reporting>\n"
  def db_report(repo, db)
    raise "No db_report(repo, db) function defined by report subclass"
  end

  # intended to be overriden
  # returns string
  def name()
    raise "No name() function defined by report subclass"
  end
  
  # intended to be overriden
  # returns string
  def describe()
    raise "No describe() function defined by report subclass"
  end
  
  # intended to be overriden
  # returns array of text or array of array [name, {type}, {type-specific-data, ...} ]
  # Supported types are
  #  text, org/repo, url, member
  def db_columns()
    raise "No db_columns() function defined by report subclass"
  end

end
