#!/bin/bash
#------------------------------------------------------------------------------#
#  Minecraft Installer for Linux                                               #
#  Filename    : minecraftinst.sh                                              #
#  Author      : Akythius <akythius [AT] binarycore [DOT] org>                 #
#  URL         : https://github.com/Akythius/minecraftinst                     #
#  Description : Script to install Minecraft, Technic Pack, and Spoutcraft on  #
#                Linux. Tested on Ubuntu with Oracle JRE7. Other distributions #
#                and JREs may or may not work. Please report any bugs and/or   #
#                fixes.                                                        #
#------------------------------------------------------------------------------#
#  Copyright 2013 Akythius <akythius [AT] binarycore [DOT] org>                #
#  All rights reserved.                                                        #
#                                                                              #
#  This work is licensed under the BSD 2-Clause License. To view a copy of     #
#  this license, visit http://creativecommons.org/licenses/BSD/.               #
#------------------------------------------------------------------------------#

#- Configuration --------------------------------------------------------------#
# Memory settings, change to override defaults. All values are in MB.
#  MIN_MEM          Minimum memory requirement (default 2048 as per docs)
MIN_MEM_REQ="2048"
#  JRE_XMX          Max memory heap size (default is half of total RAM, set
#                   to a non-null value to override calculation)
JRE_XMX=""
#  JRE_XMS          Initial memory heap size (default 512)
JRE_XMS="512"

# Java enviroment settings (change to override defaults)
#  JAVA_BIN         Full path to java binary (default is worked out using
#                   `which` to locate java binary, set a custom path here
#                   to override)
JAVA_BIN=""
#  JAVA_LIB         Full path to lib folder (default is worked out from the
#                   path to `java`, set a custom path here to override)
JAVA_LIB=""

# NVIDIA Optimus settings
#  OPTIRUN_FLAGS    If your system uses NVIDIA Optimus, it will by used
#                   by this script. You can specify custom flags to pass
#                   to `optirun` using this variable.
OPTIRUN_FLAGS=""

#- Launchers ------------------------------------------------------------------#
# Define supported launchers
LAUNCHERS=("minecraft" "technic" "spout")

# Define options for supported launchers, name must be uppercase version of
# corresponding entry in LAUNCHERS array. Format is as follows:
#   Display name, base directory, JAR URL, JAR filename, shortcut filename,
#   icon URL, custom command[s] to execute before launching.
MINECRAFT=("Minecraft" "${HOME}/.minecraft" "https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft.jar" "minecraft.jar" "minecraft.desktop" "http://i.imgur.com/HmBUF.png" "")
TECHNIC=("Technic Pack" "${HOME}/.techniclauncher" "http://mirror.technicpack.net/Technic/technic-launcher.jar" "technic-launcher.jar" "techniclauncher.desktop" "http://i.imgur.com/SObea.png" "touch ${HOME}/.techniclauncher/rtemp")
SPOUT=("Spoutcraft" "${HOME}/.spoutcraft" "http://get.spout.org/Spoutcraft.jar" "spoutcraft.jar" "spoutcraft.desktop" "http://i.imgur.com/xY1MG.png" "")

# Launcher notes:
#   Technic
#     The custom command for technic is a workaround to allow optirun to be
#     used, all credit for this goes to dreadslicer on the Technic Forums:
#     http://preview.tinyurl.com/byqywsg

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
# Check parameter passed and convert to lowercase
LAUNCHER="${1,,}"

# Check if option passed is valid
if [ "$(echo ${LAUNCHERS[*]} | grep -E -c -w "\<${LAUNCHER}\>")" -eq "1" ]
then
    PARAM_ARRAY_NAME="${LAUNCHER^^}[@]"
    PARAMETERS=("${!PARAM_ARRAY_NAME}")
else
    F_MESSAGE "Usage : ${0} [$(echo ${LAUNCHERS[*]} | sed 's/ /|/g')]"
    exit 1
fi

# Set parameters for chosen launcher
DISPLAY_NAME="${PARAMETERS[0]}"
BASE_DIR="${PARAMETERS[1]}"
JAR_URL="${PARAMETERS[2]}"
JAR_NAME="${PARAMETERS[3]}"
JAR_PATH="${BASE_DIR}/${JAR_NAME}"
SHORTCUT_FILENAME="${PARAMETERS[4]}"
SHORTCUT_PATH="${HOME}/.local/share/applications/${SHORTCUT_FILENAME}"
ICON_URL="${PARAMETERS[5]}"
LAUNCH_SCRIPT="${BASE_DIR}/launch.sh"
CUSTOM_COMMANDS="${PARAMETERS[6]}"

# Start installation
F_MESSAGE "Starting ${DISPLAY_NAME} installation"

# Set java binary path using which if not overriden by user
if [ -z ${JAVA_BIN} ]
then
    JAVA_BIN="$(which java)"
fi

# Check if we've got a java binary in our path
if [ ! -x ${JAVA_BIN} ]
then
    F_ERR_EXIT "Java not found, please install before attempting to install ${DISPLAY_NAME}"
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

