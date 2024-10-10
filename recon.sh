#!/bin/bash

# Check if a domain was provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Domain provided as a command-line argument
domain="$1"

# Directory to store temporary files
temp_dir=$(mktemp -d)

# Define a single temporary file for all tool outputs
output_temp_file="$temp_dir/all_tools_$domain.txt"

# Run enumeration tools in parallel and write to a single file
{
  subfinder -d "$domain" | httpx -silent
} >> "$output_temp_file" &

{
  sublist3r -d "$domain" | httpx -silent
} >> "$output_temp_file" &

{
  assetfinder -subs-only "$domain" | httpx -silent
} >> "$output_temp_file" &

{
  # Perform Shodan search for SSL certificates with the domain in the Common Name (CN) field
  shodan search "ssl.cert.subject.CN:\"$domain\" 200" --fields ip_str
} >> "$output_temp_file" &

# Wait for all background jobs to finish
wait

# Combine, sort, and extract unique subdomains and IP addresses in a single step
sort -u "$output_temp_file"

# Remove temporary directory and files
rm -rf "$temp_dir"
