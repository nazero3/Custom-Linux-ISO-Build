# Quick Start: Ubuntu ISO Customization

## What You Need

1. **Ubuntu Server ISO** - Download from ubuntu.com
2. **Configuration Files** - Already created in this project
3. **Build Tools** - Install on your system

## Required Tools

```bash
# On Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    xorriso \
    genisoimage \
    isohybrid \
    m4 \
    rsync \
    whois

# On RHEL/CentOS/Rocky
sudo yum install -y \
    xorriso \
    genisoimage \
    syslinux \
    isohybrid \
    m4 \
    rsync \
    mkpasswd
```

## Directory Setup

```bash
# Create directory structure
mkdir -p ../ubuntu-iso
mkdir -p ../custom-debs
mkdir -p isolinux

# Place Ubuntu ISO in ubuntu-iso/
# Example: ../ubuntu-iso/ubuntu-22.04-server-amd64.iso
```

## Essential Files Checklist

- [x] `Makefile` - Build script
- [x] `isolinux/preseed.m4` - Installation automation
- [x] `isolinux/grub.cfg` - UEFI boot menu
- [x] `isolinux/isolinux.cfg` - BIOS boot menu
- [x] `isolinux/txt.cfg` - Text mode menu
- [x] `isolinux/loopback.cfg` - GRUB loopback

## Quick Customization

### 1. Set Password (IMPORTANT!)

```bash
# Generate password hash
mkpasswd -m sha-512
# Enter password, copy the output hash

# Edit isolinux/preseed.m4
# Find: d-i passwd/user-password-crypted password $6$...
# Replace with your hash
```

### 2. Customize Installation

Edit `isolinux/preseed.m4`:
- Change timezone (line ~40)
- Set network configuration (lines ~20-30)
- Modify user account (lines ~70-80)
- Add packages (lines ~90-100)

### 3. Customize Boot Menu

Edit `isolinux/grub.cfg` and `isolinux/isolinux.cfg`:
- Change menu titles
- Adjust timeout
- Modify default selection

### 4. Add Packages

Edit `Makefile`:
```makefile
ISO_ADD_OS = \
    vim \
    curl \
    your-packages-here
```

Or place `.deb` files in `custom-debs/` directory.

## Build Commands

```bash
# Full build
make all

# Step by step
make create-build-env    # Setup directories
make iso-copy-disc       # Extract base ISO
make iso-packages        # Add packages
make iso-update-boot-config  # Update boot files
make iso-assemble        # Create ISO
make iso-md5             # Generate checksum

# Clean and rebuild
make clean
make all
```

## Output

Your custom ISO will be in:
```
BUILD/HAMLE-DFD-YYMMDD-amd64.iso
BUILD/HAMLE-DFD-YYMMDD-amd64.md5
```

## Testing

```bash
# Test in QEMU
qemu-system-x86_64 -cdrom BUILD/*.iso -m 2048

# Or use VirtualBox/VMware
# Create new VM, attach ISO, boot
```

## Common Issues

### "Source ISO not found"
- Check ISO is in `../ubuntu-iso/` directory
- Verify filename matches pattern in Makefile

### "Permission denied"
- Some operations need `sudo` (mounting ISO)
- Check file permissions

### Preseed not working
- Verify `autoinstall` in boot config
- Check preseed file location: `/cdrom/preseed/preseed.cfg`
- Test preseed syntax

### Packages not installing
- Verify package names in preseed
- Check if packages exist in repositories
- Ensure custom DEBs are valid

## What Each File Does

| File | Purpose |
|------|---------|
| `preseed.m4` | Automated installation config (like kickstart) |
| `grub.cfg` | Boot menu for UEFI systems |
| `isolinux.cfg` | Boot menu for BIOS systems |
| `txt.cfg` | Text mode boot menu |
| `loopback.cfg` | Boot ISO from hard disk |

## Key Differences from RHEL

- **Preseed** instead of Kickstart
- **DEB packages** instead of RPM
- **GRUB** primary bootloader (not ISOLinux)
- **/casper/** directory for kernel/initrd
- **apt-get** instead of yum/dnf

## Next Steps

1. Customize `preseed.m4` for your environment
2. Test in virtual machine
3. Iterate based on results
4. Deploy to production

For detailed information, see `UBUNTU_SETUP.md`.

