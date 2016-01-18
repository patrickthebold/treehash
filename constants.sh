#!/usr/bin/env bash
MY_DIR=/path/to/some/temporary/storage/dir
SPLIT_SIZE=$((128*1024*1024))
PREFIX=file-
bytes () {
  echo $(ls -l "$1" | awk '{print $5}')
}
set -e