# Check if we've got jar, download if we haven't
if [ ! -f ${JAR_PATH} ]
then
    F_MESSAGE "Downloading ${JAR_NAME}..."
    mkdir -p ${BASE_DIR} || F_ERR_EXIT "Unable to create ${BASE_DIR}"
    # Download jar file
    wget -nv -O ${JAR_PATH} ${JAR_URL} || F_ERR_EXIT "Unable to download ${JAR_NAME}, please check connectivity and try again later"
fi

# Check if we're on a system that uses NVIDIA Optimus
if [ -x $(which optirun) ]
then
    # Needs a trailing space
    OPTIRUN_CMD="$(which optirun) ${OPTIRUN_FLAGS} "
else
    OPTIRUN_CMD=""
fi

# Generate launch command
LAUNCHER_RUN="${OPTIRUN_CMD}${JAVA_BIN} -Xmx${JRE_XMX}M -Xms${JRE_XMS}M -jar ${JAR_PATH} 1>${BASE_DIR}/run.log 2>${BASE_DIR}/error.log"

# Create launcher script
tee<<EOF>${LAUNCH_SCRIPT}
#!/bin/bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${JAVA_LIB}
${CUSTOM_COMMANDS}
${LAUNCHER_RUN}
EOF
# Set permissions
chmod u+x ${LAUNCH_SCRIPT}

# Create shortcut, remove if applicable
# 1. Download icon if we don't have it
LAUNCHER_ICON="${BASE_DIR}/icon.png"
if [ ! -f ${LAUNCHER_ICON} ]
then
    F_MESSAGE "Downloading icon for ${DISPLAY_NAME}..."
    # Attempt to download icon, delete dummy file and exit with error if fails
    wget -nv -O ${LAUNCHER_ICON} ${ICON_URL} || F_ERR_EXIT "$(rm -f ${LAUNCHER_ICON} 1>/dev/null 2>&1) Unable to download ${DISPLAY_NAME} icon, please check connectivity and try again later"
fi

# 2. Unpin first (if Unity is in use)
if [ "$(ps -ef | awk '$NF ~ /unity-panel-service$/ {print 1}')" -eq "1" ]
then
    # Check if shortcut is currently pinned
    if [ "$(gsettings get com.canonical.Unity.Launcher favorites|grep -c "${SHORTCUT_FILENAME}")" -gt "0" ]
    then
        # If it is, unpin it
        F_MESSAGE "Unpinning current shortcut from Launcher"
        gsettings set com.canonical.Unity.Launcher favorites "$(gsettings get com.canonical.Unity.Launcher favorites|sed "s%, 'application://${SHORTCUT_FILENAME}'%%g")"
    fi
fi

# 3. Delete existing shortcut (if exists)
if [ -f ${SHORTCUT_PATH} ]
then
    F_MESSAGE "Deleting current shortcut"
    /bin/rm -f ${SHORTCUT_PATH} 1>/dev/null 2>&1
    sleep 1
fi

# 4. Add alias to RC file if file is writable
RCFILE="${HOME}/.bashrc"
if [ -w ${RCFILE} ]
then
    # Check if alias already in place
    if [ "$(grep -c "alias ${LAUNCHER}=" ${RCFILE})" -eq "0" ]
    then
        # No alias in place, creating...
        F_MESSAGE "Creating \"${LAUNCHER}\" shell alias"
        tee<<EOF>>${RCFILE}

# Alias to ${DISPLAY_NAME} launch script, added by Minecraft Installer for Linux
alias ${LAUNCHER}='${LAUNCH_SCRIPT} &'
EOF
    else
        F_MESSAGE "\"${LAUNCHER}\" alias shell exists, skipping"
    fi
fi

# 5. Create shortcut
F_MESSAGE "Creating shortcut"

# Make shortcut folder if it doesn't exist
SHORTCUT_DIR="$(dirname ${SHORTCUT_PATH})"
mkdir -p ${SHORTCUT_DIR} || F_ERR_EXIT "Unable to create ${SHORTCUT_DIR}"

# Create shortcut file
tee<<EOF>${SHORTCUT_PATH}
[Desktop Entry]
Version=1.0
Name=${DISPLAY_NAME}
Exec=${LAUNCH_SCRIPT}
Icon=${LAUNCHER_ICON}
Terminal=false
Type=Application
Categories=Game;
EOF

# Grant user execute on shortcut
chmod u+x ${SHORTCUT_PATH}

# 6. Pin shortcut (if Unity is in use)
if [ "$(ps -ef | awk '$NF ~ /unity-panel-service$/ {print 1}')" -eq "1" ]
then
    # Pin to bar
    F_MESSAGE "Pinning shortcut to Launcher"
    gsettings set com.canonical.Unity.Launcher favorites "$(gsettings get com.canonical.Unity.Launcher favorites|sed "s%]%, 'application://${SHORTCUT_FILENAME}']%")"
fi

F_MESSAGE "Completed"
#- EOF ------------------------------------------------------------------------#
