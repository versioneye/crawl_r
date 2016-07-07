# ruby_crawl

This repo contains some crawlers written in ruby.

## Usage

* fire-up VersionEye core on docker

```
docker-compose up -d
```

* initialize ENV variables


```
source ./scripts/set_vars_for_dev.sh
```

* set up Ruby dependencies ( _only for first time_  )

```
gem install bundler
bundle install
```

* working on console

```
rake console
VersioneyeCore.new
NugetCrawler.crawl
```

* shutting down Docker instances

```
docker-compose down
```
Copyright (c) 2014 VersionEye. See LICENSE.txt for
further details.
