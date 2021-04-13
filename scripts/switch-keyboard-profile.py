#!/usr/bin/env python3

import subprocess

CLI_PATH = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

BUILT_IN_PROFILE = "BuiltInKeyboard"
EXTERNAL_PROFILE = "ExternalKeyboard"

profile_to_switch_to = EXTERNAL_PROFILE if BUILT_IN_PROFILE in subprocess.run([CLI_PATH, "--show-current-profile-name"], stdout=subprocess.PIPE).stdout.decode('utf-8') else BUILT_IN_PROFILE
subprocess.run([CLI_PATH, "--select-profile", profile_to_switch_to])
