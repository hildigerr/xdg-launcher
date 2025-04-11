# xdg-launcher
Launcher to enfoce XDG Base Directory compliance for any application.

## Overview

This script is designed to enforce compliance with the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) for applications that do not natively respect the user's XDG settings. By redefining the `HOME` environment variable and temporarily linking necessary files, this script forces applications store their configuration, cache, and data files in the appropriate XDG-defined locations.

## Usage

```
xdg-launch [-cd <directory>] [--fuzz] [--quiet] <application> [-- <options>]
```

### Arguments

-   `-d`, `--dir`, `--cd <directory>`: Specify a working directory for the application. The script will change to this directory before launching the application.
-   `-f`, `--fuzz`: Fuzz the `/etc/passwd` file for applications that ignore environment variables.
-   `--help`, `-h`: Display usage information.
-   `--quiet`, `-q`: Quiet mode to supress launcher messages. The launched application's output is be affected.
-   `<application>`: The application to be launched.
-   `[<options>]`: Additional options or arguments passed to the application.

## How It Works

1.  **Environment Setup**:

    -   The script checks for user's `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, and `XDG_STATE_HOME`.
    -   If they are not already defined, the default values are used.
    -   Missing directories are created, if needed, just in case.

2.  **Resource Useage Registratoin**:

    -   The launcher aquires a mutex lock on the file `$XDG_STATE_HOME/xdg/launcher.lock`.
    -   The quantity of applications using links within the specified `XDG_DATA_HOME` is incremented.
    -   This data is saved within the `$XDG_STATE_HOME/xdg/launcher.data` file.

3.  **Temporary Links**:
    Temporary links to the following items are created within `XDG_DATA_HOME`.

    -   `.cache`
    -   `.config`
    -   `.Xauthority`   

4.  **/etc/passwd Fuzzing** (if enabled):

    -   A copy of the `/etc/passwd` file is created as `/tmp/passwd.fuzz-$USER`
    -   Within the file, the root user's home directory is set to the real user's `XDG_DATA_HOME`.

5.  **Application Launch**:

    -   The working directory will be changed to the specified target directory.
    -   The script redefines the `HOME` environment variable to point to `XDG_DATA_HOME`.
    -   If enabled, a new private namespace is created which overrides `/etc/passwd` with the fuzzed version.
    -   The specified application is launched with its arguments.

6.  **Cleanup After the Application Exits**:

    -   The number of registerd applications is decremented within the `$XDG_STATE_HOME/xdg/launcher.data` file.
    -   Temporary links are removed unless registered as still in use by another application.
    -   Fuzzed passwd files are not removed from the `/tmp` directory, but will be overwritten each time.

## Notes
If you have an `$XAUTHORITY` setting, the `.Xauthority` link will not be made. It is hoped that the setting just works without the cludge. I have not yet been successful in enabling this setting. So, if it works for you or not, please let me know.

