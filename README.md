# QFUbuntu

Ubuntu 24.04.5 LTS (arm64) rootfs packed inside an iOS App.

## Features
- Full Ubuntu 24.04.5 arm64 rootfs (~124MB compressed, ~377MB unpacked)
- Pre-installed toolchain:
  - gcc 13.2.0 / g++ 13.2.0
  - python 3.12.3
  - make 4.3 / git / curl / wget / nano / cpp
- Boots directly in jailbroken environment with `chroot`.

## Build
Pushed automatically via GitHub Actions (macOS runner builds Mach-O + creates signed IPA).
Download the generated `QFUbuntu.ipa` from the Actions artifacts.
