# Custom Ubuntu ISO Builder Makefile
# This Makefile builds a custom Ubuntu ISO
# Usage: make [target]

# ============================================================================
# Configuration Variables
# ============================================================================

# Source directory (parent directory)
SRC = $(abspath ..)

# Package version identifier
PACKAGE_VERSION ?= DFD

# ISO source directory (contains preseed, grub configs, etc.)
ISO_SRC ?= $(SRC)/isolinux

# ISO label (short name)
ISO_LABEL ?= HAMLE

# ISO revision (defaults to current date YYMMDD)
ISO_REV ?= $(shell date +%y%m%d)

# Build directory
BUILD_DIR = $(SRC)/BUILD

# ISO metadata
VOLUME_LABEL ?= "Karel HAMLE"
APPLICATION_LABEL ?= "HAMLE $(PACKAGE_VERSION)"
PUBLISHER_ID ?= nezir.aydin@karel.com.tr
PREPARERER_ID ?= nezir.aydin@karel.com.tr

# M4 macro processor options for preseed template
ISO_M4_OPTS = -I $(ISO_SRC) -D PACKAGE_VERSION=$(PACKAGE_VERSION)

# Package directories
ISO_PACKAGES_OS = os-Packages
ISO_PACKAGES_CUSTOM = custom-Packages

# ISO disc working directory
ISO_DISC = $(BUILD_DIR)/iso-disc

# Output ISO filename
ISO ?= $(ISO_LABEL)-$(PACKAGE_VERSION)-$(ISO_REV)-amd64.iso

# Files to copy to ISO
ISOLINUX_FILES = $(ISO_SRC)/splash.jpg $(ISO_SRC)/isolinux.cfg
GRUB_FILES = $(ISO_SRC)/grub.cfg $(ISO_SRC)/loopback.cfg

# Source ISO pattern (Ubuntu ISO)
SOURCE_ISO_PATTERN = $(SRC)/ubuntu-iso/ubuntu-*-server-amd64.iso

# Mount point for source ISO
MOUNT_POINT = cd

# Ubuntu version (for package downloads)
UBUNTU_VERSION ?= jammy
UBUNTU_CODENAME ?= $(UBUNTU_VERSION)

# ============================================================================
# Package Lists
# ============================================================================

# Base OS packages to add (DEB packages)
ISO_ADD_OS = \
	vim \
	curl \
	wget \
	git \
	build-essential \
	htop \
	tree \
	net-tools \
	tcpdump \
	nmap \
	openssh-server \
	samba \
	nfs-common \
	ntp \
	ufw \
	apt-transport-https \
	ca-certificates \
	software-properties-common

# Custom DEB packages directory
CUSTOM_DEBS_DIR = $(SRC)/custom-debs

# ============================================================================
# Main Targets
# ============================================================================

.PHONY: all clean iso help

# Default target - builds complete ISO
all: create-build-env iso

# Build ISO only (assumes build env exists)
iso: iso-copy-disc iso-add-os iso-add-custom iso-update-packages \
	iso-update-boot-config iso-assemble iso-md5

# Clean build artifacts
clean:
	@echo ">>> Cleaning build artifacts"
	@rm -rf $(ISO_PACKAGES_OS) $(ISO_PACKAGES_CUSTOM) $(BUILD_DIR) build.txt
	@find . -maxdepth 1 -type d -name "cd*" -exec rm -rf {} \; 2>/dev/null || true
	@find . -maxdepth 1 ! -name Makefile -type f -exec rm -f {} \; 2>/dev/null || true

# Show help
help:
	@echo "Custom Ubuntu ISO Builder"
	@echo ""
	@echo "Targets:"
	@echo "  all                 - Build complete ISO (default)"
	@echo "  iso                 - Build ISO (skip environment setup)"
	@echo "  clean               - Remove all build artifacts"
	@echo "  create-build-env    - Set up build environment"
	@echo "  iso-copy-disc       - Extract base ISO contents"
	@echo "  iso-packages        - Add all packages (OS, Custom)"
	@echo "  iso-assemble        - Create final ISO image"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Variables (override with VAR=value):"
	@echo "  PACKAGE_VERSION     - Package version (default: DFD)"
	@echo "  ISO_LABEL           - ISO label (default: HAMLE)"
	@echo "  ISO_REV             - ISO revision (default: YYMMDD)"
	@echo "  UBUNTU_VERSION      - Ubuntu version (default: jammy)"
	@echo "  SRC                 - Source directory (default: ..)"
	@echo "  ISO_SRC             - ISO source directory (default: \$$SRC/isolinux)"

