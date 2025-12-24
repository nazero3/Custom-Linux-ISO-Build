# How to Build a Custom Linux ISO - Step by Step Guide

## Understanding the Process

Building a custom Linux ISO involves several key steps:

### 1. **Start with a Base ISO**
   - You need a base Linux distribution ISO (Rocky, RHEL, CentOS, etc.)
   - This provides the core operating system files
   - Think of it as your "template"

### 2. **Extract and Modify**
   - Mount the ISO to access its contents
   - Copy everything to a working directory
   - Now you can modify files, add packages, change configurations

### 3. **Add Your Customizations**
   - **Packages**: Add software you want pre-installed
   - **Configurations**: Modify system settings
   - **Custom Files**: Include your own applications or scripts
   - **Boot Configuration**: Customize the installation menu

### 4. **Update Repository Metadata**
   - Linux uses package repositories (like app stores)
   - When you add/remove packages, you must update the repository index
   - This tells the installer what packages are available

### 5. **Rebuild the ISO**
   - Package everything back into an ISO9660 filesystem
   - Configure boot sectors (BIOS and UEFI)
   - Make it bootable from CD/DVD or USB

## Detailed Workflow

### Phase 1: Preparation

```
┌─────────────────┐
│  Base ISO File  │  (Rocky Linux minimal ISO)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Mount ISO      │  (Access files inside)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Copy Contents  │  (Extract to working directory)
└────────┬────────┘
```

**What happens:**
- ISO is a disk image (like a ZIP file for CDs)
- We mount it to access files inside
- Copy everything to a directory we can modify

### Phase 2: Customization

```
┌─────────────────┐
│  Add Packages   │  (Download from repositories)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Custom RPMs    │  (Your own software)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update Config  │  (Kickstart, boot menu, etc.)
└────────┬────────┘
```

**What happens:**
- Download packages you want included
- Add your custom RPM packages
- Update kickstart for automated installation
- Modify boot menu appearance

### Phase 3: Repository Update

```
┌─────────────────┐
│  Package List   │  (All .rpm files)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  createrepo     │  (Generate metadata)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  repodata/      │  (Repository index)
└─────────────────┘
```

**What happens:**
- `createrepo` scans all RPM files
- Creates metadata (package names, versions, dependencies)
- Generates `repodata/` directory with XML files
- Installer uses this to know what packages are available

### Phase 4: ISO Assembly

```
┌─────────────────┐
│  Modified Files │  (All your changes)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  genisoimage    │  (Create ISO9660 filesystem)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  isohybrid      │  (Make USB bootable)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Final ISO      │  (Ready to burn/deploy)
└─────────────────┘
```

**What happens:**
- `genisoimage` creates ISO9660 filesystem (CD/DVD format)
- Configures boot sectors for BIOS (isolinux) and UEFI (EFI)
- `isohybrid` makes it bootable from USB drives
- Final ISO can be burned to disc or written to USB

## Key Components Explained

### Boot Configuration (ISOLinux)

**Location:** `isolinux/isolinux.cfg`

Controls what users see when booting the ISO:
- Boot menu appearance
- Installation options
- Kernel parameters
- Timeout settings

**Example:**
```
default vesamenu.c32
timeout 600
menu title Custom Linux Installer
label install
  menu label ^Install Custom Linux
  kernel vmlinuz
  append initrd=initrd.img inst.ks=cdrom:/ks.cfg
```

### Kickstart File

**Location:** `ks.cfg` (generated from `ks.m4` template)

Automates installation - no user interaction needed:
- Partitioning scheme
- Package selection
- User accounts
- Network configuration
- Post-installation scripts

**Example:**
```
install
cdrom
lang en_US.UTF-8
keyboard us
rootpw --plaintext mypassword
timezone America/New_York
bootloader --location=mbr
part / --fstype=xfs --size=10000
%packages
@core
vim
%end
```

### Package Management

**Three types of packages:**

1. **Base OS Packages** (`ISO_ADD_OS`)
   - From the distribution's main repository
   - Example: `vim`, `gcc`, `kernel-devel`

