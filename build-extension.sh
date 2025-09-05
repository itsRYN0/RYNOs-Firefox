#!/usr/bin/env bash

set -e

# Script to automate building of the extension

CWD=$(pwd)
DEBUG=false
ARG_1=${1}

# Check if the '-d' flag was given from CLI and set 'DEBUG' mode accordingly
if [[ "$ARG_1" == "-d" ]]; then
  DEBUG=true
fi

# ANSII colour codes for text output
NC='\033[0m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;34m'

function print_debug() {
  if [ "$DEBUG" == "true" ]; then
    echo -e "${PURPLE}DEBUG:${NC} ${*}"
  fi
  return
}

function exit_func() {
  local exit_int=${1:-0}

  print_debug "'exit_func' called"
  print_debug "CWD = $CWD"
  print_debug "pwd = $(pwd)"

  if [[ "$CWD" != "$(pwd)" ]]; then
    cd "$CWD" || exit 1
  fi

  exit $exit_int
}

function check_cmd() {
  local cmd=${1}

  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo -e "${RED}ERROR:${NC} '${cmd}' command not found, please install it. Exiting..."
    exit_func 1
  fi
  return 0
}

check_cmd "jq"
check_cmd "npm"
check_cmd "sponge"

# If the 'web-ext' command is not found, install it or exit if 'npm' is also not installed
if ! command -v web-ext >/dev/null 2>&1; then
  echo -e "${YELLOW}WARNING:${NC} The required '${YELLOW}web-ext${NC}' command could not be found, installing using npm..."

  echo -e "${BLUE}INFO:${NC} Installing the '${YELLOW}web-ext${NC}' npm package as it was not found..."
  npm install --global web-ext
fi

print_debug "switching to dir: ${CWD}/extension"
cd "${CWD}/extension" || exit 1

# Get version from the manifest file and ensure it can be read as an int
VERSION=$(jq -M '.version' manifest.json | sed 's#"##g')
print_debug "VERSION = $VERSION"

IFS=. read -r major minor patch <<<"$VERSION"

print_debug "major = $major"
print_debug "minor = $minor"
print_debug "patch = $patch"

((patch++))

# Update the patch, minor, and major versions as the values increase over time
if [ "$patch" -gt 10 ]; then
  print_debug "patch is greater than 10, updating patch to == '0' and bumping '${CYAN}minor${NC}' version by '1'..."
  patch=0
  ((minor++))
fi
if [ "$minor" -gt 10 ]; then
  print_debug "minor is greater than 10, updating minor to == '0' and bumping '${CYAN}major${NC}' version by '1'..."
  minor=0
  ((major++))
fi
NEW_VERSION="${major}.${minor}.${patch}"

# Use jq to update the manifest version
jq ".version |= \"${NEW_VERSION}\"" manifest.json | sponge manifest.json

# Delete the build artifact dir if it already exists as is created by 'web-ext' command
# if [ -d "$(pwd)/web-ext-artifacts/" ]; then
#   rm -rf "$(pwd)/web-ext-artifacts/"
# fi

if ! web-ext build; then
  echo -e "${RED}ERROR:${NC} Failed running the 'web-ext build' command. Exiting with error..."
  exit_func 1
fi

echo -e "${BLUE}INFO:${NC} Build completed successfully, exiting..."

exit_func 0

