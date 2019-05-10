#!/bin/sh

# Simple script to pull all git subdirectories with submodules if exists
# Also can prune non existing remote branches
# USAGE: ./pull_all.sh -p -s

# NOTE: if the -depth 1 option is not available, try -mindepth 1 -maxdepth 1.

# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec echo $PWD/{} \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec git --git-dir={}/.git --work-tree=$PWD/{} status \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." \( -exec sh -c 'echo Repo: $PWD/{}; false' \; -false -o -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \; \)

PRUNE=0
SUBMODULES=0

while getopts 'ps' opt; do
    case $opt in
        p) PRUNE=1
           ;;
        s) SUBMODULES=1
           ;;
        *) echo 'Error in command line parsing' >&2
           exit 1
           ;;
    esac
done

shift "$((OPTIND-1))"

# Params after '--' to ARGV
[ "${1:-}" = "--" ] && shift

# Since git 1.8.5 we can do the next thing
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git -C {} pull \;
# Update main repositories (always)
echo "\e[92mUpdating repositories...\e[0m"
find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \;

# Prune non existing remote branches (-p arg)
if [ "$PRUNE" -eq 1 ]; then
    echo "\e[95mPrune non existing branches...\e[0m"
    find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git --git-dir={}/.git --work-tree=$PWD/{} fetch -p --all \;
fi

# And submodules update (-s arg)
if [ "$SUBMODULES" -eq 1 ]; then
    echo "\e[91mUpdating submodules...\e[0m"
    find . -type f -name '.gitmodules' | sed -r 's|/[^/]+$||' | sort | uniq | xargs -I % sh -c 'echo Repo: $PWD/%; git -C $PWD/% submodule update --remote --recursive --merge'
fi
