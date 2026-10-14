#!/usr/bin/env python3
"""Save a Git patch (including safe untracked text files) for inspection only."""
import argparse
import pathlib
import subprocess

def run(args, cwd):
    return subprocess.run(args, cwd=cwd, check=True, stdout=subprocess.PIPE).stdout

def collect(repo, out):
    repo, out = pathlib.Path(repo), pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    # Files are untrusted; no repository-provided scripts are run.
    untracked = run(['git', 'ls-files', '--others', '--exclude-standard', '-z'], repo).split(b'\x00')
    for path in untracked:
        if not path:
            continue
        text = path.decode('utf-8', 'surrogateescape')
        run(['git', 'add', '-N', '--', text], repo)
    (out / 'solution.patch').write_bytes(run(['git', 'diff', '--binary', '--no-ext-diff'], repo))
    (out / 'status.txt').write_bytes(run(['git', 'status', '--short'], repo))
    if not (out / 'solution.patch').stat().st_size:
        print('No code diff produced; save no claims of a completed fix.')
    else:
        print('Draft patch collected. It has NOT been tested or submitted.')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--repo', required=True)
    p.add_argument('--out', required=True)
    x = p.parse_args()
    collect(x.repo, x.out)

if __name__ == '__main__':
    main()
