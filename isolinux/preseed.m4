# Ubuntu Preseed Configuration (M4 Template)
# This file is processed by M4 to generate preseed.cfg
# Usage: m4 -I . -D PACKAGE_VERSION=1.0 preseed.m4 > preseed.cfg

# ============================================================================
# Localization
# ============================================================================

# Language and country
d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/splash boolean false
d-i localechooser/supported-locales multiselect en_US.UTF-8

# Keyboard configuration
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/layoutcode string us

# ============================================================================
# Network Configuration
# ============================================================================

# Network interface (auto-detect)
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ubuntu
d-i netcfg/get_domain string local

# Static network configuration (uncomment and modify if needed)
#d-i netcfg/get_ipaddress string 192.168.1.100
#d-i netcfg/get_netmask string 255.255.255.0
#d-i netcfg/get_gateway string 192.168.1.1
#d-i netcfg/get_nameservers string 8.8.8.8 8.8.4.4
#d-i netcfg/confirm_static boolean true

# Or use DHCP
d-i netcfg/dhcp_options select Configure network manually

# ============================================================================
# Mirror Settings
# ============================================================================

# Use CD-ROM as primary source
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string

# ============================================================================
# Clock and Timezone
# ============================================================================

d-i clock-setup/utc boolean true
d-i time/zone string America/New_York
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string pool.ntp.org

# ============================================================================
# Partitioning
# ============================================================================

# Use entire disk with LVM
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

# Partitioning scheme
d-i partman-auto/expert_recipe string \
    boot-root :: \
        512 512 512 ext4 \
            $primary{ } $bootable{ } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ /boot } \
        . \
        1024 1024 1024 swap \
            $lvmok{ } \
            lv_name{ swap } \
            method{ swap } format{ } \
        . \
        10240 10240 -1 ext4 \
            $lvmok{ } \
            lv_name{ root } \
            method{ format } format{ } \
            use_filesystem{ } filesystem{ ext4 } \
            mountpoint{ / } \
        .

d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# ============================================================================
# User Account Setup
# ============================================================================

# Root password (WARNING: Use hashed password in production!)
# Generate hash: mkpasswd -m sha-512
d-i passwd/root-login boolean false
d-i passwd/make-user boolean true
d-i passwd/user-fullname string HAMLE User
d-i passwd/username string hamle
d-i passwd/user-password-crypted password $6$rounds=4096$salt$hashedpassword
# Or use plaintext (NOT RECOMMENDED for production):
#d-i passwd/user-password password changeme
#d-i passwd/user-password-again string changeme

# User should be in sudo group
d-i user-setup/allow-password-weak boolean false
d-i user-setup/encrypt-home boolean false

# ============================================================================
# Package Installation
# ============================================================================

# Install base system
tasksel tasksel/first multiselect standard, ubuntu-server
d-i pkgsel/update-policy select none
d-i pkgsel/upgrade select none

# Additional packages to install
d-i pkgsel/include string \
    vim \
    curl \
    wget \
    git \
    build-essential \
    htop \
    openssh-server \
    net-tools

# ============================================================================
# Boot Loader
# ============================================================================

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

# ============================================================================
# Finishing Up
# ============================================================================

# Reboot after installation
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean false
d-i debian-installer/exit/halt boolean false

# ============================================================================
# Late Command (Post-Installation Scripts)
# ============================================================================

# Run commands after installation completes
d-i preseed/late_command string \
    in-target sh -c 'echo "Package Version: PACKAGE_VERSION" > /etc/hamle-version'; \
    in-target sh -c 'echo "Installation Date: $(date)" >> /etc/hamle-version'; \
    in-target apt-get update; \
    in-target apt-get install -y $(pkgsel/include)

# ============================================================================
# Optional: Custom Scripts
# ============================================================================

# Uncomment to run custom script from ISO
#d-i preseed/late_command string \
#    cp /cdrom/preseed/custom-script.sh /target/tmp/; \
#    chmod +x /target/tmp/custom-script.sh; \
#    in-target /tmp/custom-script.sh