2. **EPEL Packages** (`ISO_ADD_EPEL`)
   - Extra Packages for Enterprise Linux
   - Additional software not in base repo
   - Example: `mxml`, `msmtp`

3. **Custom Packages** (`hml-rpms/`)
   - Your own RPM files
   - Proprietary software
   - Custom-built applications

### EFI Boot Support

Modern computers use UEFI instead of BIOS:
- **GRUB Config:** `EFI/BOOT/grub.cfg` - Boot menu for UEFI
- **Boot Image:** `images/efiboot.img` - EFI bootloader
- Required for UEFI systems to boot

## Common Use Cases

### 1. Pre-configured Server Image
- Include all required packages
- Pre-configure services
- Add custom scripts
- Automated installation with kickstart

### 2. Development Environment
- Include development tools
- Pre-install IDEs, compilers
- Configure development settings
- Ready-to-use environment

### 3. Specialized Application
- Include your application
- Configure dependencies
- Set up runtime environment
- One-click deployment

### 4. Security Hardened Image
- Remove unnecessary packages
- Include security tools
- Pre-configure firewalls
- Compliance-ready image

## Best Practices

### 1. Version Control
- Keep Makefile in version control
- Track package lists
- Document customizations

### 2. Testing
- Test ISO in virtual machine first
- Verify all packages install correctly
- Test kickstart automation
- Check boot on different hardware

### 3. Package Management
- Use specific package versions when possible
- Verify package signatures
- Test package dependencies
- Document why each package is included

### 4. Security
- Never include plaintext passwords in kickstart
- Use hashed passwords: `rootpw --iscrypted $6$...`
- Verify package sources
- Keep base ISO updated

### 5. Optimization
- Remove unnecessary packages to reduce size
- Compress custom files
- Use efficient filesystem options
- Consider multi-layer ISOs for large images

## Troubleshooting Common Issues

### Issue: ISO won't boot
**Solutions:**
- Verify `isolinux.bin` is present and executable
- Check EFI boot files exist
- Ensure `isohybrid` completed successfully
- Test in different virtual machines

### Issue: Packages missing during install
**Solutions:**
- Verify `repodata/` was generated correctly
- Check package files are in `Packages/` directory
- Ensure `comps.xml` includes package groups
- Verify repository metadata is valid

### Issue: Kickstart fails
**Solutions:**
- Validate kickstart syntax: `ksvalidator ks.cfg`
- Check file paths are correct
- Verify package names exist
- Test kickstart in interactive mode first

### Issue: Build fails with permission errors
**Solutions:**
- Some operations require `sudo` (mounting ISO)
- Ensure build directories are writable
- Check disk space available
- Verify source ISO is readable

## Advanced Techniques

### Multi-Architecture Support
Build ISOs for different CPU architectures:
- x86_64 (Intel/AMD 64-bit)
- aarch64 (ARM 64-bit)
- ppc64le (PowerPC)

### Layered ISO Structure
For very large ISOs:
- Base layer: Core OS
- Add-on layers: Optional components
- Users select what to install

### Automated Testing
Integrate with CI/CD:
```bash
# Build ISO
make all

# Test in VM
qemu-system-x86_64 -cdrom BUILD/*.iso -m 2048

# Run automated tests
# Verify installation
```

### Custom Package Creation
Create your own RPMs:
```bash
# Use rpmbuild or mock
rpmbuild -ba mypackage.spec

# Place in hml-rpms/
cp ~/rpmbuild/RPMS/x86_64/*.rpm hml-rpms/
```

## Summary

Building a custom Linux ISO is essentially:
1. **Extract** a base ISO
2. **Modify** its contents (packages, configs)
3. **Update** repository metadata
4. **Rebuild** into a new ISO

The Makefile automates all these steps, making it easy to:
- Reproduce builds
- Version control changes
- Automate in CI/CD
- Maintain consistency

Each build creates a complete, bootable Linux installation image with your customizations baked in!

