# Python Refactoring Plan

## Goal
Rewrite the CLI utility `pull_all_go` in Python, preserving all capabilities: scanning, parallel pull, colored reporting, dry-run, verbose mode, and worker count configuration.

## Main Requirements
- Recursive and non-recursive search for git repositories in specified directories
- Parallel execution of `git pull --prune --no-edit --all --ff-only --stat`
- Colored output: success (green), error (red)
- Flags: `-d` (directories), `-R` (recursively), `-w` (number of workers), `--dry-run`, `--verbose`
- Correct exit code when errors are present

## Architectural Decisions
- Argument parsing: `argparse`
- Colored output: `colorama` (if available) or direct ANSI codes
- Concurrency: `concurrent.futures.ThreadPoolExecutor`
- Git execution: `subprocess.run` with stdout/stderr capture and returncode checking
- Scanning: `pathlib.Path.glob` for recursive traversal, checking for `.git` folder presence

## Implementation Stages
1. Create executable script `pull_all.py` with basic CLI and argument processing
2. Implement scanning function: collect list of paths to `.git/..` considering the `-R` flag
3. Implement pull function for a single repository returning status and output
4. Main loop: worker pool, result collection, report output
5. Handle special cases: missing git, access errors, empty repositories
6. Add dry-run (only print commands without execution)
7. Test and document, write unit tests if necessary

## Dependencies
- Python >= 3.8
- `colorama` (recommended for stable color across all platforms)

## Notes
- Auxiliary shell scripts (`pull_all_old.sh`, `git_local_branches_ffwd_update.sh`) can be used as reference material
- Repository structure is preserved, new script is placed in the project root
