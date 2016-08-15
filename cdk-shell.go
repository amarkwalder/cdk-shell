package main

import (
	"os/exec"
	"os"
	"os/signal"
	"fmt"
	"flag"
	"path/filepath"
)

var container string
var image string
var command string
var mount string
var rm bool

var (
	Version string
	Build string
)

func main() {
	banner()
	parse()
	check()
	removecontainer()
	signalhook()
	runcontainer()
}

func parse() {
	flag.StringVar(&container, "container", "cdk", "CDK container name")
	flag.StringVar(&image, "image", "busybox", "container image to start")
	flag.StringVar(&command, "command", "sh", "command run in container")
	flag.StringVar(&mount, "mount", ".", "mount directory")
	flag.BoolVar(&rm, "rm", false, "remove container at startup")
	flag.Parse()
}

func check() {
	if container == "" {
		flag.Usage()
		os.Exit(1)
	}

	var err error
	mount, err = filepath.Abs(mount)
	checkerror(err)

	src, err := os.Stat(mount)
	checkerror(err)
	if !src.IsDir() {
		fmt.Printf("Mount '%s' is not a directory.\n", mount)
		os.Exit(1)
	}
}

func banner() {
	fmt.Println()
	fmt.Println("   __  _ ___                           ____           __         ____")
	fmt.Println("  / /_(_| _ )   ____ ___     _________/ / /__   _____/ /_  ___  / / /")
	fmt.Println(" / __/ / __ \\/|/ __ `__ \\   / ___/ __  / //_/  / ___/ __ \\/ _ \\/ / /")
	fmt.Println("/ /_/ / /_/  </ / / / / /  / /__/ /_/ / ,<    (__  ) / / /  __/ / /  ")
	fmt.Println("\\__/_/\\____/\\/_/ /_/ /_/   \\___/\\__,_/_/|_|  /____/_/ /_/\\___/_/_/")
	fmt.Println()
	fmt.Println("Version : ", Version)
	fmt.Println("Build   : ", Build)
	fmt.Println()
}

func removecontainer() {
	if rm {
		fmt.Printf("Kill and remove docker container %s\n", container)
		dockerkill(container)
		dockerrm(container)
	}
}

func dockerkill(container string) {
	exec.Command("docker", "kill", container).Run()
}

func dockerrm(container string) {
	exec.Command("docker", "rm", container).Run()
}

func checkerror(err error) {
	if err != nil {
		panic(err)
	}
}

func signalhook() {
	signalchannel := make(chan os.Signal, 1)
	signal.Notify(signalchannel)
	go func() {
		for sig := range signalchannel {
			fmt.Printf("\n\nCaptured signal '%v', stopping docker container and exiting.\n\n", sig)
			dockerkill(container)
			dockerrm(container)
			os.Exit(1)
		}
	}()
}

func runcontainer() {
	cmd := exec.Command("docker", "run", "-it", "--rm", "--name", container, "-v", mount + ":/src", image, command)

	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Start()
	checkerror(err)

	defer cmd.Wait()
}