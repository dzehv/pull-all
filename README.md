# Pull all git subdirectories

Place scripts to repositories root dir:

``` shell
cp pull_all.sh git_local_branches_ffwd_update.sh repos_root_folder/
```

Looks like this:

``` shell
.
..
some_repo_folder1
some_repo_folder2
some_repo_folder3
pull_all.sh
git_local_branches_ffwd_update.sh
```

### USAGE:

``` shell
./pull_all.sh [OPTIONS]
```

#### Options:

    -h, Show this text
    -w, Write remotes to file as ready to clone sh script
    -p, Prune non existing branches at remote
    -s, Also update git submodules
    -a, Update all local brnaches to their upstream ff-only
    -f <FILE>, write remotes to specified file

#### Long alternative options:

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
