#!/usr/bin/env bash

# Wrapper script for nnn file selection
# This mimics the functionality of yazi-wrapper.sh but for nnn

# Launch nnn in file selection mode with proper options
# Using -e to enable file selection mode and -c for clipboard mode
nnn -e -c "$@"