# ============================================================================
# Build Environment Setup
# ============================================================================

create-build-env:
	@echo ">>> Creating build environment"
	@test -d $(ISO_PACKAGES_OS) || mkdir -p $(ISO_PACKAGES_OS)
	@test -d $(ISO_PACKAGES_CUSTOM) || mkdir -p $(ISO_PACKAGES_CUSTOM)
	@test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)
	@rm -f build.txt
	@touch build.txt
	@echo ">>> Starting building $(ISO_LABEL) Ubuntu ISO"

# ============================================================================
# ISO Content Preparation
# ============================================================================

iso-copy-disc:
	@echo ">>> Extracting base Ubuntu ISO contents"
	@test -d $(MOUNT_POINT) || mkdir -p $(MOUNT_POINT)
	@if [ -d $(MOUNT_POINT).tmp ]; then rm -rf $(MOUNT_POINT).tmp; fi
	@SOURCE_ISO=$$(ls -1 $(SOURCE_ISO_PATTERN) 2>/dev/null | head -1); \
	if [ -z "$$SOURCE_ISO" ]; then \
		echo "ERROR: Source ISO not found matching $(SOURCE_ISO_PATTERN)"; \
		exit 1; \
	fi; \
	echo ">>> Mounting source ISO: $$SOURCE_ISO"; \
	sudo mount -o loop "$$SOURCE_ISO" $(MOUNT_POINT) &>> build.txt || exit 1; \
	echo ">>> Copying contents of disc"; \
	cp -ar $(MOUNT_POINT) $(MOUNT_POINT).tmp; \
	sudo umount $(MOUNT_POINT) || true; \
	sudo rm -rf $(MOUNT_POINT); \
	chmod -R a+rw $(MOUNT_POINT).tmp; \
	mv $(MOUNT_POINT).tmp $(ISO_DISC); \
	echo ">>> ISO contents extracted to $(ISO_DISC)"

