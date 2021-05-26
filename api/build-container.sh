#!/bin/bash -e
cp Makefile.PL docker/Makefile_local.PL

docker build -t its/lgpdjus_api docker/
