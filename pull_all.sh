#!/bin/sh

# Simple script to pull all git subdirectories with submodules if exists
# Also can prune non existing remote branches
# USAGE:
# ./pull_all.sh -p -s
# WRITE remotes of repo list:
# ./pull_all.sh -w -f remotes_file.sh

# NOTE: if the -depth 1 option is not available, try -mindepth 1 -maxdepth 1.

# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec echo $PWD/{} \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec git --git-dir={}/.git --work-tree=$PWD/{} status \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." \( -exec sh -c 'echo Repo: $PWD/{}; false' \; -false -o -exec git --git-dir={}/.git --work-tree=$PWD/{} pull --no-edit \; \)

WRITE_REMOTES=0
REMOTES_FILE="git_remotes.sh"
PRUNE=0
SUBMODULES=0

while getopts 'wpsf:' opt; do
    case $opt in
        w) WRITE_REMOTES=1
           ;;
        p) PRUNE=1
           ;;
        s) SUBMODULES=1
           ;;
        f) REMOTES_FILE=$OPTARG
           ;;
        *) echo 'Error in command line parsing' >&2
           exit 1
           ;;
    esac
done

shift "$((OPTIND-1))"

# Params after '--' to ARGV
[ "${1:-}" = "--" ] && shift

# TODO: process multiple git remotes
# Collect repo links and write sh file as ready to git clone command
if [ "$WRITE_REMOTES" -eq 1 ]; then
    echo "Collecting repos links, writing to clone..."
    echo "#!/bin/sh\n" > $REMOTES_FILE
    find . -maxdepth 1 -type d -not -path "." -not -path ".." | sort | uniq | xargs -I % sh -c "git -C $PWD/% remote -v" >> $REMOTES_FILE
    # Prepare string to clone cmd
    sed -i -e 's/origin[[:space:]]/git clone /g' -e 's/[[:space:]](fetch)//g' -e 's/[[:space:]](push)//g' $REMOTES_FILE

    # Remove duplicate lines (if uniq is not working)

    # delete duplicate, consecutive lines from a file (emulates "uniq").
    # First line in a set of duplicate lines is kept, rest are deleted.
    sed -i '$!N; /^\(.*\)\n\1$/!P; D' $REMOTES_FILE
    # delete duplicate, nonconsecutive lines from a file. Beware not to
    # overflow the buffer size of the hold space, or else use GNU sed.
    # sed -i -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P' remotes.sh
    chmod +x $REMOTES_FILE
    exit 0
fi

# Since git 1.8.5 we can do the next thing
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git -C {} pull --no-edit \;
# Update main repositories (always)
echo "\033[92mUpdating repositories...\033[0m"
find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git --git-dir={}/.git --work-tree=$PWD/{} pull --no-edit \;

# Prune non existing remote branches (-p arg)
if [ "$PRUNE" -eq 1 ]; then
    echo "\033[95mPrune non existing branches...\033[0m"
    find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $PWD/{}; true' \; -exec git --git-dir={}/.git --work-tree=$PWD/{} fetch -p --all \;
fi

# And submodules update (-s arg)
if [ "$SUBMODULES" -eq 1 ]; then
    echo "\033[91mUpdating submodules...\033[0m"
    SED="sed"
    case "$OSTYPE" in
        *darwin*)
            SED="gsed"
            ;;
    esac
    # if [ -z "${OSTYPE##*darwin*}" ]; then
        # SED="gsed"
    # fi
    find . -type f -name '.gitmodules' | $SED -r 's|/[^/]+$||' | sort | uniq | xargs -I % sh -c 'echo Repo: $PWD/%; git -C $PWD/% submodule update --remote --recursive --merge'
fi
