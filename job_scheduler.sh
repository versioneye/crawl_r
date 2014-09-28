#!/bin/bash

/bin/bash -l -c 'cd /ruby_crawl; /usr/local/bin/bundle exec rake versioneye:cocoa_pods_worker &'

/bin/bash -l -c 'cd /ruby_crawl; /usr/local/bin/bundle exec rake versioneye:scheduler_crawl_r'
