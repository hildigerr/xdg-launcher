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

usage() { echo "Usage: $0 [-cd <directory>] [--fuzz] application> [-- options]"; exit; }

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
    --fuzz|-f) FUZZ="$1";;
    --help|-h) useage;;
    --) shift; break;;
    *) if [ -z "$APPLICATION" ]; then APPLICATION="$1"; else usage; fi;;
  esac
  shift
done
if [ -z "$APPLICATION" ]; then usage; fi;

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
XDG_DATA_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}
echo "XDG_DATA_HOME is \"${XDG_DATA_HOME}\""

# Create User Data Home (Should be Unnecessary)
if [ ! -d "${XDG_DATA_HOME}" ]; then
  echo "Creating \"${XDG_DATA_HOME}\""
  mkdir -p "${XDG_DATA_HOME}"
fi

# Link Xauthority file (Only if it Known to be Necessary)
if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
  # User has XAUTHORITY setting, lets see if it works withough a cludge.
  echo "XXX: NOT temporarily linking your XAUTHORITY file."
  echo "     Please, let the maintainer know if this works."
elif [ -f "${HOME}/.Xauthority" ] && [ ! -f "${XDG_DATA_HOME}/.Xauthority" ]; then
  echo "Linking ~/.Xauthority within \"${XDG_DATA_HOME}\""
  ln -T "${HOME}/.Xauthority" "${XDG_DATA_HOME}/.Xauthority"
else
  # Unknown handling of XAUTHORITY, lets see if it is needed.
  echo "XXX: NOT temporarily linking your XAUTHORITY file."
  echo "     Please, let the maintainer know if you have any issues."
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

if [ -z "${FUZZ}" ]; then
  env HOME="${XDG_DATA_HOME}" "$APPLICATION" "$@"
else
  sed "s|:/root:|:${XDG_DATA_HOME}:|" /etc/passwd > "/tmp/passwd.fuz-${USER}"
  unshare --user --map-root-user --mount --propagation private sh -c "
    mount --bind /tmp/passwd.fuz-${USER} /etc/passwd
    exec env HOME=\"${XDG_DATA_HOME}\" \"${APPLICATION}\" \"\$@\"
  " _ "$@"
fi
RVAL=$?

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
