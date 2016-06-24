
DEVICE ?= cyclonev
TOOL ?= quartus
ROM_FILE ?= rom.hex
# MEM_FILE ?= rom.dat

.phony: all sim target_build

all :
	echo "Error: specify target of sim or img"
	exit 1
	
uname_o := $(shell uname -o)

ifeq ($(uname_o),Cygwin)
	SYNTH_DIR_A := $(shell cygpath -w $(SYNTH_DIR) | sed -e 's%\\%/%g')
else
	SYNTH_DIR_A := $(SYNTH_DIR)
endif
	
include $(SYNTHSCRIPTS_DIR)/mkfiles/synth_mk/synth_mk_$(TOOL).mk

vpath %.f $(SRC_DIRS)
vpath %.sdc $(SRC_DIRS)
vpath %.dat $(SRC_DIRS)


target_build :
	if test "x$(TARGET_MAKEFILE)" != "x"; then \
		$(MAKE) -f $(TARGET_MAKEFILE) build; \
	fi

RULES := 1

include $(SYNTHSCRIPTS_DIR)/mkfiles/synth_mk/synth_mk_$(TOOL).mk
