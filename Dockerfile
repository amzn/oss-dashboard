FROM ruby:2.4.5

RUN apt update && apt install --no-install-recommends -y \
  build-essential \
  cmake \
  file \
  git \
  libpq-dev \
  libxml2-dev \
  libxslt1-dev \
  libssl-dev \
  pkg-config \
  postgresql \
  netcat \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /oss-dashboard

COPY ./Gemfile /oss-dashboard/Gemfile
COPY ./Gemfile.lock /oss-dashboard/Gemfile.lock
COPY ./Rakefile /oss-dashboard/Rakefile
RUN gem install bundler \
  && bundle install --path vendor/bundle

COPY . /oss-dashboard

ENTRYPOINT ["bundle", "exec", "ruby"]
CMD ["refresh-dashboard.rb", "/oss-dashboard/example-config/dashboard-config_postgres.yaml"]
