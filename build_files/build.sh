#!/bin/bash

set -ouex pipefail

dnf5 copr enable -y bieszczaders/kernel-cachyos-addons

# Adds required package for the scheduler
dnf5 install -y \
    --enablerepo="copr:copr.fedorainfracloud.org:bieszczaders:kernel-cachyos-addons" \
    --allowerasing \
    libcap-ng libcap-ng-devel bore-sysctl cachyos-ksm-settings procps-ng procps-ng-devel uksmd libbpf scx-scheds scx-tools scx-manager cachyos-settings

# Adds the longterm kernel repo
dnf5 copr enable -y bieszczaders/kernel-cachyos

# Remove useless kernels
readarray -t OLD_KERNELS < <(rpm -qa 'kernel-*')
if (( ${#OLD_KERNELS[@]} )); then
    rpm -e --justdb --nodeps "${OLD_KERNELS[@]}"
    dnf5 versionlock delete "${OLD_KERNELS[@]}" || true
    rm -rf /usr/lib/modules/*
    rm -rf /lib/modules/*
fi

# Install kernel packages (noscripts required for 43+)
dnf5 install -y \
    --enablerepo="copr:copr.fedorainfracloud.org:bieszczaders:kernel-cachyos" \
    --allowerasing \
    --setopt=tsflags=noscripts \
    kernel-cachyos-lts \
    kernel-cachyos-lts-devel-matched \
    kernel-cachyos-lts-devel \
    kernel-cachyos-lts-modules \
    kernel-cachyos-lts-core

KERNEL_VERSION="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos-lts)"

# Depmod (required for fedora 43+)
depmod -a "${KERNEL_VERSION}"

# Copy vmlinuz
VMLINUZ_SOURCE="/usr/lib/kernel/vmlinuz-${KERNEL_VERSION}"
VMLINUZ_TARGET="/usr/lib/modules/${KERNEL_VERSION}/vmlinuz"
if [[ -f "${VMLINUZ_SOURCE}" ]]; then
    cp "${VMLINUZ_SOURCE}" "${VMLINUZ_TARGET}"
fi

# Lock kernel packages
dnf5 versionlock add "kernel-cachyos-lts-${KERNEL_VERSION}" || true
dnf5 versionlock add "kernel-cachyos-lts-modules-${KERNEL_VERSION}" || true


# Thank you @renner03 for this part
export DRACUT_NO_XATTR=1
dracut --force \
  --no-hostonly \
  --kver "${KERNEL_VERSION}" \
  --add-drivers "btrfs nvme xfs ext4" \
  --reproducible -v --add ostree \
  -f "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
