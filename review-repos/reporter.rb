#!/usr/bin/env ruby

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
          txt << "      <reporting type='#{name}'>#{file.to_s[sliceIdx..-1]}</reporting>\n"
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
  
end
