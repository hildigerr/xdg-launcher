#!/bin/sh
#
# Launcher Enforcing XDG Base Directory Compliance
#
#  Some applications refuse to comply with user's XDG Base Directory settings.
#  So, we redefine HOME to enforce compliance.
#  However, they often need to be able to find the Xauthority file.
#  So, we temporarily link it.
#  Some applications half-ass comply using cache and/or config for some things.
#  So, we temporarily link them too, enforcing XDG_{CACHE,CONFIG}_HOME setting.
#
# Copyright (C) 2025 Hildigerr Vergaray [MIT License]

usage() { echo "Usage: $0 [-cd <directory>] [--fuzz] [--quiet] application> [-- options]"; exit; }

increment_lock() {
  touch "${STATE_FILE}"
  local update="$(awk -F'::' -v OFS='::' -v path="${XDG_DATA_HOME}" '
      BEGIN { count = 0 }
      $2 == path { count = ++$1 }
      { print }
      END { if (!count) { print "1::" path } }
    ' "${STATE_FILE}")" || {
      echo "Error: Failed to register resource lock" >&2
      exit 1
    }
  echo "$update" > "${STATE_FILE}"
}

decrement_lock() {
  local count=$(awk -F'::' -v path="${XDG_DATA_HOME}" '
    $2 == path { print $1; exit }
  ' "${STATE_FILE}" ) || count=0

  if [ "$count" -lt 1 ]; then
    echo "Error: Resource lock corrupted [${count}]" >&2
    echo "       Unlinking will not occur in case links are still needed." >&2
    exit 1
  fi

  sed -i "s|$count::${XDG_DATA_HOME}$|$((count - 1))::${XDG_DATA_HOME}|" "${STATE_FILE}"
  if [ ! $? ]; then
    echo "Error: Failed to deregister resource lock [$count]" >&2
    echo "       Unlinking will not occur in case links are still needed." >&2
    exit 1
  fi
  return $((count - 1))
}

# Save stdout and stderr for quiet mode
exec 3>&1 4>&2

while [ "$#" -gt 0 ]; do
  case $1 in
    --dir|--cd|-d)
      WORKING_DIRECTORY="$2"
      if [ -d "$WORKING_DIRECTORY" ]; then
        pushd "$WORKING_DIRECTORY"
      else
        echo "Error: No such directory: \"$WORKING_DIRECTORY\""
        exit 1
      fi
      shift;;
    --fuzz|-f) FUZZ="/tmp/${USER}/passwd.$$";;
    --help|-h) useage;;
    --quiet|-q) QUIET="$1";;
    --) shift; break;;
    *) if [ -z "$APPLICATION" ]; then APPLICATION="$1"; else usage; fi;;
  esac
  shift
done
if [ -z "$APPLICATION" ]; then usage; fi;

if [ -n "$QUIET" ]; then exec >/dev/null 2>&1; fi

# Determine Where User Config Files Should Go
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
echo "XDG_CONFIG_HOME is \"${XDG_CONFIG_HOME}\""

# Create User Config Home (Should be Unnecessary)
if [ ! -d "${XDG_CONFIG_HOME}" ]; then
  echo "Creating \"${XDG_CONFIG_HOME}\""
  mkdir -p "${XDG_CONFIG_HOME}"
fi

# Determine Where User Cache Should Go
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
echo "XDG_CACHE_HOME is \"${XDG_CACHE_HOME}\""

# Create User Cache Home (Should be Unnecessary)
if [ ! -d "${XDG_CACHE_HOME}" ]; then
  echo "Creating \"${XDG_CACHE_HOME}\""
  mkdir -p "${XDG_CACHE_HOME}"
fi

# Determine Where User Data Files Should Go
export XDG_DATA_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}
echo "XDG_DATA_HOME is \"${XDG_DATA_HOME}\""

