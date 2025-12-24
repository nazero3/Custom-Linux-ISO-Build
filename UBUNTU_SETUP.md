# Ubuntu ISO Customization Setup Guide

This guide explains all the files and steps needed to customize an Ubuntu installation ISO.

## Required Files and Directory Structure

```
project-root/
├── Makefile                 # Main build script
├── isolinux/                # Boot configuration files
│   ├── preseed.m4          # Automated installation template (M4)
│   ├── preseed.cfg         # Generated preseed file (optional, if not using M4)
│   ├── grub.cfg            # GRUB configuration for UEFI boot
│   ├── isolinux.cfg        # ISOLinux config for legacy BIOS boot
│   ├── txt.cfg             # Text mode installation menu
│   ├── loopback.cfg        # GRUB loopback configuration
│   └── splash.jpg          # Boot splash screen (optional)
├── ubuntu-iso/             # Source Ubuntu ISO files
│   └── ubuntu-*-server-amd64.iso
├── custom-debs/            # Custom DEB packages
│   └── *.deb               # Your custom packages
└── BUILD/                  # Build output directory (created automatically)
    └── *.iso               # Final custom ISO
```

## Key Files Explained

### 1. `preseed.m4` (or `preseed.cfg`)

**Purpose:** Automated installation configuration (like kickstart for RHEL)

**What it does:**
- Configures language, keyboard, timezone
- Sets up network (DHCP or static)
- Defines partitioning scheme
- Creates user accounts
- Installs packages
- Runs post-installation scripts

**Key sections:**
- `d-i debian-installer/language` - Language settings
- `d-i netcfg/choose_interface` - Network configuration
- `d-i partman-auto/method` - Partitioning method
- `d-i passwd/user-fullname` - User account setup
- `d-i pkgsel/include` - Packages to install
- `d-i preseed/late_command` - Post-install scripts

**M4 Template Variables:**
- `PACKAGE_VERSION` - Set via Makefile, used in preseed.m4

**Example usage:**
```bash
# Generate preseed.cfg from template
m4 -I isolinux -D PACKAGE_VERSION=1.0 isolinux/preseed.m4 > isolinux/preseed.cfg
```

### 2. `grub.cfg`

**Purpose:** GRUB boot menu for UEFI systems

**What it does:**
- Defines boot menu entries
- Sets timeout and default selection
- Configures graphics and themes
- Points to kernel and initrd

**Key entries:**
- `Install Ubuntu Server` - Automated install with preseed
- `Install Ubuntu Server (Manual)` - Interactive install
- `Try Ubuntu without installing` - Live mode

**Important parameters:**
- `autoinstall` - Enable automated installation
- `ds=nocloud\;s=/cdrom/preseed/` - Point to preseed directory
- `/casper/vmlinuz` - Kernel location (Ubuntu 20.04+)
- `/casper/initrd` - Initrd location

### 3. `isolinux.cfg`

**Purpose:** Boot menu for legacy BIOS systems

**What it does:**
- Provides menu for BIOS-based computers
- Same functionality as grub.cfg but for BIOS
- Uses ISOLinux bootloader

**Key differences from GRUB:**
- Uses `LABEL` instead of `menuentry`
- Uses `KERNEL` and `APPEND` instead of `linux` and `initrd`
- Located in `/isolinux/` directory on ISO

### 4. `txt.cfg`

**Purpose:** Text-based installation menu (fallback)

**What it does:**
- Provides text menu when graphics aren't available
- Same boot options as isolinux.cfg
- Used as fallback

### 5. `loopback.cfg`

**Purpose:** Allows booting ISO from within GRUB

**What it does:**
- Enables booting ISO from hard disk via GRUB
- Useful for network boot or PXE scenarios
- Uses loopback device to mount ISO

## Step-by-Step Setup

### Step 1: Prepare Source ISO

```bash
# Download Ubuntu Server ISO
# Place it in ubuntu-iso/ directory
# Example: ubuntu-iso/ubuntu-22.04-server-amd64.iso
```

### Step 2: Create Directory Structure

```bash
mkdir -p isolinux
mkdir -p ubuntu-iso
mkdir -p custom-debs
```

### Step 3: Configure Preseed

Edit `isolinux/preseed.m4`:
- Set your timezone
- Configure network (DHCP or static IP)
- Define partitioning scheme
- Set user account details
- List packages to install
- Add post-installation commands

**Generate password hash:**
```bash
# Install whois package
sudo apt-get install whois

# Generate hashed password
mkpasswd -m sha-512
# Enter your password, copy the hash
# Use in preseed.m4: d-i passwd/user-password-crypted password $6$...
```

### Step 4: Customize Boot Menus

Edit boot configuration files:
- `isolinux/grub.cfg` - UEFI boot menu
- `isolinux/isolinux.cfg` - BIOS boot menu
- `isolinux/txt.cfg` - Text mode menu

**Key things to customize:**
- Menu titles and labels
- Default boot option
- Timeout values
- Kernel parameters

### Step 5: Add Custom Packages (Optional)

```bash
# Place your DEB packages in custom-debs/
cp your-package.deb custom-debs/
```

