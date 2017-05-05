#!/bin/bash

set -e -x


echo "Building a release candidate"
touch api-nodejs/rc_tag
echo "1.0.1" >> api-nodejs/rc_tag
