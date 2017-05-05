#!/bin/bash

set -e -x


echo "Building a release candidate with version number:"

cat api-nodejs/number

touch tag-out/rc_tag
echo "1.0.1" >> tag-out/rc_tag


