#!/bin/bash -e
export USER=app

source /home/app/perl5/perlbrew/etc/bashrc

cd /tmp/
cpanm --from https://cpan.metacpan.org/ . --installdeps -n