iso-add-os:
	@echo ">>> Adding extra OS packages"
	@mkdir -p $(BUILD_DIR)/tmp
	@for package in $(ISO_ADD_OS); do \
		echo "  Downloading: $$package"; \
		cd $(BUILD_DIR)/tmp && \
		apt-get download $$package 2>>$(SRC)/build.txt || \
		apt-get -o Dir::Cache::Archives=$(BUILD_DIR)/tmp download $$package 2>>$(SRC)/build.txt; \
		if [ "$$?" == "0" ]; then \
			mv $(BUILD_DIR)/tmp/*.deb $(ISO_PACKAGES_OS)/ 2>/dev/null || true; \
			echo "  +++ Added: $$package"; \
		else \
			echo "  ??? Failed: $$package"; \
		fi; \
		rm -f $(BUILD_DIR)/tmp/*.deb; \
	done
	@if [ -d $(ISO_PACKAGES_OS) ] && [ "$$(ls -A $(ISO_PACKAGES_OS) 2>/dev/null)" ]; then \
		rsync -av $(ISO_PACKAGES_OS)/ $(ISO_DISC)/pool/main/ 2>>build.txt || \
		cp -av $(ISO_PACKAGES_OS)/*.deb $(ISO_DISC)/pool/main/ 2>>build.txt || true; \
	fi
	@rm -rf $(BUILD_DIR)/tmp
	@rm -rf $(ISO_PACKAGES_OS)

iso-add-custom:
	@echo ">>> Adding custom DEB packages"
	@if [ -d $(CUSTOM_DEBS_DIR) ]; then \
		if [ "$$(ls -A $(CUSTOM_DEBS_DIR)/*.deb 2>/dev/null)" ]; then \
			cp -av $(CUSTOM_DEBS_DIR)/*.deb $(ISO_DISC)/pool/main/ 2>>build.txt; \
			echo "  +++ Custom packages added from $(CUSTOM_DEBS_DIR)"; \
		else \
			echo "  --- No DEB files found in $(CUSTOM_DEBS_DIR)"; \
		fi; \
	else \
		echo "  --- No custom packages directory found: $(CUSTOM_DEBS_DIR)"; \
	fi

iso-update-packages:
	@echo ">>> Updating package index"
	@if [ -d $(ISO_DISC)/pool/main ] && [ "$$(ls -A $(ISO_DISC)/pool/main/*.deb 2>/dev/null)" ]; then \
		echo "  Note: Package updates should be handled via apt repositories"; \
		echo "  Consider using apt-cacher-ng or local repository mirror"; \
	fi

# Combined package target
iso-packages: iso-add-os iso-add-custom iso-update-packages

# ============================================================================
# ISO Metadata and Boot Configuration
# ============================================================================

iso-update-boot-config:
	@echo ">>> Updating boot configuration"
	@# Generate preseed file from M4 template
	@if [ -f $(ISO_SRC)/preseed.m4 ]; then \
		m4 $(ISO_M4_OPTS) $(ISO_SRC)/preseed.m4 > $(ISO_DISC)/preseed/preseed.cfg; \
		echo "  +++ Generated preseed file"; \
	elif [ -f $(ISO_SRC)/preseed.cfg ]; then \
		cp -f $(ISO_SRC)/preseed.cfg $(ISO_DISC)/preseed/preseed.cfg; \
		echo "  +++ Copied preseed file"; \
	fi
	@# Copy isolinux files (for legacy BIOS boot)
	@if [ -d $(ISO_DISC)/isolinux ]; then \
		for f in $(ISOLINUX_FILES); do \
			if [ -f "$$f" ]; then \
				cp -f "$$f" $(ISO_DISC)/isolinux/$$(basename "$$f"); \
				echo "  +++ Copied isolinux: $$(basename $$f)"; \
			fi; \
		done; \
	fi
	@# Copy GRUB files (for UEFI boot)
	@if [ -d $(ISO_DISC)/boot/grub ]; then \
		for f in $(GRUB_FILES); do \
			if [ -f "$$f" ]; then \
				cp -f "$$f" $(ISO_DISC)/boot/grub/$$(basename "$$f"); \
				echo "  +++ Copied GRUB: $$(basename $$f)"; \
			fi; \
		done; \
	fi
	@# Update GRUB in EFI directory
	@if [ -d $(ISO_DISC)/EFI/BOOT ]; then \
		if [ -f $(ISO_SRC)/grub.cfg ]; then \
			cp -f $(ISO_SRC)/grub.cfg $(ISO_DISC)/EFI/BOOT/grub.cfg; \
			echo "  +++ Updated EFI GRUB config"; \
		fi; \
	fi
	@# Update txt.cfg for text mode install
	@if [ -f $(ISO_SRC)/txt.cfg ] && [ -d $(ISO_DISC)/isolinux ]; then \
		cp -f $(ISO_SRC)/txt.cfg $(ISO_DISC)/isolinux/txt.cfg; \
		echo "  +++ Updated txt.cfg"; \
	fi

# ============================================================================
# ISO Assembly
# ============================================================================

iso-assemble:
	@echo ">>> Creating Ubuntu ISO image: $(ISO)"
	@# Ubuntu uses xorriso (or mkisofs) with specific options
	@if command -v xorriso >/dev/null 2>&1; then \
		xorriso -as mkisofs \
			-r -J -T \
			-V $(VOLUME_LABEL) \
			-A $(APPLICATION_LABEL) \
			-p $(PREPARERER_ID) \
			-b isolinux/isolinux.bin \
			-c isolinux/boot.cat \
			-no-emul-boot \
			-boot-load-size 4 \
			-boot-info-table \
			-eltorito-alt-boot \
			-e boot/grub/efi.img \
			-no-emul-boot \
			-isohybrid-gpt-basdat \
			-o $(BUILD_DIR)/$(ISO).tmp \
			$(ISO_DISC) &>> build.txt; \
	else \
		genisoimage -r -J -T \
			-V $(VOLUME_LABEL) \
			-A $(APPLICATION_LABEL) \
			-p $(PREPARERER_ID) \
			-b isolinux/isolinux.bin \
			-c isolinux/boot.cat \
			-no-emul-boot \
			-boot-load-size 4 \
			-boot-info-table \
			-eltorito-alt-boot \
			-e boot/grub/efi.img \
			-no-emul-boot \
			-o $(BUILD_DIR)/$(ISO).tmp \
			$(ISO_DISC) &>> build.txt; \
	fi
	@mv $(BUILD_DIR)/$(ISO).tmp $(BUILD_DIR)/$(ISO)
	@if command -v isohybrid >/dev/null 2>&1; then \
		isohybrid --uefi $(BUILD_DIR)/$(ISO); \
		echo "  +++ ISO hybridized for USB boot"; \
	fi
	@echo ">>> ISO created: $(BUILD_DIR)/$(ISO)"

iso-md5:
	@echo ">>> Generating MD5 checksum"
	@cd $(BUILD_DIR); \
	md5sum $(ISO) > $(ISO:%.iso=%.md5); \
	echo "  +++ Checksum: $$(cat $(ISO:%.iso=%.md5))"
