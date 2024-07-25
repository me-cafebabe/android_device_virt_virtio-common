#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_GRUB_PATH := $(call my-dir)

ifeq ($(TARGET_GRUB_ARCH),)
$(warning TARGET_GRUB_ARCH is not defined, could not build GRUB)
else
GRUB_PREBUILT_DIR := prebuilts/grub/$(HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)
GRUB_TOOLS_LINEAGE_BIN_DIR := prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
GRUB_PATH_OVERRIDE := PATH=$(GRUB_TOOLS_LINEAGE_BIN_DIR):$$PATH
GRUB_XORRISO_EXEC := $(GRUB_TOOLS_LINEAGE_BIN_DIR)/xorriso

GRUB_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/GRUB_OBJ
GRUB_WORKDIR_BOOT := $(GRUB_WORKDIR_BASE)/boot

ifneq ($(LINEAGE_BUILD),)
GRUB_ANDROID_DISTRIBUTION_NAME := LineageOS $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)
GRUB_ARTIFACT_FILENAME_PREFIX := lineage-$(LINEAGE_VERSION)
GRUB_THEME := lineage
else
LOCAL_BUILD_DATE := $(shell date -u +%Y%m%d)
GRUB_ANDROID_DISTRIBUTION_NAME := Android $(PLATFORM_VERSION_LAST_STABLE) $(BUILD_ID)
GRUB_ARTIFACT_FILENAME_PREFIX := Android-$(PLATFORM_VERSION_LAST_STABLE)-$(BUILD_ID)-$(LOCAL_BUILD_DATE)
GRUB_THEME := android
endif

# $(1): output file
# $(2): dependencies
define make-isoimage-boot-target
	$(call pretty,"Target boot ISO image: $(1)")
	mkdir -p $(GRUB_WORKDIR_BOOT)/boot/grub
	cp $(COMMON_GRUB_PATH)/grub-boot.cfg $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg
	sed -i "s|@GRUB_ANDROID_DISTRIBUTION_NAME@|$(GRUB_ANDROID_DISTRIBUTION_NAME)|g" $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg
	sed -i "s|@STRIPPED_BOARD_KERNEL_CMDLINE_CONSOLE@|$(strip $(BOARD_KERNEL_CMDLINE_CONSOLE))|g" $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg
	sed -i "s|@STRIPPED_TARGET_GRUB_KERNEL_CMDLINE@|$(strip $(TARGET_GRUB_KERNEL_CMDLINE))|g" $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg

	sed -i "s|@GRUB_THEME@|$(GRUB_THEME)|g" $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg
	rm -rf $(GRUB_WORKDIR_BOOT)/boot/grub/themes/$(GRUB_THEME)
	$(if $(GRUB_THEME), cp -r $(COMMON_GRUB_PATH)/themes/$(GRUB_THEME) $(GRUB_WORKDIR_BOOT)/boot/grub/themes/)

	$(GRUB_PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkrescue -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --xorriso=$(GRUB_XORRISO_EXEC) -o $(1) $(2) $(GRUB_WORKDIR_BOOT)
endef

INSTALLED_ISOIMAGE_BOOT_TARGET := $(PRODUCT_OUT)/$(GRUB_ARTIFACT_FILENAME_PREFIX)-boot.iso
INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_TARGET) $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)
$(INSTALLED_ISOIMAGE_BOOT_TARGET): $(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS)
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

.PHONY: isoimage-boot
isoimage-boot: $(INSTALLED_ISOIMAGE_BOOT_TARGET)

.PHONY: isoimage-boot-nodeps
isoimage-boot-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_BOOT_TARGET): ignoring dependencies"
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

endif
