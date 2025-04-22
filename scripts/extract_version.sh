#!/bin/bash

# Extract version info from pubspec.yaml
VERSION=$(grep -E '^version:' pubspec.yaml | sed -E 's/version: +(.+)/\1/')
echo "Full version string: $VERSION"

# Split version into release version and build number
if [[ $VERSION =~ ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+) ]]; then
  RELEASE_VERSION="${BASH_REMATCH[1]}"
  BUILD_NUMBER="${BASH_REMATCH[2]}"
  echo "Release version: $RELEASE_VERSION"
  echo "Build number: $BUILD_NUMBER"
else
  echo "Error: Could not parse version string correctly"
  exit 1
fi

# Create or update .env file with version info
echo "VERSION=\"$VERSION\"" >> .env
echo "RELEASE_VERSION=\"$RELEASE_VERSION\"" >> .env
echo "BUILD_NUMBER=\"$BUILD_NUMBER\"" >> .env

echo "Version information added to .env file"