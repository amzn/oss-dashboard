#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'reporter'

class DocsReporter < Reporter

  def report(repo, repodir)
    # Look for any text files
    filename_check(repo, repodir, /\.txt$/, 'documentation', /(LICENSE.txt|NOTICE.txt)/);
    # Look for any md files, this also picks up README.md
    filename_check(repo, repodir, /\.md$/, 'documentation', /(LICENSE.md|NOTICE.md)/);
  end

end
