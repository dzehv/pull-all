# Pull all git subdirectories

### USAGE:

``` shell
./pull_all.sh [OPTIONS]
```

#### Options:

    -d, Specify parent dir to search for repos ("." by default)
    -h, Show this text
    -w, Write remotes to file as ready to clone sh script
    -p, Prune non existing branches at remote
    -s, Also update git submodules
    -a, Update all local brnaches to their upstream ff-only
    -f <FILE>, write remotes to specified file

#### Long alternative options:

    --dir <PATH>
    --help
    --write-remotes
    --prune
    --submodules
    --all
    --remotes-file <FILE>

#### Examples:

``` shell
./pull_all.sh -p -s -a
```

Write remotes of repo list to specified file:

``` shell
./pull_all.sh -w -f remotes_file.sh
```

Same with long opts:

``` shell
./pull_all.sh --write-remotes --remotes-file remotes_file.sh
```

``` shell
./pull_all.sh --dir /home/user/gitrepos --prune --all
```
