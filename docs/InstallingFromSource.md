# Installing oss-dashboard

Follow these instructions to prepare to run the oss-dashboard.

## Firstly, you'll need to install the tools the oss-dashboard requires

### PostgreSQL

The oss-dashboard depends on PostgreSQL to store its data. You can either install a [local version](https://www.postgresql.org/download/), or use a hosted version (for example our own [Amazon RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/)).

If a dev package is available to be installed (for example Red Hat RPM/Debian APT based Linuxes), install that as well.

### git

The oss-dashboard pulls the latest code via git on the command line, so git needs to be installed. See the [git install instructions](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git). 

### ruby

The oss-dashboard scripts are written in Ruby, so you will need to [install Ruby](https://www.ruby-lang.org/en/documentation/installation/) as well.

#### Install Ruby Bundler

You'll also need the bundle command (to make installing the required libraries easier). Bundler is available [here](https://github.com/bundler/bundler) - but you can install it via the RubyGem libraries with the following:

```
 gem install bundler
```

## Git clone oss-dashboard

First, get the oss-dashboard code itself. You can git clone the latest code, or pull the latest release source:

```
git clone https://github.com/amznlabs/oss-dashboard.git
```

or:
```
wget https://github.com/amzn/oss-dashboard/releases/latest
```

## Lastly, you'll need to get the dependencies that oss-dashboard builds upon

Some of the Ruby libraries depend on other system libraries to be installed. On a Red Hat system, that means installing the following:
```
 sudo yum install libxml2-devel cmake postgresql95-libs postgresql95-devel libxslt-devel
```
 (NOTE: If folk have instructions for other operating systems, contributions would be very welcome)

And then you can tell Bundler to install the required libraries:
```
 cd oss-dashboard
 bundle install
```

Congratulations - you should now be ready to start configuring oss-dashboard. If you had issues installing, or suggestions for improvements to these instructions, please let us know via [an issue](https://github.com/amzn/oss-dashboard/issues/new).
