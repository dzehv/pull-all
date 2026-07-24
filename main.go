package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
)

// pathList allows multiple -d flags
// added this type to handle multiple directory inputs
type pathList []string

// implementation for flag.Value interface
func (p *pathList) String() string {
	return strings.Join(*p, ", ")
}

func (p *pathList) Set(value string) error {
	*p = append(*p, value)
	return nil
}

// config holds application settings
type config struct {
	paths     pathList // changed from 'path string' to 'paths pathList'
	workers   int
	recursive bool
	dryRun    bool
	verbose   bool
	tags      bool
}

// result holds the outcome of the git operation
type result struct {
	path string
	err  error
	out  []byte
}

func main() {
	cfg := parseFlags()

	// logic changed here to iterate over multiple paths
	var allRepos []string
	for _, path := range cfg.paths {
		repos, err := findRepos(path, cfg.recursive)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error scanning %s: %v\n", path, err)
			continue
		}
		allRepos = append(allRepos, repos...)
	}

	if len(allRepos) == 0 {
		fmt.Println("no git repositories found.")
		return
	}

	if cfg.dryRun {
		showDryRun(allRepos)
		return
	}

	results := runWorkerPool(cfg, allRepos)
	report(results, cfg.verbose)
}

// parseFlags handles cli arguments and mandatory checks.
func parseFlags() *config {
	cfg := &config{}

	// customize usage message
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: pull_all_go [OPTIONS]\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d ~/projects -d ~/wrk\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -dir /var/www -workers 20 -r\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -dir . -dry -verbose\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d ~/dev -r -w 5\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d . -v  # update and show git statistics (--stat)\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d . -v -t  # also fetch tags\n")
	}

	// updated to flag.Var to support multiple inputs for both short and long flags
	flag.Var(&cfg.paths, "d", "mandatory: path to parent directory")
	flag.Var(&cfg.paths, "dir", "long one -d")

	// your original options kept intact
	flag.IntVar(&cfg.workers, "w", 5, "number of concurrent workers")
	flag.IntVar(&cfg.workers, "workers", 5, "long one -w")
	flag.BoolVar(&cfg.recursive, "r", false, "recursive search for .git directories")
	flag.BoolVar(&cfg.recursive, "recursive", false, "long one -r")
	flag.BoolVar(&cfg.dryRun, "dry", false, "show repos without executing updates")
	flag.BoolVar(&cfg.verbose, "v", false, "show detailed error output")
	flag.BoolVar(&cfg.verbose, "verbose", false, "long one -v")

	// new flags for fetching tags
	flag.BoolVar(&cfg.tags, "t", false, "fetch tags (adds --tags to git pull)")
	flag.BoolVar(&cfg.tags, "tags", false, "long one -t")

	flag.Parse()

	// validation updated for slice length
	if len(cfg.paths) == 0 {
		fmt.Fprintln(os.Stderr, "\033[91merror: directory path (-d/-dir) is mandatory\033[0m")
		flag.Usage()
		os.Exit(1)
	}

	return cfg
}

// findRepos scans for .git directories efficiently.
func findRepos(root string, recursive bool) ([]string, error) {
	var repos []string
	err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if d.IsDir() && d.Name() == ".git" {
			repos = append(repos, filepath.Dir(path))
			if !recursive {
				return filepath.SkipDir
			}
		}

		return nil
	})

	return repos, err
}

// runWorkerPool initializes the goroutine pool and processes jobs.
func runWorkerPool(cfg *config, repos []string) <-chan result {
	jobs := make(chan string, len(repos))
	results := make(chan result, len(repos))
	var wg sync.WaitGroup

	// initialize the connection pool of workers
	for i := 0; i < cfg.workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			worker(jobs, results, cfg.tags)
		}()
	}

	// dispatch repositories to workers
	for _, repo := range repos {
		jobs <- repo
	}
	close(jobs)

	// close results when all workers finish
	go func() {
		wg.Wait()
		close(results)
	}()

	return results
}

// worker executes git commands and captures output with forced colors,
// optionally fetching tags.
func worker(jobs <-chan string, results chan<- result, tags bool) {
	for path := range jobs {
		args := []string{
			"-C", path,
			"-c", "color.ui=always",
			"-c", "color.status=always",
			"-c", "color.diff=always",
			"pull", "--prune", "--no-edit",
			"--all", "--ff-only", "--stat",
		}

		if tags {
			args = append(args, "--tags")
		}

		cmd := exec.Command("git", args...)

		out, err := cmd.CombinedOutput()
		results <- result{path: path, err: err, out: out}
	}
}

// report displays the status and the git output if requested.
func report(results <-chan result, verbose bool) {
	for res := range results {
		if res.err != nil {
			fmt.Printf("\033[91mFAILED:\033[0m %s\n", res.path)
			fmt.Printf("  output: %s\n", string(res.out))
		} else {
			fmt.Printf("\033[92mOK:\033[0m     %s\n", res.path)
			// if verbose is on, show the --stat output even for successful updates
			if verbose && len(res.out) > 0 {
				// git adds own newline char, so fmt.Print here to prevent double
				fmt.Print(string(res.out))
				// write directly to stdout buffer to avoid any fmt processing
				// os.Stdout.Write(res.out)
				// fmt.Println() // just for a newline
			}
		}
	}
}

// showDryRun simply lists found repositories.
func showDryRun(repos []string) {
	fmt.Printf("dry-run: found %d repositories:\n", len(repos))
	for _, repo := range repos {
		fmt.Printf(" - %s\n", repo)
	}
}
