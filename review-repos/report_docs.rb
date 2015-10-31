#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'reporter'

class DocsReporter < Reporter

  def report(repo, repodir)
    # Look for any text files
    txt  = filename_check(repo, repodir, /\.txt$/, 'documentation', /(LICENSE.txt|NOTICE.txt)/);
    # Look for any md files, this also picks up README.md
    txt << filename_check(repo, repodir, /\.md$/, 'documentation', /(LICENSE.md|NOTICE.md)/);
    return txt
  end

end
