#!/usr/bin/env python3

import subprocess

if "1" in subprocess.run(["defaults", "read", "NSGlobalDomain", "com.apple.swipescrolldirection"], stdout=subprocess.PIPE).stdout.decode('utf-8'):
    subprocess.run(["defaults", "write", "NSGlobalDomain", "com.apple.swipescrolldirection", "-bool", "NO"])
else:
    subprocess.run(["defaults", "write", "NSGlobalDomain", "com.apple.swipescrolldirection", "-bool", "YES"])
