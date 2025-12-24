# Custom Linux ISO Builder

This project provides a Makefile-based system for building custom Linux ISOs based on Rocky Linux (or similar RHEL-based distributions).

## Overview

Building a custom Linux ISO allows you to:
- Pre-install specific packages
- Include custom applications and configurations
- Create automated installation with kickstart files
- Brand the installation media
- Create reproducible deployment images

## Prerequisites

### Required Software

```bash
# On Rocky/RHEL/CentOS
sudo yum install -y \
    genisoimage \
    isohybrid \
    createrepo \
    m4 \
    rsync \
    rpm-build

# Or on newer systems
sudo dnf install -y \
    genisoimage \
    syslinux \
    isohybrid \
    createrepo \
    m4 \
    rsync
```

### Required Directory Structure

```
project-root/
├── Makefile                 # This Makefile
├── rocky-iso/              # Source Rocky Linux ISO files
│   └── Rocky-*-x86_64-Minimal-*.iso
├── isolinux/               # Boot configuration files
│   ├── isolinux.cfg        # Boot menu configuration
│   ├── splash.jpg          # Boot splash screen
│   ├── ks.m4               # Kickstart template (M4 macro)
│   └── comps-hml.xml       # Package groups definition
├── efi/                    # EFI boot files
│   ├── grub.cfg            # GRUB configuration for EFI
│   └── efiboot.img         # EFI boot image
├── hml-rpms/               # Custom RPM packages
│   └── *.rpm               # Your custom packages
└── yum.repos.d/            # YUM repository configurations
    └── build.repo          # Repository for downloading packages
```

## Quick Start

1. **Prepare your source ISO:**
   ```bash
   # Download Rocky Linux minimal ISO and place it in rocky-iso/
   # Example: Rocky-9.3-x86_64-minimal.iso
   ```

2. **Configure repositories:**
   ```bash
   # Create yum.repos.d/build.repo with your package repositories
   # This is used to download packages during build
   ```

3. **Customize package lists:**
   ```bash
   # Edit Makefile variables:
   # - ISO_ADD_OS: Base OS packages to include
   # - ISO_ADD_EPEL: EPEL packages to include
   ```

4. **Build the ISO:**
   ```bash
   make all
   ```

5. **Output:**
   ```bash
   # ISO will be created in: BUILD/HAMLE-DFD-YYMMDD-x86_64.iso
   # MD5 checksum: BUILD/HAMLE-DFD-YYMMDD-x86_64.md5
   ```

## Makefile Targets

### Main Targets

- `make all` - Complete build (setup + ISO creation)
- `make iso` - Build ISO (assumes environment is ready)
- `make clean` - Remove all build artifacts
- `make help` - Show available targets and options

### Individual Steps

- `make create-build-env` - Set up build directories
- `make iso-copy-disc` - Extract base ISO contents
- `make iso-add-os` - Add OS packages
- `make iso-add-epEL` - Add EPEL packages
- `make iso-add-hml` - Add custom packages
- `make iso-update-packages` - Update existing packages
- `make iso-create-repodata` - Generate repository metadata
- `make iso-update-isolinux` - Update boot configuration
- `make iso-assemble` - Create final ISO image
- `make iso-md5` - Generate MD5 checksum

## Configuration Variables

You can override these variables when running make:

```bash
# Package version
make PACKAGE_VERSION=1.0.0

# ISO label
make ISO_LABEL=MYCUSTOM

# ISO revision (defaults to date)
make ISO_REV=20240101

# Source directory
make SRC=/path/to/source
```

## How It Works

### 1. Base ISO Extraction
- Mounts the source Rocky Linux ISO
- Copies all contents to a working directory
- Unmounts and prepares for modification

### 2. Package Management
- **Add OS Packages**: Downloads specified packages from base OS repositories
- **Add EPEL Packages**: Downloads packages from EPEL repository
- **Add Custom Packages**: Copies your custom RPMs
- **Update Packages**: Checks for newer versions of existing packages

### 3. Repository Metadata
- Uses `createrepo` to generate repository metadata
- Includes package groups if `comps-hml.xml` is provided
- Required for package installation during OS install

### 4. Boot Configuration
- **Kickstart**: Processes M4 template to generate `ks.cfg` for automated install
- **ISOLinux**: Updates boot menu and splash screen
- **EFI**: Updates GRUB configuration and boot images for UEFI systems

### 5. ISO Assembly
- Uses `genisoimage` to create the ISO9660 filesystem
- Configures boot sectors for BIOS and UEFI
- Applies volume labels and metadata
- Uses `isohybrid` to make ISO bootable from USB

## Customization Guide

### Adding Packages

Edit the package lists in the Makefile:

```makefile
ISO_ADD_OS = \
    package1 \
    package2.x86_64

ISO_ADD_EPEL = \
    epel-package1 \
    epel-package2
```

### Custom Kickstart

1. Create `isolinux/ks.m4` (M4 macro template):
   ```m4
   # Kickstart configuration
   install
   cdrom
   lang en_US.UTF-8
   keyboard us
   rootpw --plaintext password
   # ... more configuration
   ```

2. The Makefile will process it with M4 macros

### Boot Menu Customization

Edit `isolinux/isolinux.cfg`:
```
default vesamenu.c32
timeout 600
label linux
  menu label ^Install Custom Linux
  kernel vmlinuz
  append initrd=initrd.img inst.ks=cdrom:/ks.cfg
```

### Custom Packages

Place your RPM files in `hml-rpms/` directory. They will be automatically included.

## Troubleshooting

### "Source ISO not found"
- Ensure Rocky Linux ISO is in `rocky-iso/` directory
- Check the filename matches the pattern in Makefile

### "Permission denied" errors
- Some operations require sudo (mounting ISO)
- Ensure you have permissions to create directories

### Package download failures
- Check repository configuration in `yum.repos.d/build.repo`
- Verify network connectivity
- Some packages may not be available in specified repositories

### ISO won't boot
- Verify `isolinux.bin` and boot files are present
- Check EFI boot configuration
- Ensure `isohybrid` ran successfully

## Advanced Usage

### Building for Different Architectures

Modify the architecture filters:
```makefile
# In iso-add-epel and iso-update-packages
--archlist=noarch,x86_64,aarch64
```

### Multiple ISO Variants

Create separate Makefiles or use variables:
```bash
make ISO_LABEL=DESKTOP ISO_ADD_OS="$(DESKTOP_PACKAGES)"
make ISO_LABEL=SERVER ISO_ADD_OS="$(SERVER_PACKAGES)"
```

### Automated Builds

Use in CI/CD:
```bash
#!/bin/bash
set -e
make clean
make all
# Upload ISO to artifact repository
```

## Security Considerations

- **Kickstart passwords**: Use hashed passwords, not plaintext
- **Package verification**: Verify package signatures
- **Repository security**: Use signed repositories
- **ISO verification**: Always verify MD5 checksums before deployment

## Further Reading

- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Kickstart Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_8_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user)
- [ISOLinux Documentation](https://wiki.syslinux.org/wiki/index.php?title=ISOLINUX)
- [genisoimage Manual](https://linux.die.net/man/1/genisoimage)

## License

This Makefile is provided as-is for building custom Linux distributions.

