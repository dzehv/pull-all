#!/bin/sh

# simple script to pull all git subdirectories (with submodules if exists)
# also can prune non existing remote branches
# USAGE:
# ./pull_all.sh -p -s
# WRITE remotes of repo list:
# ./pull_all.sh -w -f remotes_file.sh

# NOTE: if the -depth 1 option is not available, try -mindepth 1 -maxdepth 1.

# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec echo $DIR/{} \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec git --git-dir={}/.git --work-tree=$DIR/{} status \;
# find . -maxdepth 1 -type d -not -path "." -not -path ".." \( -exec sh -c 'echo Repo: $DIR/{}; false' \; -false -o -exec git --git-dir={}/.git --work-tree=$DIR/{} pull --no-edit \; \)

# transform long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
        "--dir")           set -- "$@" "-d" ;;
        "--help")          set -- "$@" "-h" ;;
        "--write-remotes") set -- "$@" "-w" ;;
        "--prune")         set -- "$@" "-p" ;;
        "--submodules")    set -- "$@" "-s" ;;
        "--remotes-file")  set -- "$@" "-f" ;;
        "--all")           set -- "$@" "-a" ;;
        *)                 set -- "$@" "$arg" ;;
    esac
done

# defaults
DIR="."
HELP=0
WRITE_REMOTES=0
REMOTES_FILE="git_remotes.sh"
PRUNE=0
SUBMODULES=0
ALL=0

# and parse at least
while getopts 'd:hwpsaf:' opt; do
    case $opt in
        d) DIR=$OPTARG
           ;;
        h) HELP=1
           ;;
        w) WRITE_REMOTES=1
           ;;
        p) PRUNE=1
           ;;
        s) SUBMODULES=1
           ;;
        f) REMOTES_FILE=$OPTARG
           ;;
        a) ALL=1
           ;;
        *) echo 'Error in command line parsing' >&2
           exit 1
           ;;
    esac
done

shift "$((OPTIND-1))"

# params after '--' to ARGV
[ "${1:-}" = "--" ] && shift

if [ "$HELP" -eq 1 ]; then
    USAGE=$(cat << EOF
Usage: ./$(basename $0) [OPTIONS]\n
\n
Options:\n
    -d, Specify parent dir to search for repos\n
    -h, Show this text\n
    -w, Write remotes to file as ready to clone sh script\n
    -p, Prune non existing branches at remote\n
    -s, Also update git submodules\n
    -a, Update all local brnaches to their upstream ff-only\n
    -f <FILE>, write remotes to specified file\n
\n
Long alternative options:\n
    --dir <PATH>\n
    --help\n
    --write-remotes\n
    --prune\n
    --submodules\n
    --all\n
    --remotes-file <FILE>\n
\n
Examples:\n
    ./pull_all.sh -p -s -a\n
    Write remotes of repo list to specified file:\n
    ./pull_all.sh -w -f remotes_file.sh\n
    Same with long opts:\n
    ./pull_all.sh --write-remotes --remotes-file remotes_file.sh\n
    With specified dir\n
    ./pull_all.sh --dir /home/user/gitrepos\n
EOF
)
    echo $USAGE
    exit 0
fi

# collect repo links and write sh file as ready to git clone command
if [ "$WRITE_REMOTES" -eq 1 ]; then
    echo "Collecting repos links, writing to clone..."
    echo "#!/bin/sh\n" > $REMOTES_FILE
    find $DIR -maxdepth 1 -type d -not -path "." -not -path ".." -not -path "$DIR" | sort | uniq | xargs -I % sh -c 'FILE="%"; git -C $DIR/$FILE remote -v' >> $REMOTES_FILE
    # prepare string to clone cmd
    sed -i -e 's/origin[[:space:]]/git clone /g' -e 's/[[:space:]](fetch)//g' -e 's/[[:space:]](push)//g' $REMOTES_FILE

    # remove duplicate lines (if uniq is not working)

    # delete duplicate, consecutive lines from a file (emulates "uniq").
    # first line in a set of duplicate lines is kept, rest are deleted.
    sed -i '$!N; /^\(.*\)\n\1$/!P; D' $REMOTES_FILE
    # delete duplicate, nonconsecutive lines from a file. Beware not to
    # overflow the buffer size of the hold space, or else use GNU sed.
    # sed -i -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P' remotes.sh
    chmod +x $REMOTES_FILE
    exit 0
fi

# since git 1.8.5 we can do the next thing
# find . -maxdepth 1 -type d -not -path "." -not -path ".." -exec sh -c 'echo Repo: $DIR/{}; true' \; -exec git -C {} pull --no-edit --all \;
# NOTE: update main repositories (always)
echo "\033[92mUpdating repositories...\033[0m"
find $DIR -maxdepth 1 -type d -not -path "." -not -path ".." -not -path "$DIR" -exec sh -c 'echo Repo: {}; true' \; -exec git --git-dir={}/.git --work-tree={} pull --no-edit --all \;

# Prune non existing remote branches (-p arg)
if [ "$PRUNE" -eq 1 ]; then
    echo "\033[95mPrune non existing branches...\033[0m"
    find $DIR -maxdepth 1 -type d -not -path "." -not -path ".." -not -path "$DIR" -exec sh -c 'echo Repo: {}; true' \; -exec git --git-dir={}/.git --work-tree={} fetch -p --all \;
fi

# submodules update (-s arg)
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
    find $DIR -type f -name '.gitmodules' | $SED -r 's|/[^/]+$||' | sort | uniq | xargs -I % sh -c 'FILE="%"; echo Repo: $FILE; git -C $FILE submodule update --remote --recursive --merge'
fi

# TODO: evaluate 'SCRIPT' code here instead of file copying
# remote branches update (-a arg)
if [ "$ALL" -eq 1 ]; then
    if [ -f "git_local_branches_ffwd_update.sh" ]; then
        echo "\033[90mSync all local branches to their remotes...\033[0m"
        find $DIR -maxdepth 1 -type d -not -path "." -not -path ".." -not -path "$DIR" | sort | uniq | xargs -I % sh -c 'FILE="%"; SCRIPT="git_local_branches_ffwd_update.sh"; SCRIPT_COPY="git_local_branches_ffwd_update_copy.sh"; echo Repo: $FILE; cp $SCRIPT $FILE/$SCRIPT_COPY; cd $FILE/; sh $SCRIPT_COPY; rm $SCRIPT_COPY'
    else
        echo "No git update script existing"
    fi
fi
