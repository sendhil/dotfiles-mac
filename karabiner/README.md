# Karabiner

Keyboard customization via [Karabiner-Elements](https://karabiner-elements.pqrs.org/).

## Profiles

There are two profiles:

- **ExternalKeyboard** - For use with an external keyboard and monitor
- **BuiltInKeyboard** - For use with the laptop's built-in keyboard

## Git Note

Karabiner-Elements rewrites `karabiner.json` whenever you switch profiles (updating the `selected` field, reformatting, adding defaults). To prevent noisy diffs, the file is marked with `skip-worktree`:

```bash
git update-index --skip-worktree karabiner/.config/karabiner/karabiner.json
```

This tells git to ignore local changes to the file. When you want to commit an actual config change:

```bash
# Temporarily unset skip-worktree
git update-index --no-skip-worktree karabiner/.config/karabiner/karabiner.json

# Stage and commit your changes
git add karabiner/.config/karabiner/karabiner.json
git commit -m "karabiner: update config"

# Re-enable skip-worktree
git update-index --skip-worktree karabiner/.config/karabiner/karabiner.json
```
