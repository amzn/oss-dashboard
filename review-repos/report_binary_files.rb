#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
#require_relative 'reporter'

class BinaryReporter < Reporter

  def name()
    return "Binary File Report"
  end

  def describe()
    return "Uses the Linux file command to identify if a file is binary. Empty files and images are filtered out of the list. "
  end

  def report_class()
    return 'repo-report'
  end

  def report(context, repo, repodir)
    txt=""
    sliceIdx=repodir.length + 1
    Dir.glob("#{repodir}/**/*").each do |file|
      unless(File.directory?(file))
        type=`file --brief --mime '#{file}'`
        if(type.include?('charset=binary') and !type.include?('image/') and !type.include?('application/x-empty'))
          txt << "      <reporting class='repo-report' repo='#{repo.full_name}' type='BinaryReporter'><file>#{file.to_s[sliceIdx..-1]}</file></reporting>\n"
        end
      end
    end
    return txt
  end

end
