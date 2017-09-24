FROM ruby:2.2.6-slim

COPY . /oss-dashboard
WORKDIR /oss-dashboard
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
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN gem install bundler \
  && bundle install --path vendor/bundle

ENTRYPOINT ["bundle", "exec", "ruby"]
CMD ["refresh-dashboard.rb", "/oss-dashboard/example-config/dashboard-config_postgres.yaml"]
