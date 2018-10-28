#!/usr/bin/env bash

# Copyright (C) Harsh Shandilya <msfjarvis@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# Source common functions
SCRIPT_DIR="$(cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd)"
source "${SCRIPT_DIR}"/common
git -C "${SCRIPT_DIR}" submodule update --init --recursive

declare -a SCRIPTS=("kronic-build" "build-caesium" "build-kernel" "build-twrp" "hastebin")
declare -a TDM_SCRIPTS=("gerrit-review")
declare -a GPG_KEYS=("public_old.asc" "private_old.asc")

mkdir -p ~/bin/

echoText "Installing necessary packages"
sudo apt install -y android-tools-adb jq curl wget axel mosh xclip aria2

echoText "Checking and installing hub"
HUB="$(command -v hub)"
if [[ "${HUB}" == "" || "$*" =~ --update-binaries ]]; then
    HUB_ARCH=linux-amd64
    aria2c "$(get_release_assets github/hub | grep ${HUB_ARCH})" -o hub.tgz
    mkdir -p hub
    tar -xf hub.tgz -C hub
    sudo ./hub/*/install --prefix=/usr/local/
    rm -rf hub/ hub.tgz
else
    reportWarning "$(hub --version) is already installed!"
fi

echoText "Checking and installing gdrive"
GDRIVE="$(command -v gdrive)"
if [ "${GDRIVE}" == "" ]; then
    GDRIVE_ARTIFACT_NAME="gdrive-linux-x64"
    aria2c "$(get_release_assets MSF-Jarvis/gdrive | grep ${GDRIVE_ARTIFACT_NAME})" -o ~/bin/gdrive
    chmod +x ~/bin/gdrive
else
    reportWarning "gdrive is already installed!"
fi

echoText "Installing 'diff-so-fancy'"
DIFF_SO_FANCY="$(command -v diff-so-fancy)"
if [[ "${DIFF_SO_FANCY}" == "" ]]; then
    sudo aria2c 'https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy' -o /usr/local/bin/diff-so-fancy
    sudo chmod +x /usr/local/bin/diff-so-fancy
else
    INSTALLED_VERSION="$(grep "my \$VERSION = " /usr/local/bin/diff-so-fancy | cut -d \" -f 2)"
    LATEST_VERSION="$(get_latest_release so-fancy/diff-so-fancy | sed 's/v//')"
    if [[ "${INSTALLED_VERSION}" != "${LATEST_VERSION}" ]]; then
        sudo aria2c 'https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy' -o /usr/local/bin/diff-so-fancy
        sudo chmod +x /usr/local/bin/diff-so-fancy
    fi
fi
unset DIFF_SO_FANCY

echoText "Importing GPG keys"
for KEY in "${GPG_KEYS[@]}"; do
    gpg --import "${SCRIPT_DIR}"/gpg_keys/"${KEY}"
done

echoText "Moving credentials"
gpg --decrypt "${SCRIPT_DIR}"/.secretcreds.gpg > ~/.secretcreds

# SC2076: Don't quote rhs of =~, it'll match literally rather than as a regex.
# SC2088: Note that ~ does not expand in quotes.
# shellcheck disable=SC2076,SC2088
if [[ ! "${PATH}" =~ "~/bin" ]]; then
    reportWarning "~/bin is not in PATH, appending the export to bashrc"
    echo $'\nexport PATH="~/bin":$PATH' >> ~/.bashrc
fi

ret="$(grep -q "source ${SCRIPT_DIR}/functions" ~/.bashrc)"
if [[ "${ret}" ]]; then
    reportWarning "functions is not sourced in the bashrc, appending"
    echo "source ${SCRIPT_DIR}/functions" >> ~/.bashrc
fi

echoText "Installing scripts"
for SCRIPT in "${SCRIPTS[@]}"; do
    echo -e "${CL_YLW}Processing ${SCRIPT}${CL_RST}"
    rm -rf ~/bin/"${SCRIPT}"
    ln -s "${SCRIPT_DIR}"/"${SCRIPT}" ~/bin/"${SCRIPT}"
done

echoText "Setting up tdm-scripts"
for SCRIPT in "${TDM_SCRIPTS[@]}"; do
    echo -e "${CL_YLW}Processing ${SCRIPT}${CL_RST}"
    cp "${SCRIPT_DIR}"/tdm-scripts/"${SCRIPT}" ~/bin/"${SCRIPT}"
done

echoText "Setting up gitconfig"
mv ~/.gitconfig ~/.gitconfig.old 2>/dev/null # Failsafe in case we screw up
cp "${SCRIPT_DIR}/.gitconfig" ~/.gitconfig
# SC2044: For loops over find output are fragile. Use find -exec or a while read loop.
# Disabling until I have a better idea
# shellcheck disable=SC2044
for ITEM in $(find gitconfig_fragments -type f); do
    DECRYPTED="${ITEM/.gpg/}"
    rm -f "${DECRYPTED}" 2>/dev/null
    gpg --decrypt "${ITEM}" > "${DECRYPTED}"
    [[ ! -f "${DECRYPTED}" ]] && break
    cat "${DECRYPTED}" >> ~/.gitconfig
    rm "${DECRYPTED}"
done

if [[ "$*" =~ --setup-adb || "$*" =~ --all ]]; then
    echoText "Setting up multi-adb"
    "${SCRIPT_DIR}"/adb-multi/adb-multi generate
    cp "${SCRIPT_DIR}"/adb-multi/adb-multi ~/bin
fi
