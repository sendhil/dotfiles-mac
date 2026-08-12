#!/bin/bash

set -u

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

assert_contains() {
  haystack=$1
  needle=$2
  message=$3
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "$message (missing: $needle)" ;;
  esac
}

assert_not_contains() {
  haystack=$1
  needle=$2
  message=$3
  case "$haystack" in
    *"$needle"*) fail "$message (found: $needle)" ;;
    *) ;;
  esac
}

assert_status() {
  expected=$1
  shift
  set +e
  "$@" >/dev/null 2>&1
  actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || fail "expected status $expected, got $actual: $*"
}
