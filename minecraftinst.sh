#!/bin/bash
#------------------------------------------------------------------------------#
#  Minecraft Installer for Linux                                               #
#  Filename    : minecraftinst.sh                                              #
#  Author      : Phasma <phasma [AT] binarycore [DOT] org>                     #
#  URL         : https://github.com/AtrumPhasma/minecraftinst
#  Description : Script to install Minecraft on Linux. Tested on Ubuntu with   #
#                Oracle JRE7. Other distributions and JREs may or may not      #
#                work. Please report any bugs and/or fixes.                    #
#------------------------------------------------------------------------------#
#  Copyright 2013 Phasma <phasma [AT] binarycore [DOT] org>                    #
#  All rights reserved.                                                        #
#                                                                              #
#  This work is licensed under the BSD 2-Clause License. To view a copy of     #
#  this license, visit http://creativecommons.org/licenses/BSD/.               #
#------------------------------------------------------------------------------#

#- Configuration --------------------------------------------------------------#
# Memory settings (change to override defaults)
# Note: All values are in MB
# VARIABLE				DESCRIPTION
# MIN_MEM				Minimum memory requirement (default 2048 as per docs)
MIN_MEM_REQ="2048"
# JRE_XMX				Max memory heap size (default is half of total RAM, set
#						to a non-null value to override calculation)
JRE_XMX=""
# JRE_XMS				Initial memory heap size (default 512)
JRE_XMS="512"

# Java enviroment settings (change to override defaults)
# VARIABLE				DESCRIPTION
# JAVA_BIN				Full path to java binary (default is worked out using
#						`which` to locate java binary, set a custom path here
#						to override)
JAVA_BIN=""
# JAVA_LIB				Full path to lib folder (default is worked out from the
#						path to `java`, set a custom path here to override)
JAVA_LIB=""

# Advanced script options - Change with caution
# VARIABLE				DESCRIPTION
# MINECRAFT_DIR			Directory for Minecraft
MINECRAFT_DIR="${HOME}/.minecraft"
# MINECRAFT_LOG			Path to STDOUT log, overwritten during each execution
MINECRAFT_LOG="${MINECRAFT_DIR}/minecraft.log"
# MINECRAFT_ERR_LOG		Path to STDERR log, overwritten during each execution
MINECRAFT_ERR_LOG="${MINECRAFT_DIR}/minecraft.err.log"
# MINECRAFT_JAR			Location to download/look for launcher
MINECRAFT_JAR="${MINECRAFT_DIR}/minecraft.jar"
# MINECRAFT_SCRIPT		Path to script to launch Minecraft, launch script is
#						created by the current script
MINECRAFT_SCRIPT="${MINECRAFT_DIR}/minecraft.sh"
# MINECRAFT_SHORTCUT	Path for launcher shortcut, this should always be
#						called minecraft.desktop
MINECRAFT_SHORTCUT="${HOME}/.local/share/applications/minecraft.desktop"
# MINECRAFT_ICON		Path to download icon to and use for shortcut
MINECRAFT_ICON="${MINECRAFT_DIR}/minecraft.png"
# MINECRAT_ICON_URL		URL to download icon from
MINECRAFT_ICON_URL="http://i.imgur.com/HmBUF.png"
# OPTIRUN_FLAGS			If your system uses NVIDIA Optimus, it will by used
#						by this script. You can specify custom flags to pass
#						to `optirun` using this variable.
OPTIRUN_FLAGS=""

#- Functions ------------------------------------------------------------------#
# Precede output messages with timestamp
# Usage   : F_MESSAGE MESSAGE
# Example : F_MESSAGE "Message to output"
F_MESSAGE()
{
	echo "$(date +%T) ${1}"
}

