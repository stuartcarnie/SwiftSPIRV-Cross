# SPIRV-Tools 
SPIRV_TOOLS_DIR?=SPIRV-Tools
SPIRV_TOOLS_EXTERNAL_DIR:=$(SPIRV_TOOLS_DIR)/external
SPIRV_TOOLS_BUILD_DIR:=$(SPIRV_TOOLS_DIR)/build

# glslang
GLSLANG_DIR?=glslang
GLSLANG_BUILD_DIR:=$(GLSLANG_DIR)/build

PROJ_ROOT=..
PROJ_CGLSLANG_DIR=$(PROJ_ROOT)/CGLSLang

ifeq ($(origin CMAKE), undefined)
  CMAKE := $(shell ./find-cmake.sh)
endif
NCPUS:=$(shell sysctl -n hw.ncpu)

# Determine if the current SDK version is Big Sur or later
# 
# NOTE: 
# When running Xcode 12 on Intel hardware, the SDK returns 10.16.
# On Apple SI, SDK returns 11.0
MACOS_SDK_VERSION := $(shell xcrun --sdk macosx --show-sdk-version)

# need to check the current SDK is either >= 10.16 or 11.0
TARGET_ARCHITECTURES ?= $(shell ./version_gte.sh $(MACOS_SDK_VERSION) 11.0 || ./version_gte.sh $(MACOS_SDK_VERSION) 10.16 && echo 'arm64;x86_64' || echo 'x86_64')

all: spirv-update-ext build_info.h

install: all
.PHONY: install

clean: clean-spirv clean-glslang
.PHONY: clean

# glslang

clean-glslang:
	if [[ -e $(GLSLANG_BUILD_DIR) ]]; then $(MAKE) -C $(GLSLANG_BUILD_DIR) clean; fi
	rm -rf $(GLSLANG_BUILD_DIR)
.PHONY: clean-glslang

build_info.h: $(PROJ_CGLSLANG_DIR)/include/glslang/build_info.h $(GLSLANG_BUILD_DIR)/include/glslang/build_info.h
.PHONY: build_info.h

$(PROJ_CGLSLANG_DIR)/include/glslang/build_info.h: $(GLSLANG_BUILD_DIR)/include/glslang/build_info.h
	cp -c $< $@

$(GLSLANG_BUILD_DIR)/include/glslang/build_info.h: $(GLSLANG_DIR)/CHANGES.md $(GLSLANG_DIR)/build_info.h.tmpl $(GLSLANG_BUILD_DIR)/CMakeCache.txt
	# $(MAKE) -C $(GLSLANG_BUILD_DIR) glslang-build-info/fast

$(GLSLANG_BUILD_DIR)/CMakeCache.txt: $(GLSLANG_DIR)/CMakeLists.txt
	mkdir -p $(GLSLANG_BUILD_DIR)
	$(CMAKE) -B $(GLSLANG_BUILD_DIR) -S $(GLSLANG_DIR)

# SPIRV-Tools

clean-spirv:
	if [[ -e $(SPIRV_TOOLS_BUILD_DIR) ]]; then $(MAKE) -C $(SPIRV_TOOLS_BUILD_DIR) clean; fi
	rm -rf $(SPIRV_TOOLS_BUILD_DIR)
	rm -rf $(SPIRV_TOOLS_EXTERNAL_DIR)/SPIRV-Headers
.PHONY : clean-spirv

spirv-generate: $(SPIRV_TOOLS_BUILD_DIR)/CMakeCache.txt
	$(MAKE) -j$(NCPUS) -C $(SPIRV_TOOLS_BUILD_DIR) extinst_tables core_tables enum_string_mapping spirv-tools-build-version
.PHONY: spirv-generate

spirv-update-ext: spirv-generate
	rsync --delete -vaE --include='*.h' --include='*.inc' --exclude='*' SPIRV-Tools/build/ ../CSPIRVTools/ext/

spirv-sync-headers: $(SPIRV_TOOLS_EXTERNAL_DIR)/SPIRV-Headers
	rsync --delete -vaE SPIRV-Tools/external/SPIRV-Headers/include/ ../CSPIRVTools/SPIRV-Headers/include/

$(SPIRV_TOOLS_BUILD_DIR)/CMakeCache.txt: $(SPIRV_TOOLS_DIR)/CMakeLists.txt $(SPIRV_TOOLS_EXTERNAL_DIR)/SPIRV-Headers
	mkdir -p $(SPIRV_TOOLS_BUILD_DIR)
	$(CMAKE) -B $(SPIRV_TOOLS_BUILD_DIR) -S $(SPIRV_TOOLS_DIR) -DCMAKE_BUILD_TYPE=RelWithDebInfo

$(SPIRV_TOOLS_EXTERNAL_DIR)/SPIRV-Headers:
	pushd $(SPIRV_TOOLS_DIR); \
	git clone https://github.com/KhronosGroup/SPIRV-Headers.git external/SPIRV-Headers; \
	cd external/SPIRV-Headers; \
	git checkout `grep "spirv_headers_revision':" ../../DEPS | sed -E "s|.*': '||;s|',||"`; \
	popd

print:
	@echo '$(TARGET_ARCHITECTURES)'
