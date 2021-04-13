#!/usr/bin/env python3

import subprocess

CLI_PATH = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

BUILT_IN_PROFILE = "BuiltInKeyboard"
EXTERNAL_PROFILE = "ExternalKeyboard"

if BUILT_IN_PROFILE in subprocess.run([CLI_PATH, "--show-current-profile-name"], stdout=subprocess.PIPE).stdout.decode('utf-8'):
    subprocess.run([CLI_PATH, "--select-profile", EXTERNAL_PROFILE])
    subprocess.run(["defaults", "write", "NSGlobalDomain", "com.apple.swipescrolldirection", "-bool", "NO"])
else:
    subprocess.run([CLI_PATH, "--select-profile", BUILT_IN_PROFILE])
    subprocess.run(["defaults", "write", "NSGlobalDomain", "com.apple.swipescrolldirection", "-bool", "YES"])
