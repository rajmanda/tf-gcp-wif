#!/bin/bash

# Check if a search string is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <search-string>"
  exit 1
fi

SEARCH_STRING=$1

# Fetch all branches from the remote
git fetch --all

# Iterate over each branch and search for the string
for branch in $(git branch -r | grep -v '\->'); do
  echo "Searching in branch: $branch"
  git grep "$SEARCH_STRING" "$branch"
done
