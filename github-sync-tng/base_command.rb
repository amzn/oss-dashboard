# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Extend this and implement run(*params);boolean
class BaseCommand

  # Commands are created with a hash for desired arguments
  def initialize(arg_hash=nil)
    @args = arg_hash
  end

  # Override this method to implement your command execution
  # [boolean] Returning false indicates there was an issue
  def run(*params)
    raise "Cannot execute the BaseCommand, please extend"
  end

  # [String] defines the format it is saved in the filequeue
  def pickle_format
    return "#{self.class.name}(" + @args.map{|k,v| "#{k}='#{v}'"}.join(',') + ')'
  end

  # the queue assumes you can call match on the stored object so it can 
  # check whether its record separator is in the data
  def match(regexp)
    return regexp.match(pickle_format)
  end

  # the queue assumes you can call + on the stored object
  # it is adding the separator to the pickle format
  def +(separator)
    return pickle_format + separator
  end

  # Given a pickled command, create a new object ready for execution
  def self.instantiate(cmdstring)
    # ExampleCommand( org='amznlabs',test='3' )
    openIdx=cmdstring.index('(')
    clazzname=cmdstring[0..openIdx-1]
    clazz = Object.const_get(clazzname)

    argtext=cmdstring[openIdx+1..-2]
    args=Hash.new
    # TODO: ASSUMES THERE ARE NO COMMAS IN THE ARGS; ie) CHEAP PARSER OF THE HASH
    argtext.split(',').each do |pair|
      key,value=pair.split('=')
      args[key]=value[1..-2]   # strip off the quotes from the value
    end

    cmd=clazz.new(args)
    return cmd
  end

end
