FROM        versioneye/ruby-base:2.4.21
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ADD . /app

RUN cp /app/supervisord.conf /etc/supervisord.conf; \
    cd /app/ && bundle install;

CMD /usr/bin/supervisord -c /etc/supervisord.conf
