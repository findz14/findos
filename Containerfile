# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/fedora/fedora-kinoite:42

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/cachy.sh \
    /ctx/packages.sh

# Enable RPM Fusion (free + nonfree)
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# uBlue derivative with codecs + Steam 32‑bit deps via rpm-ostree

FROM ghcr.io/ublue-os/silverblue-main:latest
# Or kinoite-main/sericea-main, matching your desktop variant

# 1) Get RPM Fusion repo definitions from uBlue's helper image
COPY --from=ghcr.io/ublue-os/rpmfusion:latest /etc/yum.repos.d/rpmfusion*.repo /etc/yum.repos.d/
# If you need patent-encumbered/extra formats, also copy tainted repos:
# COPY --from=ghcr.io/ublue-os/rpmfusion:latest /etc/yum.repos.d/rpmfusion-*-tainted.repo /etc/yum.repos.d/

# 2) Install packages (note: 'vainfo' -> 'libva-utils')
RUN rpm-ostree install \
      # Steam + 32-bit GL stack (you already had these)
      steam \
      mesa-dri-drivers.i686 \
      mesa-libGL.i686 \
      libgcc.i686 \
      libstdc++.i686 \
      \
      # FFmpeg + GStreamer codec families
      ffmpeg \
      gstreamer1-plugins-base \
      gstreamer1-plugins-good \
      gstreamer1-plugins-bad-free \
      gstreamer1-plugins-bad-freeworld \
      gstreamer1-plugins-ugly \
      gstreamer1-libav \
      \
      # VAAPI/VDPAU + utils
      libva \
      libva-utils \        # <-- provides 'vainfo'
      intel-media-driver \
      libva-intel-driver \
      mesa-va-drivers \
      mesa-vdpau-drivers \
      vdpauinfo \
      \
      # Audio extras
      alsa-plugins-pulseaudio \
      pipewire-codec-aptx \
    && rpm-ostree cleanup -m \
    && ostree container commit 



### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
