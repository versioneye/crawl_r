#!/bin/bash

/bin/bash -l -c 'cd /ruby_crawl; /usr/local/bin/bundle exec rake versioneye:satis_crawl_worker &'
/bin/bash -l -c 'cd /ruby_crawl; /usr/local/bin/bundle exec rake versioneye:satis_crawl_worker'