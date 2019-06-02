#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

swift package generate-xcodeproj
bundler exec jazzy \
    --clean \
    --author 'Juri Pakaste' \
    --author_url 'https://juripakaste.fi' \
    --github_url 'https://github.com/juri/graphqler' \
    --module 'GraphQLer' \
    --source-directory . \
    --readme 'README.md' \
    --output docs/
    exit
