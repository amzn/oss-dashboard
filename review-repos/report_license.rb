#!/usr/bin/env ruby

require 'licensee'
require_relative 'reporter'

class LicenseReporter < Reporter

  def license_identify(repo, dir)
      begin
        license=Licensee::GitProject.new(dir).license
      rescue ArgumentError
        puts "Error getting license for #{dir}"
        return "      <reporting type='LicenseFilesReporter'>License causes error</reporting>\n"
      end

      if(license)
        return "      <license>#{license.name}</license>\n"
      else
        return "      <reporting type='LicenseReporter'>Unrecognized/Missing License</reporting>\n"
      end
  end

  def report(repo, repodir)
    # Run the license review
    license_identify(repo, repodir);
  end

end
