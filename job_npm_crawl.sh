#!/bin/bash

/bin/bash -l -c 'cd /ruby_crawl; /usr/local/bin/bundle exec rake versioneye:npm_crawl_worker'
