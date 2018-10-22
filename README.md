# The Kubernetes native experience: `kn`

The basic idea behind `kn` is to use the fact that pods in Kubernetes are modelled after machines. That is, the containers (==apps) can communicate with each other via `localhost` and transfer data via volumes they can mount into their own filesystem hierarchy as they see fit.

So, imagine you want to try something out real quick? Do a short iteration using a scripting language such as Python, Ruby, or Node.js? Might want to jump on a container to debug something in-cluster? Run a quick load test? Then, `kn` is for you: it offers a collection of shell functions allowing you to quickly launch a pod, jump into it and have the code and data available you need to carry out your task.

## Install

Clone or download this repo, copy `kn.sh` somewhere on your path. If you're super fancy, you can set an alias like so. Since I moved the script to `/Users/mhausenblas/bin/`, I'm using this alias:

```shell
alias kn='/Users/mhausenblas/bin/kn.sh'
```

I've tested `kn` in the Bash shell on macOS and Linux. The `kn` tool assumes that you have got `kubectl` [installed and configured](https://kubernetes.io/docs/tasks/tools/install-kubectl/). If you also want to benefit from exposing an environment to the public (optional feature), then you need to install [ngrok](https://ngrok.com/) as an dependency.

## Use

### Config

The following environment variables are used (set global or per invocation):

- `KN_BASE_IMAGE` … set the base image to use; defaults to `centos:7`.
- `KN_SYNC` … if set to `true`, the content of the current directory will be copied into the pod at `/tmp/work`; defaults to `true`.
- `KN_POLICY` … if set to `public`, services will be made available on the public Web using `ngrok`; defaults to `local`.

### Commands

The following commands are available:

- `up NAME` … creates environment, copies files of current directory unless disabled by `KN_SYNC=false`.
- `connect NAME` … puts you into the running environment.
- `down NAME` … deletes environment, removes all resources associated with it.
- `publish NAME PORT` … publishes environment `NAME` by using port-forwarding of `PORT` in the environment (assuming something serves on this port in the container) to port `9898` locally, and, if enabled by `KN_POLICY`, makes it also publicly available using `ngrok`.
- `ls` … lists all resources manged by `kn`.

### Example

Launching an interactive environment:

```shell
$ kn up
.......
Copied content of /Users/mhausenblas/tmp to /tmp/work in the environment
The environment [sandbox] is now ready!

$ kn ls
NAME      SINCE
sandbox   2018-10-22T10:16:13Z

$ kn connect
connecting to sandbox-64dc6d6bf9-s6gzjsh-4.2#
sh-4.2#
sh-4.2# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 10:16 ?        00:00:00 sleep 86400
root        27     0  0 10:17 pts/0    00:00:00 sh
root        36    27  0 10:17 pts/0    00:00:00 ps -ef
sh-4.2# exit
exit
$ kn down

```

Publishing a daemon environment:

```shell
$ KN_BASE_IMAGE=quay.io/mhausenblas/pingsvc:2 KN_MODE=daemon kn up psvc 8888

$ KN_POLICY=public kn publish psvc 8888

$ kn down psvc
```