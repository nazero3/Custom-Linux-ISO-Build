# ✅ Ubuntu ISO Customization - Setup Complete!

## What Has Been Created

All necessary files for customizing Ubuntu installation ISOs have been created:

### ✅ Core Files

1. **`Makefile`** - Ubuntu-specific build script
   - Uses `apt-get` and DEB packages (not RPM)
   - Handles Ubuntu ISO structure
   - Uses `xorriso` for ISO creation

2. **`isolinux/preseed.m4`** - Automated installation template
   - M4 template for generating preseed.cfg
   - Configures language, network, partitioning, users, packages
   - Includes post-installation scripts

3. **`isolinux/grub.cfg`** - UEFI boot menu
   - GRUB configuration for modern UEFI systems
   - Boot menu entries for install/try/check

4. **`isolinux/isolinux.cfg`** - Legacy BIOS boot menu
   - ISOLinux configuration for older BIOS systems
   - Same functionality as grub.cfg but for BIOS

5. **`isolinux/txt.cfg`** - Text mode boot menu
   - Fallback text-based menu
   - Used when graphics aren't available

6. **`isolinux/loopback.cfg`** - GRUB loopback configuration
   - Allows booting ISO from hard disk
   - Useful for PXE/network boot scenarios

### ✅ Documentation

- **`QUICK_START.md`** - Quick reference guide
- **`UBUNTU_SETUP.md`** - Detailed setup instructions
- **`GUIDE.md`** - General Linux ISO building guide (from Rocky)
- **`README.md`** - Original Rocky Linux documentation

## What You Need to Do Next

### Step 1: Install Required Tools

```bash
# On Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y xorriso genisoimage isohybrid m4 rsync whois

# On RHEL/CentOS/Rocky  
sudo yum install -y xorriso genisoimage syslinux isohybrid m4 rsync mkpasswd
```

### Step 2: Prepare Your Ubuntu ISO

```bash
# Create directory
mkdir -p ../ubuntu-iso

# Download Ubuntu Server ISO and place it there
# Example: ../ubuntu-iso/ubuntu-22.04-server-amd64.iso
```

### Step 3: Customize Preseed Configuration

**IMPORTANT:** You MUST set a password before building!

```bash
# Generate password hash
mkpasswd -m sha-512
# Enter your password, copy the hash

# Edit isolinux/preseed.m4
# Find this line (around line 75):
# d-i passwd/user-password-crypted password $6$rounds=4096$salt$hashedpassword
# Replace with your generated hash
```

**Other customizations in `isolinux/preseed.m4`:**
- Timezone (line ~40): Change `America/New_York` to your timezone
- Network (lines ~20-30): Configure static IP or keep DHCP
- User account (lines ~70-80): Change username and full name
- Packages (lines ~90-100): Add/remove packages to install
- Partitioning (lines ~50-65): Modify if needed

### Step 4: Customize Boot Menus (Optional)

Edit boot menu files to change labels:
- `isolinux/grub.cfg` - Change menu titles
- `isolinux/isolinux.cfg` - Change menu labels
- `isolinux/txt.cfg` - Text mode labels

### Step 5: Add Custom Packages (Optional)

**Option A:** Edit `Makefile` variable `ISO_ADD_OS`
```makefile
ISO_ADD_OS = \
    vim \
    curl \
    your-packages-here
```

**Option B:** Place `.deb` files in `../custom-debs/` directory

### Step 6: Build Your ISO

```bash
# Full build
make all

# Output will be in: BUILD/HAMLE-DFD-YYMMDD-amd64.iso
```

### Step 7: Test the ISO

```bash
# Test in QEMU
qemu-system-x86_64 -cdrom BUILD/*.iso -m 2048

# Or use VirtualBox/VMware
```

## File Reference

| File | Purpose | When to Edit |
|------|---------|--------------|
| `Makefile` | Build script | Change package lists, ISO name |
| `isolinux/preseed.m4` | Installation automation | **MUST EDIT** - Set password, customize install |
| `isolinux/grub.cfg` | UEFI boot menu | Change menu labels, timeout |
| `isolinux/isolinux.cfg` | BIOS boot menu | Change menu labels, timeout |
| `isolinux/txt.cfg` | Text boot menu | Usually same as isolinux.cfg |
| `isolinux/loopback.cfg` | GRUB loopback | Rarely needed |

## Key Differences from Rocky/RHEL

| Feature | Ubuntu | Rocky/RHEL |
|---------|--------|-------------|
| Automation | **preseed** | kickstart |
| Packages | **DEB** | RPM |
| Package Manager | **apt-get** | yum/dnf |
| Boot Primary | **GRUB** | ISOLinux |
| Kernel Location | `/casper/` | `/images/` |
| ISO Tool | **xorriso** | genisoimage |

## Quick Commands

```bash
# Build everything
make all

# Clean and rebuild
make clean && make all

# Step by step
make create-build-env
make iso-copy-disc
make iso-packages
make iso-update-boot-config
make iso-assemble
make iso-md5

# Get help
make help
```

## Troubleshooting

### "Source ISO not found"
- Check ISO is in `../ubuntu-iso/` directory
- Verify filename matches: `ubuntu-*-server-amd64.iso`

### Preseed not working
- Verify `autoinstall` parameter in boot configs
- Check preseed file is in `/cdrom/preseed/preseed.cfg` on ISO
- Test preseed syntax

### Password not working
- Make sure you generated hash with `mkpasswd -m sha-512`
- Verify hash is in correct format: `$6$rounds=4096$...`
- Check preseed.m4 has correct password line

### ISO won't boot
- Verify boot files are in correct locations
- Check ISO structure is valid
- Test on different hardware/VMs

## Next Steps

1. ✅ **Set password** in `isolinux/preseed.m4` (REQUIRED)
2. ✅ **Customize** installation settings in preseed.m4
3. ✅ **Place Ubuntu ISO** in `../ubuntu-iso/` directory
4. ✅ **Build** with `make all`
5. ✅ **Test** in virtual machine
6. ✅ **Iterate** based on results

## Documentation Files

- **`QUICK_START.md`** - Start here for quick reference
- **`UBUNTU_SETUP.md`** - Detailed setup guide with explanations
- **`GUIDE.md`** - General Linux ISO building concepts
- **`README.md`** - Original Rocky Linux documentation

## Support

For issues or questions:
1. Check `UBUNTU_SETUP.md` for detailed explanations
2. Review `QUICK_START.md` for common tasks
3. Verify all files are in correct locations
4. Test preseed syntax separately

---

**You're all set!** Start by editing `isolinux/preseed.m4` to set your password and customize the installation, then build your first custom Ubuntu ISO!