### Step 6: Build the ISO

```bash
# Build complete ISO
make all

# Or step by step
make create-build-env
make iso-copy-disc
make iso-packages
make iso-update-boot-config
make iso-assemble
make iso-md5
```

### Step 7: Test the ISO

```bash
# Test in virtual machine
qemu-system-x86_64 -cdrom BUILD/your-iso.iso -m 2048

# Or use VirtualBox/VMware
```

## Important Differences from RHEL/Rocky

### Package Management
- **Ubuntu:** Uses `apt-get` and `.deb` packages
- **RHEL:** Uses `yum/dnf` and `.rpm` packages

### Automated Installation
- **Ubuntu:** Uses `preseed` files
- **RHEL:** Uses `kickstart` files

### Boot System
- **Ubuntu:** Primarily GRUB, ISOLinux for legacy BIOS
- **RHEL:** ISOLinux primary, GRUB for EFI

### ISO Structure
- **Ubuntu:** Uses `/casper/` for kernel/initrd
- **RHEL:** Uses `/images/` and `/isolinux/`

### Repository Metadata
- **Ubuntu:** Uses `Packages.gz` and `Release` files
- **RHEL:** Uses `repodata/` with `comps.xml`

## Common Customizations

### 1. Pre-install Packages

Edit `Makefile` variable `ISO_ADD_OS`:
```makefile
ISO_ADD_OS = \
    vim \
    curl \
    wget \
    your-package
```

### 2. Custom Partitioning

Edit `isolinux/preseed.m4`:
```m4
# Custom partition recipe
d-i partman-auto/expert_recipe string \
    boot-root :: \
        512 512 512 ext4 \
            $primary{ } $bootable{ } \
            mountpoint{ /boot } \
        . \
        10240 10240 -1 ext4 \
            $primary{ } \
            mountpoint{ / } \
        .
```

### 3. Network Configuration

Edit `isolinux/preseed.m4`:
```m4
# Static IP
d-i netcfg/get_ipaddress string 192.168.1.100
d-i netcfg/get_netmask string 255.255.255.0
d-i netcfg/get_gateway string 192.168.1.1
d-i netcfg/get_nameservers string 8.8.8.8
d-i netcfg/confirm_static boolean true
```

### 4. Post-Installation Scripts

Edit `isolinux/preseed.m4`:
```m4
d-i preseed/late_command string \
    in-target sh -c 'echo "Custom config" > /etc/custom.conf'; \
    in-target systemctl enable your-service; \
    in-target apt-get install -y additional-package
```

## Troubleshooting

### Preseed not working
- Check file is in `/preseed/` directory on ISO
- Verify `autoinstall` parameter in boot config
- Check preseed syntax (no typos)
- Test with `debconf-get-selections` to see current settings

### Boot menu not showing
- Verify `grub.cfg` is in correct location
- Check `isolinux.cfg` for BIOS systems
- Ensure boot files are executable
- Test in different virtual machines

### Packages not installing
- Verify package names are correct
- Check repository availability
- Ensure packages are in pool/main/
- Check preseed package list syntax

### ISO won't boot
- Verify ISO structure is correct
- Check boot sector configuration
- Ensure `isohybrid` ran successfully
- Test on different hardware

## Security Best Practices

1. **Never use plaintext passwords** in preseed files
   - Always use `passwd/user-password-crypted` with hashed passwords
   - Generate hash with `mkpasswd -m sha-512`

2. **Remove preseed files after installation** (if sensitive)
   - Add to late_command: `rm -f /cdrom/preseed/preseed.cfg`

3. **Verify package sources**
   - Only use trusted repositories
   - Verify DEB package signatures

4. **Secure network configuration**
   - Don't hardcode sensitive network info
   - Use DHCP when possible

## Advanced Topics

### Multi-Architecture Support
Build ISOs for different architectures:
- amd64 (x86_64)
- arm64
- ppc64el

### Custom Repository
Create local APT repository:
```bash
# Create repository structure
mkdir -p repo/pool/main
cp *.deb repo/pool/main/
cd repo
apt-ftparchive packages pool/main > Packages
apt-ftparchive release . > Release
gpg --sign Release
```

### Network Boot (PXE)
Configure PXE server to boot your custom ISO:
- Use `loopback.cfg` in GRUB
- Configure TFTP server
- Point to ISO location

## Quick Reference

| Task | File to Edit |
|------|-------------|
| Automated install config | `isolinux/preseed.m4` |
| UEFI boot menu | `isolinux/grub.cfg` |
| BIOS boot menu | `isolinux/isolinux.cfg` |
| Package list | `Makefile` (ISO_ADD_OS) |
| Custom packages | `custom-debs/*.deb` |
| Build ISO | `make all` |

## Next Steps

1. Customize `preseed.m4` for your needs
2. Update boot menu labels in `grub.cfg` and `isolinux.cfg`
3. Add your custom DEB packages
4. Build and test the ISO
5. Iterate based on testing results

For more information, see:
- [Ubuntu Preseed Documentation](https://wiki.debian.org/DebianInstaller/Preseed)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [GRUB Manual](https://www.gnu.org/software/grub/manual/)

