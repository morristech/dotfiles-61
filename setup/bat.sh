#!/usr/bin/env bash

# Copyright (C) Harsh Shandilya <msfjarvis@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

source "${SCRIPT_DIR}"/common
source "${SCRIPT_DIR}"/gitshit

function install_bat {
    local BAT
    echoText "Checking and installing bat"
    BAT="$(command -v bat)"
    if [ "${BAT}" == "" ]; then
        BAT_ARTIFACT=x86_64-unknown-linux-gnu.tar.gz
        aria2c "$(get_release_assets sharkdp/bat | grep ${BAT_ARTIFACT})" -o bat.tgz
        mkdir -p bat
        tar -xf bat.tgz -C bat/
        cd bat/*/ || return 1
        sudo install bat /usr/local/bin
        sudo install bat.1 /usr/local/man/
        cd "${SCRIPT_DIR}" || return 1
        rm -rf bat/ bat.tgz
    else
        reportWarning "$(bat --version) is already installed!"
    fi
}

install_bat