# Output error message before exiting
# Usage   : F_ERR_EXIT [ERROR_MESSAGE] [RC]
# Example : F_ERR_EXIT "Error message" 1
# Notes   : Both parameters are optional
F_ERR_EXIT()
{
	# If error message specified, output it
	if [ -n "${1}" ]
	then
		F_MESSAGE "ERROR : ${1}"
	fi

	# If custom RC is specified and is a number then use it, otherwise exit
	# with RC 1
	if [ -n "${2}" ] && [ "${2}" -eq "${2}" 2>/dev/null ]
	then
		F_MESSAGE "EXITING : returncode ${2}"
		exit "${2}"
	else
		F_MESSAGE "EXITING : returncode 1"
		exit 1
	fi
}

#- Start ----------------------------------------------------------------------#
F_MESSAGE "Starting Minecraft installation"

# Set java binary path using which if not overriden by user
if [ -z ${JAVA_BIN} ]
then
	JAVA_BIN="$(which java)"
fi

# Check if we've got a java binary in our path
if [ ! -x ${JAVA_BIN} ]
then
	F_ERR_EXIT "Java not found, please install before attempting to install Minecraft"
fi

# Work out library path if not overriden by user
if [ -z ${JAVA_LIB} ]
then
	# Get OS bitness and convert to lib path
	case $(uname -m) in
		x86_64) LIB_DIR="lib\/amd64"
				;;
	 i386|i686) LIB_DIR="lib"
				;;
			 *) F_ERR_EXIT "Unsupported architecture"
				;;
	esac
	# Get LIB path by:
	#  1) Reading symlinks to get actual path to java binary (readlink)
	#  2) Getting full directory path that java binary is in (dirname)
	#  3) Replacing "bin" with LIB_DIR as set above (sed)
	JAVA_LIB="$(ls -d $(dirname $(readlink -f ${JAVA_BIN})|sed "s/bin$/${LIB_DIR}/"))"
fi

# Check if java library directory is valid, this is needed to get jre7
# to work correctly on 64-bit systems
if [ ! -d ${JAVA_LIB} ]
then
	F_ERR_EXIT "Unable to locate library path for java"
fi

# Check memory and calculate max (if not overridden)
if [ -z ${JRE_XMX} ]
then
	# If total_ram>=MIN_MEM returns total_ram/2, otherwise returns zero
	JRE_XMX="$(free -m | awk -v min_mem=${MIN_MEM} '$1 ~ /^Mem/ {if($2>=min_mem) print $2/2; else print 0}')"
	if [ "${JRE_XMX}" -eq "0" ]
	then
		F_ERR_EXIT "Insufficient RAM, less than MIN_MEM value of ${MIN_MEM}"
	fi
fi

# Check if we've got minecraft.jar, download if we haven't
if [ ! -f ${MINECRAFT_JAR} ]
then
	F_MESSAGE "Downloading minecraft.jar..."
	mkdir -p ${MINECRAFT_DIR} || F_ERR_EXIT "Unable to create ${MINECRAFT_DIR}"
	# Get URL to minecraft.jar
	MINECRAFT_JAR_URL="$(wget -qO- http://minecraft.net/download | sed -n 's/.*"\([a-zA-Z0-9:./].*minecraft.jar\)".*/\1/p')"
	# Download minecraft.jar
	wget -nv -P ${MINECRAFT_DIR} ${MINECRAFT_JAR_URL} || F_ERR_EXIT "Unable to download minecraft.jar, please check connectivity and try again later"
fi

# Check if we're on a system that uses NVIDIA Optimus
if [ -x $(which optirun) ]
then
	# Needs a trailing space
	OPTIRUN_CMD="$(which optirun) ${OPTIRUN_FLAGS} "
else
	OPTIRUN_CMD=""
fi

# Minecraft launch command
MINECRAFT_RUN="${OPTIRUN_CMD}${JAVA_BIN} -Xmx${JRE_XMX}M -Xms${JRE_XMS}M -cp ${MINECRAFT_JAR} net.minecraft.LauncherFrame 1>${MINECRAFT_LOG} 2>${MINECRAFT_ERR_LOG}"

