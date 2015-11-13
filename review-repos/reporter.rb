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

class Reporter

  # exclude and pattern are regexps
  def filename_check(repo, dir, pattern, name, exclude=nil)
      txt=""
      sliceIdx=dir.length + 1
      Dir.glob("#{dir}/**/*").grep(pattern).each do |file|
        if(exclude and file.match(exclude))
          next
        end
  
        unless(File.directory?(file))
          txt << "      <reporting type='#{name}' file='#{file.to_s[sliceIdx..-1]}'></reporting>\n"
        end
      end
      return txt
  end
  
  
  def file_search(repo, dir, pattern, name)
      txt=""
      Dir.glob("#{dir}/**/*").each do |file|
        unless(File.directory?(file))
          if(File.exists?(file))
            fh=open(file, "r:ASCII-8BIT")
            num=0
            fh.each_line do |line|
              num=num+1
              if(pattern.match(line))
                sliceIdx=dir.length + 1
                escaped=line.chomp.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
                txt << "      <reporting type='#{name}' lineno='#{num}' file='#{file.to_s[sliceIdx..-1]}'>#{escaped}</reporting>\n"
              end
            end
            fh.close
          end
        end
      end
      return txt
  end

  # intended to be overridden
  # returns strings in xml format
  def report(repo, dir)
    raise "No report(repo, dir) function defined by report subclass"
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
  
end
