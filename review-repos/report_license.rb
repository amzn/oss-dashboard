#!/usr/bin/env ruby

require 'licensee'
require_relative 'reporter'

class LicenseReporter < Reporter

  def license_identify(repo, dir)
      begin
        license=Licensee::GitProject.new(dir).license
      rescue Licensee::GitProject::InvalidRepository
        # This should be unnecessary, they are all GitHub projects
        license=Licensee::FSProject.new(dir).license
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
