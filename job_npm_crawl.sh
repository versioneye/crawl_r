#!/bin/bash

/bin/bash -l -c 'cd /crawl_r; /usr/local/bin/bundle exec rake versioneye:npm_crawl_worker &'
/bin/bash -l -c 'cd /crawl_r; /usr/local/bin/bundle exec rake versioneye:npm_crawl_worker &'
/bin/bash -l -c 'cd /crawl_r; /usr/local/bin/bundle exec rake versioneye:npm_crawl_worker'
