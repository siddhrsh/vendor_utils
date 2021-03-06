WORK_PATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/zip
BUILD_TOP := $(OUT_DIR)/../
PB_BUILD_TYPE := UNOFFICIAL
VERSION := $(shell cat $(BUILD_TOP)/bootable/recovery/variables.h | egrep "define\s+PB_MAIN_VERSION" | tr -d '"' | tr -s ' ' | awk '{ print $$3 }')
PB_VENDOR := vendor/utils
ifeq ($(shell echo $${BETA_BUILD}), BETA)
    PB_BUILD_TYPE := BETA
else
    ifeq ($(shell echo $${PB_OFFICIAL}), true)
        PB_BUILD_TYPE := OFFICIAL
    endif
endif
ifneq ($(PB_BUILD_TYPE), UNOFFICIAL)
    ifneq ($(shell python3 $(BUILD_TOP)/vendor/utils/pb_devices.py verify all $(TARGET_DEVICE); echo $$?),0)
        $(call error Device is not official)
    endif
endif
ZIP_NAME := PBRP-$(TARGET_DEVICE)-$(VERSION)-$(shell date +%Y%m%d-%H%M)-$(PB_BUILD_TYPE).zip
RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/recovery.img
KEYCHECK := $(OUT_DIR)/recovery/root/sbin/keycheck
AB := false
ifeq ($(AB_OTA_UPDATER), true)
    AB := true
endif
.PHONY: pbrp
pbrp: $(INSTALLED_RECOVERYIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
	$(hide) rm -f $(WORK_PATH)/../*.zip
	$(hide) if [ -d $(WORK_PATH) ]; then rm -rf $(WORK_PATH); fi
	$(hide) mkdir $(WORK_PATH)
	$(hide) rsync -avp $(PB_VENDOR)/PBRP $(WORK_PATH)/
	$(hide) mkdir -p $(WORK_PATH)/META-INF/com/google/android
	$(hide) rsync -avp $(PB_VENDOR)/updater/update-* $(WORK_PATH)/META-INF/com/google/android/
	$(hide) rsync -avp $(PB_VENDOR)/updater/awk $(WORK_PATH)/META-INF/
	$(hide) if [ -f $(KEYCHECK) ]; then cp $(KEYCHECK) $(WORK_PATH)/META-INF/; fi
	$(hide) if [ "$(AB)" == "true" ]; then sed -i "s|AB_DEVICE=false|AB_DEVICE=true|g" $(WORK_PATH)/META-INF/com/google/android/update-binary; fi
	$(hide) mkdir $(WORK_PATH)/TWRP
	$(hide) cp $(WORK_PATH)/../recovery.img $(WORK_PATH)/TWRP/
	$(hide) cd $(WORK_PATH) && zip -r $(ZIP_NAME) *
	$(hide) cd $(BUILD_TOP) && mv $(WORK_PATH)/$(ZIP_NAME) $(WORK_PATH)/../
	$(hide) cat $(BUILD_TOP)/vendor/utils/.pb.1
	printf "Recovery Image: %s\n" "$(RECOVERYPATH)"
	printf "Size: %s\n" "$$(du -h $(RECOVERYPATH) | awk '{print $$1}')"
	printf "Flashable Zip: %s\n" "$(OUT_DIR)/target/product/${TARGET_DEVICE}/$(ZIP_NAME)"
	printf "Size: %s\n" "$$(du -h $(WORK_PATH)/../$(ZIP_NAME) | awk '{print $$1}')"
