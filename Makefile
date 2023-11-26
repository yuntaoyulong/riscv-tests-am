TEST_ISA = i m #a f d c
EXCLUDE_TEST = fence_i ma_data

SUPPORTED_AM_ISA = riscv64 riscv32 riscv64e riscv32e
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

SLASH_REPLACER = _SLASH_

LINK_SSRCS = $(subst /,$(SLASH_REPLACER),$(ORIGINAL_SSRCS))
ALL = $(basename $(LINK_SSRCS))

all: $(addprefix Makefile-, $(ALL))
	@echo "test list:" $(subst isa/,,$(subst $(SLASH_REPLACER),/,$(ALL)))

$(ALL): %: Makefile-%

build/%.S:
	mkdir -p $(@D)
	ln -s $(abspath $(subst $(SLASH_REPLACER),/,$(notdir $@))) $@

Makefile-%: build/%.S
	@/bin/echo -e "NAME = $*\nSRCS = $<\nINC_PATH += $(shell pwd)/env/p $(shell pwd)/isa/macros/scalar\ninclude $${AM_HOME}/Makefile" > $@
	-@make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS)
	-@rm -f Makefile-$*

run: all

clean:
	rm -rf Makefile-* build/

.PHONY: all run clean $(ALL)
