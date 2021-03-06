#!/usr/bin/env bash

# Copyright (C) Harsh Shandilya <msfjarvis@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

source "${SCRIPT_DIR}"/common
source "${SCRIPT_DIR}"/gitshit

function install_hub {
    local INSTALLED_VERSION HUB HUB_ARCH
    echoText "Checking and installing hub"
    HUB="$(command -v hub)"
    HUB_ARCH=linux-amd64
    if [ "${HUB}" == "" ]; then
        aria2c "$(get_release_assets github/hub | grep ${HUB_ARCH})" -o hub.tgz
        mkdir -p hub
        tar -xf hub.tgz -C hub
        sudo ./hub/*/install --prefix=/usr/local/
        rm -rf hub/ hub.tgz
    else
        INSTALLED_VERSION="v$(hub --version | tail -n1 | awk '{print $3}')"
        LATEST_VERSION="$(get_latest_release github/hub)"
        if [ "${INSTALLED_VERSION}" != "${LATEST_VERSION}" ]; then
            reportWarning "Outdated version of hub detected, upgrading"
            aria2c "$(get_release_assets github/hub | grep ${HUB_ARCH})" -o hub.tgz
            mkdir -p hub
            tar -xf hub.tgz -C hub
            sudo ./hub/*/install --prefix=/usr/local/
            rm -rf hub/ hub.tgz
        else
            reportWarning "hub ${INSTALLED_VERSION} is already installed!"
        fi
    fi
}

install_hub
