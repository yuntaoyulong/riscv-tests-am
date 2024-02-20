TEST_ISA = i m #a f d c
EXCLUDE_TEST = fence_i ma_data

SUPPORTED_AM_ISA = riscv64 riscv32 riscv64e riscv32e riscv32mini
AM_ISA = $(word 1, $(subst -, ,$(ARCH)))

ifeq ($(findstring $(MAKECMDGOALS),clean),)  # ignore the commands if the target is clean
ifeq ($(filter $(SUPPORTED_AM_ISA), $(AM_ISA)), )
  $(error Expected $$ISA in {$(SUPPORTED_AM_ISA)}, Got "$(AM_ISA)")
endif

XLEN = $(shell echo $(AM_ISA) | grep -o '32\|64')
TEST_DIR = $(TEST_ISA:%=isa/rv$(XLEN)u%)
ORIGINAL_SSRCS := $(shell find $(TEST_DIR) -name "*.S" | sort)
endif

EXCLUDE_SSRCS := $(foreach f,$(EXCLUDE_TEST),$(wildcard isa/*/$(f).S))
ORIGINAL_SSRCS := $(filter-out $(EXCLUDE_SSRCS),$(ORIGINAL_SSRCS))

RESULT = .result
$(shell > $(RESULT))

COLOR_RED   = \033[1;31m
COLOR_GREEN = \033[1;32m
COLOR_NONE  = \033[0m

SLASH_REPLACER = _SLASH_

define shortform
  $(subst isa/,,$(subst $(SLASH_REPLACER),/,$(1)))
endef

LINK_SSRCS = $(subst /,$(SLASH_REPLACER),$(ORIGINAL_SSRCS))
ALL = $(basename $(LINK_SSRCS))

all: $(addprefix Makefile-, $(ALL))
	@echo "test list:" $(call shortform,$(ALL))

$(ALL): %: Makefile-%

build/%.S:
	mkdir -p $(@D)
	ln -s $(abspath $(subst $(SLASH_REPLACER),/,$(notdir $@))) $@

Makefile-%: build/%.S
	@/bin/echo -e "NAME = $*\nSRCS = $<\nINC_PATH += $(shell pwd)/env/p $(shell pwd)/isa/macros/scalar\ninclude $${AM_HOME}/Makefile" > $@
	@if make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS); then \
		printf "[%14s] $(COLOR_GREEN)PASS!$(COLOR_NONE)\n" $(call shortform,$*) >> $(RESULT); \
	else \
		printf "[%14s] $(COLOR_RED)FAIL!$(COLOR_NONE)\n" $(call shortform,$*) >> $(RESULT); \
	fi
	-@rm -f Makefile-$*

run: all
	@cat $(RESULT)
	@rm $(RESULT)

gdb: all

clean:
	rm -rf Makefile-* build/

.PHONY: all run clean $(ALL)
