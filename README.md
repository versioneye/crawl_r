[![CircleCI](https://circleci.com/gh/versioneye/crawl_r.svg?style=svg)](https://circleci.com/gh/versioneye/crawl_r)

# ruby_crawl

This repo contains some crawlers implemented in Ruby.

## Usage

First fire up the VersionEye backend services like described [here](https://github.com/versioneye/ops_contrib#start-backend-services-for-versioneye).

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

## Support

For commercial support send a message to `support@versioneye.com`.

## License

This repository is licensed under the [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.en.html) license.
Send a message to `support@versioneye.com` if you are interested in a commercial license.
