#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf -y copr enable ublue-os/packages
dnf5 install -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages --skip-unavailable \
    #libvirt \
    #ublue-os-libvirt-workarounds
    # edk2-ovmf \
    # genisoimage \
    # libvirt-nss \
    # virt-manager \
    # virt-v2v \
    # qemu-char-spice \
    # qemu-device-display-virtio-gpu \
    # qemu-device-display-virtio-vga \
    # qemu-device-usb-redirect \
    # qemu-img \
    # qemu-system-x86-core \
    # qemu-user-binfmt \
    # qemu-user-static

dnf5 install steam

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
