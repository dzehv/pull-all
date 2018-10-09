#!/bin/sh

# Simple script to pull all git subdirectories

# NOTE: if the -depth 1 option is not available, try -mindepth 1 -maxdepth 1.

# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec echo $PWD/{} \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec git --git-dir={}/.git --work-tree=$PWD/{} status \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." \( -exec sh -c 'echo Repo: $PWD/{}; false' \; -false -o -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \; \)

find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \;

# Since git 1.8.5 we can do the next thing

# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git -C {} pull \;
