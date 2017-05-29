#!/usr/bin/env ruby

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

require 'licensee'

# NOTE: Custom license filenames must be all lowercase as Licensee downcases them in its code

def licensee_monkey_patch(custom_path)

  puts "Monkey patching Licensee::License to add a custom license path: #{custom_path}"

  Licensee::License.class_eval do
  
      def self.add_custom_license_path(path)
        @custom_license_path=path
      end
  
      def self.custom_license_path
        return @custom_license_path
      end
  
      def self.license_files
        dir=license_dir()
        files ||= Dir.glob("#{license_dir()}/*.txt")
        custom_license_path().each do |custom_path|
          files.concat(Dir.glob("#{custom_path}/*.txt"))
        end
        return files
      end
  
      def path
         path ||= File.expand_path "#{@key}.txt", Licensee::License.license_dir
         unless(File.exist?(path))
           Licensee::License.custom_license_path().each do |custom_path|
             path = File.expand_path "#{@key}.txt", custom_path
             if(File.exist?(path))
               break
             end
           end
         end
         return path
      end
  
  end

  Licensee::License.add_custom_license_path(custom_path)

end
