#!/usr/bin/env bash

# This script is used by Render to build the app for production deployment.

# set up an exit on error
set -o errexit

# install dependencies
mix deps.get --only prod

# compile for production
MIX_ENV=prod mix compile

# Ensure the Tailwind standalone CLI matches config (:tailwind version).
# Cached _build dirs from older Tailwind v3 installs keep a mismatched binary
# unless we reinstall; v3 fails on v4 `@import "tailwindcss"` CSS.
MIX_ENV=prod mix tailwind.install --if-missing

# complie the JavaScript and CSS assets
MIX_ENV=prod mix assets.deploy

# build the release
MIX_ENV=prod mix release --overwrite
