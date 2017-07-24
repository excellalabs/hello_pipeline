# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/passenger-full:0.9.22
# Or, instead of the 'full' variant, use one of these:
#FROM phusion/passenger-ruby20:<VERSION>
#FROM phusion/passenger-ruby21:<VERSION>
#FROM phusion/passenger-ruby22:<VERSION>
#FROM phusion/passenger-ruby23:<VERSION>
#FROM phusion/passenger-ruby24:<VERSION>
#FROM phusion/passenger-jruby91:<VERSION>
#FROM phusion/passenger-nodejs:<VERSION>
#FROM phusion/passenger-customizable:<VERSION>

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# If you're using the 'customizable' variant, you need to explicitly opt-in
# for features.
#
# N.B. these images are based on https://github.com/phusion/baseimage-docker,
# so anything it provides is also automatically on board in the images below
# (e.g. older versions of Ruby, Node, Python).
#
# Uncomment the features you want:
#
#   Ruby support
#RUN /pd_build/ruby-2.0.*.sh
#RUN /pd_build/ruby-2.1.*.sh
#RUN /pd_build/ruby-2.2.*.sh
#RUN /pd_build/ruby-2.3.*.sh
#RUN /pd_build/ruby-2.4.*.sh
#RUN /pd_build/jruby-9.1.*.sh
#   Python support.
#RUN /pd_build/python.sh
#   Node.js and Meteor standalone support.
#   (not needed if you already have the above Ruby support)
#RUN /pd_build/nodejs.sh

# Enable Nginx with Passenger
RUN rm -f /etc/service/nginx/down

# Config application for nginx and passenger
RUN rm /etc/nginx/sites-enabled/default
COPY templates/hello_world.conf /etc/nginx/sites-enabled/hello_world.conf
# Create passenger directory structure
RUN mkdir /home/app/hello_world
RUN mkdir /home/app/hello_world/public
RUN mkdir /home/app/hello_world/tmp
# Copy application files to app directory
COPY hello_world.rb /home/app/hello_world/hello_world.rb
COPY config.ru /home/app/hello_world/config.ru
COPY Gemfile /home/app/hello_world/Gemfile
COPY Gemfile.lock /home/app/hello_world/Gemfile.lock
RUN chown app:app -R /home/app/hello_world
RUN chmod 755 -R /home/app/hello_world
RUN cd /home/app/hello_world && /usr/local/rvm/wrappers/ruby-2.4.1@global/bundle install --deployment
RUN touch /home/app/hello_world/tmp/restart.txt

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
