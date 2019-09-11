# Update git subdirectories

### Install:

``` shell
sudo make install
```

### Usage:

``` shell
pull_all [OPTIONS]
```

#### Options:

    -d, Specify parent dir to search for repos (mandatory option)
    -h, Show this text
    -w, Write remotes to file as ready to clone sh script
    -p, Prune non existing branches at remote
    -s, Also update git submodules
    -l, Update all local branches to their upstream ff-only
    -f <FILE>, write remotes to specified file
    -r find repositories recursively and update them

#### Long alternative options:

    --dir <PATH>
    --help
    --write-remotes
    --prune
    --submodules
    --local-branches
    --remotes-file <FILE>
    --recursive

#### Examples:

``` shell
pull_all -d ~/gitrepos -p -s -l
```

Bundling options:

``` shell
pull_all -d ~/gitrepos -psl
```

Write remotes of repo list to specified file:

``` shell
pull_all -d ~/gitrepos -w -f remotes_file.sh
```

Same with long opts:

``` shell
pull_all --dir ~/gitrepos --write-remotes --remotes-file remotes_file.sh
```

``` shell
pull_all --dir /home/user/gitrepos --prune --local-branches
```
