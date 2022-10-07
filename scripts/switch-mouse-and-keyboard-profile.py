#!/usr/bin/env python3

import subprocess
import pathlib
import os

CLI_PATH = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

BUILT_IN_PROFILE = "BuiltInKeyboard"
EXTERNAL_PROFILE = "ExternalKeyboard"
    
TRACKPAD_SCRIPT_PATH = os.path.join(pathlib.Path(__file__).parent.resolve(), 'toggle-trackpad.sh')

if BUILT_IN_PROFILE in subprocess.run([CLI_PATH, "--show-current-profile-name"], stdout=subprocess.PIPE).stdout.decode('utf-8'):
    subprocess.run([CLI_PATH, "--select-profile", EXTERNAL_PROFILE])
    subprocess.run([TRACKPAD_SCRIPT_PATH], stdout=subprocess.PIPE)
else:
    subprocess.run([CLI_PATH, "--select-profile", BUILT_IN_PROFILE])
    subprocess.run([TRACKPAD_SCRIPT_PATH], stdout=subprocess.PIPE)
