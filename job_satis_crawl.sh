#!/bin/bash

/bin/bash -l -c 'cd /crawl_r; /usr/local/bin/bundle exec rake versioneye:satis_crawl_worker &'
/bin/bash -l -c 'cd /crawl_r; /usr/local/bin/bundle exec rake versioneye:satis_crawl_worker'
