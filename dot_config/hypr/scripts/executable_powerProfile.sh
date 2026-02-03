#!/bin/bash
# Script for changing the power profile

CMD="powerprofilesctl set"

current=$(powerprofilesctl get)

case "$current" in
power-saver)
  $CMD balanced
  ;;
balanced)
  $CMD performance
  ;;
performance)
  $CMD power-saver
  ;;
*)
  echo "Unknown power profile: $current"
  exit 1
  ;;
esac
