Minecraft Installer for Linux
=============================

Installation script for Minecraft, Technic Pack, and Spoutcraft on Linux.
Tested on Ubuntu Linux 12.10 with Oracle JRE7. Other distributions and JREs
may or may not work. Please report any bugs and/or fixes.

Functionality
-------------

###Summary
* Downloads Minecraft / Technic Pack / Spoutcraft
* Creates shortcut (only tested in Unity)
* Pins shortcut to Unity Launcher (if using Unity)
* Uses NVIDIA Optimus if available

###Detail
* Creates launch script for Minecraft / Technic Pack / Spoutcraft in
  `~/.${BASE_DIR}/launch.sh`
* Adds shell alias for `minecraft` / `technic` / `spout`
* Creates and pins shortcut as detailed in summary
* Determines Java environment automatically, sets `LD_LIBRARY_PATH` in launch
  script to work around a bug that occurs when using JRE7 on 64-bit systems
* Automatically determines memory settings to use - Defaults to initial java
  heap size of 512MB, maximum heap size of half available RAM
* Creates logs in `~/.minecraft` / `~/.technicpack` / `~/.spoutcraft` which
  are populated each time when Minecraft / Technic Pack / Spoutcraft is run

Usage
-----

`./minecraftinst.sh [minecraft|technic|spout]`

The script accepts a single parameter which should dictate which launcher you
want to install. The current options are as follows:
* `minecraft` - Installs [Minecraft](http://minecraft.net/)
* `technic` - Installs [Technic Pack](http://www.technicpack.net/)
* `spout` - Installs [Spoutcraft](http://www.spout.org/)

Configuration
-------------

You should not need to edit any of these by default.

###Memory settings
Change to override defaults, all values are in MB.

<pre>
MIN_MEM         Minimum memory requirement (default 2048 as per docs)
JRE_XMX         Max memory heap size (default is half of total RAM, set to a
                non-null value to override calculation)
JRE_XMS         Initial memory heap size (default 512)
</pre>

###Java enviroment settings
Change to override defaults.

<pre>
JAVA_BIN        Full path to java binary (default is worked out using `which`
                to locate java binary, set a custom path here to override)
JAVA_LIB        Full path to lib folder (default is worked out from the path
                to `java`, set a custom path here to override)
</pre>

###NVIDIA Optimus settings
Advanced - Change to set custom flags to use for `optirun`.

<pre>
OPTIRUN_FLAGS   If your system uses NVIDIA Optimus, it will by used by this
                script. You can specify custom flags to pass to `optirun`
                using this variable.
</pre>

Launchers
---------
The script now supports multiple launchers, as defined by the `LAUNCHERS` array
and following parameter array for each launcher.

###Launcher configuration
There are two parts to defining launchers; the `LAUNCHERS` array, and the
launcher-specific settings arrays.

The `LAUNCHERS` array defines the list of available launchers - These values are
also used as the script parameter options.

The launcher-specific settings arrays must have the same name as their
corresponding entry in the `LAUNCHERS` array, except that the name of the
launcher-specific settings array must be in uppercase. The following fields
are available for each launcher, any optional ones may be left blank by
setting their value to `""`:

1. Display name - The "friendly" name for the launcher, used in places such as
   the shortcut name. Example: `"Spoutcraft"`
1. Base directory - Directory in which to place the jar file for the launcher,
   this should ideally be the same place as where the launcher stores its files.
   Example: `"${HOME}/.spoutcraft"`
1. Jar URL - Full address of the jar file that should be downloaded for the
   launcher. Example: `http://get.spout.org/Spoutcraft.jar`
1. Jar filename - Name to save the jar file as within the base directory.
   Example: `spoutcraft.jar`
1. Shortcut filename - Name to save the shortcut as, this should usually have
   the `.desktop` extension. Example: `spoutcraft.desktop`
1. Icon URL - Full address of the icon to download and use for the shortcut,
   this should be in PNG format. Example: `http://i.imgur.com/xY1MG.png`
1. Custom command - Any custom commands to run in the launcher script before
   running launcher. Example: `touch ${HOME}/.techniclauncher/rtemp` (This
   example prevents Technic Pack from automatically respawning - Without this
   workaround it would not use `optirun`)

###Adding new launchers
There are two steps to adding a new launcher:

1. Add a new entry to the `LAUNCHERS` array,
1. Add a new launcher-specific settings array to define the various options
   for installing the launcher.

Licensing
---------

Copyright 2013 Phasma <phasma@binarycore.org>

All rights reserved.

This work is licensed under the BSD 2-Clause License. To view a copy of this
license, visit http://creativecommons.org/licenses/BSD/.
