# Ubuntu-only shell environment. Wayland variables are set only in a Wayland
# session so SSH and the GNOME fallback remain usable.
export BROWSER=${BROWSER:-xdg-open}
export TERMINAL=${TERMINAL:-wezterm}

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  export MOZ_ENABLE_WAYLAND=${MOZ_ENABLE_WAYLAND:-1}
  export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-'wayland;xcb'}
  export SDL_VIDEODRIVER=${SDL_VIDEODRIVER:-'wayland,x11'}
fi
