#!/bin/bash -e

if xrandr | grep --quiet 3440x1440; then
  echo polybar
else
  echo polybar-laptop
fi 
