package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
)

// config holds application settings
type config struct {
	path      string
	workers   int
	recursive bool
	dryRun    bool
	verbose   bool
}

// result holds the outcome of the git operation
type result struct {
	path string
	err  error
	out  []byte
}

func main() {
	cfg := parseFlags()

	repos, err := findRepos(cfg.path, cfg.recursive)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error scanning: %v\n", err)
		os.Exit(1)
	}

	if len(repos) == 0 {
		fmt.Println("no git repositories found.")
		return
	}

	if cfg.dryRun {
		showDryRun(repos)
		return
	}

	results := runWorkerPool(cfg, repos)
	report(results, cfg.verbose)
}

// parseFlags handles cli arguments and mandatory checks
func parseFlags() *config {
	cfg := &config{}

	// customize usage message
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: pull_all_go [OPTIONS]\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d ~/projects\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d /var/www -w 20 -r\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d . -dry -v\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d ~/dev -r -w 5\n")
		fmt.Fprintf(os.Stderr, "  pull_all_go -d . -v  # update and show git statistics (--stat)\n")
	}

	flag.StringVar(&cfg.path, "d", "", "mandatory: path to parent directory")
	flag.IntVar(&cfg.workers, "w", 10, "number of concurrent workers")
	flag.BoolVar(&cfg.recursive, "r", false, "recursive search for .git directories")
	flag.BoolVar(&cfg.dryRun, "dry", false, "show repos without executing updates")
	flag.BoolVar(&cfg.verbose, "v", false, "show detailed error output")
	flag.Parse()

	if cfg.path == "" {
		fmt.Fprintln(os.Stderr, "\033[91merror: directory path (-d) is mandatory\033[0m")
		flag.Usage()
		os.Exit(1)
	}

	return cfg
}

// findRepos: scans for .git directories efficiently
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

// runWorkerPool: initializes the goroutine pool and processes jobs
func runWorkerPool(cfg *config, repos []string) <-chan result {
	jobs := make(chan string, len(repos))
	results := make(chan result, len(repos))
	var wg sync.WaitGroup

	// initialize the connection pool of workers
	for i := 0; i < cfg.workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			worker(jobs, results)
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

// worker: executes git commands and captures output with forced colors
func worker(jobs <-chan string, results chan<- result) {
	for path := range jobs {
		// forcing interactive terminal behavior
		cmd := exec.Command("git", "-C", path,
			"-c", "color.ui=always",
			"-c", "color.status=always",
			"-c", "color.diff=always",
			"pull", "--prune", "--no-edit",
			"--all", "--ff-only", "--stat")

		out, err := cmd.CombinedOutput()
		results <- result{path: path, err: err, out: out}
	}
}

// report: displays the status and the git output if requested
func report(results <-chan result, verbose bool) {
	for res := range results {
		if res.err != nil {
			fmt.Printf("\033[91mFAILED:\033[0m %s\n", res.path)
			fmt.Printf("  output: %s\n", string(res.out))
		} else {
			fmt.Printf("\033[92mOK:\033[0m     %s\n", res.path)
			// if verbose is on, show the --stat output even for successful updates
			if verbose && len(res.out) > 0 {
				fmt.Printf("%s\n", string(res.out))
				// write directly to stdout buffer to avoid any fmt processing
				// os.Stdout.Write(res.out)
				// fmt.Println() // just for a newline
			}
		}
	}
}

// showDryRun: simply lists found repositories
func showDryRun(repos []string) {
	fmt.Printf("dry-run: found %d repositories:\n", len(repos))
	for _, repo := range repos {
		fmt.Printf(" - %s\n", repo)
	}
}
