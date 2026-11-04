#!/usr/bin/env bash

# Wrapper script for nnn file selection
# This mimics the functionality of yazi-wrapper.sh but for nnn

# Function to launch nnn with file selection capability
launch_nnn() {
    # Create a temporary fifo for communication if needed
    local fifo="/tmp/nnn.fifo"
    
    # Clean up any existing fifo
    if [[ -p "$fifo" ]]; then
        rm "$fifo"
    fi
    
    # Create the fifo
    mkfifo "$fifo"
    
    # Launch nnn in file selection mode with proper options
    # Using -d for directory mode, -c for clipboard mode, -s for selection mode
    nnn -d -c -s "$@"
    
    # Clean up
    rm -f "$fifo"
}

# Main execution
launch_nnn "$@"