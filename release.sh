#!/bin/bash -e

name=$(grep '"name"' info.json | sed 's/^.*: *"\([^"]*\)".*$/\1/')
version=$(grep '"version"' info.json | sed 's/^.*: *"\([^"]*\)".*$/\1/')

cd ..
set -x
zip -r "${name}_${version}.zip" ${name}

