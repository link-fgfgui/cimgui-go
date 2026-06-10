package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: zigcgo cc|c++ [args...]")
		os.Exit(2)
	}

	mode := os.Args[1]
	if mode != "cc" && mode != "c++" {
		fmt.Fprintf(os.Stderr, "zigcgo: unsupported mode %q\n", mode)
		os.Exit(2)
	}

	target := os.Getenv("ZIG_CGO_TARGET")
	if target == "" {
		target = "x86_64-windows-gnu"
	}

	args := []string{mode, "-target", target}
	windowsGNU := strings.Contains(target, "windows-gnu")
	args = append(args, rewriteArgs(os.Args[2:], windowsGNU)...)
	if windowsGNU && isLinkCommand(os.Args[2:]) {
		args = append(args, "-lapi-ms-win-core-synch-l1-2-0")
	}

	cmd := exec.Command("zig", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	if err := cmd.Run(); err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			os.Exit(exitErr.ExitCode())
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func rewriteArgs(in []string, windowsGNU bool) []string {
	out := make([]string, 0, len(in))
	libDirs := make([]string, 0)

	for i := 0; i < len(in); i++ {
		arg := in[i]
		if windowsGNU && arg == "-static" {
			continue
		}

		if strings.HasPrefix(arg, "-L") && len(arg) > 2 {
			libDirs = append(libDirs, arg[2:])
			out = append(out, arg)
			continue
		}

		if arg == "-L" && i+1 < len(in) {
			libDirs = append(libDirs, in[i+1])
			out = append(out, arg, in[i+1])
			i++
			continue
		}

		if strings.HasPrefix(arg, "-l:") {
			if resolved := findArchive(libDirs, arg[3:]); resolved != "" {
				out = append(out, resolved)
				continue
			}
		}

		out = append(out, arg)
	}

	return out
}

func isLinkCommand(args []string) bool {
	for _, arg := range args {
		if arg == "-c" || arg == "-E" || arg == "-S" {
			return false
		}
	}
	return true
}

func findArchive(dirs []string, name string) string {
	for i := len(dirs) - 1; i >= 0; i-- {
		path := filepath.Join(filepath.FromSlash(dirs[i]), name)
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return ""
}