# Create User Data Home (Should be Unnecessary)
if [ ! -d "${XDG_DATA_HOME}" ]; then
  echo "Creating \"${XDG_DATA_HOME}\""
  mkdir -p "${XDG_DATA_HOME}"
fi

# Determine Where User State Date Should Go
XDG_STATE_HOME=${XDG_STATE_HOME:-${HOME}/.local/state}
echo "XDG_STATE_HOME is \"${XDG_STATE_HOME}\""

STATE_HOME="$XDG_STATE_HOME/xdg"

# Create User State Home for Launcher
if [ ! -d "${STATE_HOME}" ]; then
  echo "Creating \"${STATE_HOME}\""
  mkdir -p "${STATE_HOME}"
fi

# Register State as in-use
LOCK_FILE="${STATE_HOME}/launcher.lock"
export STATE_FILE="${STATE_HOME}/launcher.data"
echo "Acquiring resource lock..."
flock -x "${LOCK_FILE}" -c "$(declare -f increment_lock); increment_lock"

# Link Xauthority file (Only if it Known to be Necessary)
if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
  # User has XAUTHORITY setting, lets see if it works withough a cludge.
  echo "XXX: NOT temporarily linking your XAUTHORITY file."
  echo "     Please, let the maintainer know if this works."
elif [ -f "${HOME}/.Xauthority" ] && [ ! -f "${XDG_DATA_HOME}/.Xauthority" ]; then
  echo "Linking ~/.Xauthority within \"${XDG_DATA_HOME}\""
  ln -T "${HOME}/.Xauthority" "${XDG_DATA_HOME}/.Xauthority"
fi

# Link User's Cache Home
if [ ! -e "${XDG_DATA_HOME}/.cache" ]; then
  echo "Linking User's Cache Home..."
  ln --symbolic -T "${XDG_CACHE_HOME}" "${XDG_DATA_HOME}/.cache"
fi

# Link User's Config Home
if [ ! -e "${XDG_DATA_HOME}/.config" ]; then
  echo "Linking User's Config Home..."
  ln --symbolic -T "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}/.config"
fi

if [ -n "$QUIET" ]; then exec >&3 2>&4; fi

if [ -z "${FUZZ}" ]; then
  env HOME="${XDG_DATA_HOME}" "$APPLICATION" "$@"
else
  mkdir -p "$(dirname "${FUZZ}")"
  sed "s|:/root:|:${XDG_DATA_HOME}:|" /etc/passwd > "${FUZZ}"
  unshare --user --map-root-user --mount --propagation private sh -c "
    mount --bind \"${FUZZ}\" /etc/passwd
    exec env HOME=\"${XDG_DATA_HOME}\" \"${APPLICATION}\" \"\$@\"
  " _ "$@"
fi
RVAL=$?

if [ -n "$QUIET" ]; then exec >/dev/null 2>&1; fi

echo "Releasing resource lock..."
flock -x "${LOCK_FILE}" -c "$(declare -f decrement_lock); decrement_lock"
if [ $? -gt 0 ]; then
  echo "Resources still in use. Not unlinking."
  exit $RVAL
fi

# Unlink the Xauthority file (Only if it has more than one link)
if [ -f "${XDG_DATA_HOME}/.Xauthority" ]; then
  links=$(stat -c "%h" "${XDG_DATA_HOME}/.Xauthority")
  if [ "$links" -gt 1 ]; then
  echo "Unlinking temporary Xauthority file"
    unlink "${XDG_DATA_HOME}/.Xauthority"
  fi
fi

# Unlink User's Cache Home
if [ -L "${XDG_DATA_HOME}/.cache" ]; then
  echo "Unlinking temporary cache home"
  unlink "${XDG_DATA_HOME}/.cache"
fi

# Unlink User's Config Home
if [ -L "${XDG_DATA_HOME}/.config" ]; then
  echo "Unlinking temporary config home"
  unlink "${XDG_DATA_HOME}/.config"
fi

exit $RVAL