# Create launcher script
tee<<EOF>${MINECRAFT_SCRIPT}
#!/bin/bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${JAVA_LIB}
${MINECRAFT_RUN}
EOF
# Set permissions
chmod u+x ${MINECRAFT_SCRIPT}

# Create shortcut, remove if applicable
# 1. Download icon if we don't have it
if [ ! -f ${MINECRAFT_ICON} ]
then
	F_MESSAGE "Downloading Minecraft icon..."
	# Attempt to download icon, delete dummy file and exit with error if fails
	wget -nv -O ${MINECRAFT_ICON} ${MINECRAFT_ICON_URL} || F_ERR_EXIT "$(rm -f ${MINECRAFT_ICON} 1>/dev/null 2>&1) Unable to download Minecraft icon, please check connectivity and try again later"
fi

# 2. Unpin first (if Unity is in use)
if [ "$(ps -ef | awk '$NF ~ /unity-panel-service$/ {print 1}')" -eq "1" ]
then
	# Check if shortcut is currently pinned
	if [ "$(gsettings get com.canonical.Unity.Launcher favorites|grep -c "minecraft.desktop")" -gt "0" ]
	then
		# If it is, unpin it
		F_MESSAGE "Unpinning current shortcut from Launcher"
		gsettings set com.canonical.Unity.Launcher favorites "$(gsettings get com.canonical.Unity.Launcher favorites|sed "s%, 'application://minecraft.desktop'%%g")"
	fi
fi

# 3. Delete existing shortcut (if exists)
if [ -f ${MINECRAFT_SHORTCUT} ]
then
	F_MESSAGE "Deleting current shortcut"
	/bin/rm -f ${MINECRAFT_SHORTCUT} 1>/dev/null 2>&1
	sleep 1
fi

# 4. Add alias to RC file if file is writable
RCFILE="${HOME}/.bashrc"
if [ -w ${RCFILE} ]
then
	# Check if alias already in place
	if [ "$(grep -c "alias minecraft=" ${RCFILE})" -eq "0" ]
	then
		# No alias in place, creating...
		F_MESSAGE "Creating \"minecraft\" shell alias"
		tee<<EOF>>${RCFILE}

# Alias to Minecraft launch script, added by minecraftinst
alias minecraft='${MINECRAFT_SCRIPT} &'
EOF
	else
		F_MESSAGE "\"minecraft\" alias shell exists, skipping"
	fi
fi

# 5. Create shortcut
F_MESSAGE "Creating shortcut"

# Make shortcut folder if it doesn't exist
MINECRAFT_SHORTCUT_DIR="$(dirname ${MINECRAFT_SHORTCUT})"
mkdir -p ${MINECRAFT_SHORTCUT_DIR} || F_ERR_EXIT "Unable to create ${MINECRAFT_SHORTCUT_DIR}"

# Create shortcut file
tee<<EOF>${MINECRAFT_SHORTCUT}
[Desktop Entry]
Version=1.0
Name=Minecraft
Exec=${MINECRAFT_SCRIPT}
Icon=${MINECRAFT_ICON}
Terminal=false
Type=Application
Categories=Game;
EOF

# Grant user execute on shortcut
chmod u+x ${MINECRAFT_SHORTCUT}

# 6. Pin shortcut (if Unity is in use)
if [ "$(ps -ef | awk '$NF ~ /unity-panel-service$/ {print 1}')" -eq "1" ]
then
	# Pin to bar
	F_MESSAGE "Pinning shortcut to Launcher"
	gsettings set com.canonical.Unity.Launcher favorites "$(gsettings get com.canonical.Unity.Launcher favorites|sed "s%]%, 'application://minecraft.desktop']%")"
fi

F_MESSAGE "Completed"
#- EOF ------------------------------------------------------------------------#
