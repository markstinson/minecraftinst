Minecraft Installer for Linux
=============================

Installation script for Minecraft on Linux. Tested on Ubuntu Linux 12.10 with
Oracle JRE7.

Functionality
-------------

###Summary
* Downloads Minecraft
* Creates shortcut (only tested in Unity)
* Pins shortcut to Unity Launcher (if using Unity)
* Uses NVIDIA Optimus if available

###Detail
* Creates launch script for Minecraft in `~/.minecraft/minecraft.sh`
* Adds shell alias for `minecraft`
* Creates and pins shortcut as detailed in Summary section
* Determines Java environment automatically, sets `LD_LIBRARY_PATH` in launch
  script to work around a bug that occurs when using JRE7 on 64-bit systems
* Automatically determines memory settings to use - Defaults to initial java
  heap size of 512MB, maximum heap size of half available RAM
* Creates logs in `~/.minecraft` which are populated when Minecraft is run

Usage
-----

`./minecraftinst.sh`

The script does not currently accept any parameters, but you can modify a number
of parameters within the "Configuration" section of the script. The default
values should work fine.

Configuration
-------------

You should not need to edit any of these by default.

###Memory settings
Change to override defaults, all values are in MB.

<pre>
MIN_MEM					Minimum memory requirement (default 2048 as per docs)
JRE_XMX					Max memory heap size (default is half of total RAM, set
						to a non-null value to override calculation)
JRE_XMS					Initial memory heap size (default 512)
</pre>

###Java enviroment settings
Change to override defaults.

<pre>
JAVA_BIN				Full path to java binary (default is worked out using
 						`which` to locate java binary, set a custom path here
 						to override)
JAVA_LIB				Full path to lib folder (default is worked out from the
 						path to `java`, set a custom path here to override)
</pre>

###Advanced script options
Do not change these unless you understand what it is that they do.

<pre>
MINECRAFT_DIR			Directory for Minecraft
MINECRAFT_LOG			Path to STDOUT log, overwritten during each execution
MINECRAFT_ERR_LOG		Path to STDERR log, overwritten during each execution
MINECRAFT_JAR			Location to download/look for launcher
MINECRAFT_SCRIPT		Path to script to launch Minecraft, launch script is
 						created by the current script
MINECRAFT_SHORTCUT		Path for launcher shortcut, this should always be
 						called minecraft.desktop
MINECRAFT_ICON			Path to download icon to and use for shortcut
MINECRAT_ICON_URL		URL to download icon from
OPTIRUN_FLAGS			If your system uses NVIDIA Optimus, it will by used
 						by this script. You can specify custom flags to pass
 						to `optirun` using this variable.
</pre>

Licensing
---------

Copyright 2013 Phasma <phasma@binarycore.org>
All rights reserved.

This work is licensed under the BSD 2-Clause License. To view a copy of this
license, visit http://creativecommons.org/licenses/BSD/.
