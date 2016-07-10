
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

DATAFILES_DST := $(shell echo $(DATAFILES) | sed -e 's@[^\s][^\s]*=\([^\s][^\s]*\)@\1@g')
DATAFILES_SRC := $(shell echo $(DATAFILES) | sed -e 's@\([^\s][^\s]*\)=[^\s][^\s]*@\1@g')
	
include $(SYNTHSCRIPTS_DIR)/mkfiles/synth_mk/synth_mk_$(TOOL).mk

vpath %.f $(SRC_DIRS)
vpath %.sdc $(SRC_DIRS)
vpath %.dat $(SRC_DIRS)


target_build :
	if test "x$(TARGET_MAKEFILE)" != "x"; then \
		$(MAKE) -f $(TARGET_MAKEFILE) build; \
	fi
	


RULES := 1

copy_datafiles: $(DATAFILES_SRC)
	echo "copy_datafiles: $(DATAFILES) DST=$(DATAFILES_DST) SRC=$(DATAFILES_SRC)"
	cd $(BUILD_DIR) ; for spec in $(DATAFILES); do \
		src=`echo $$spec | sed -e 's@\([^\s][^\s]*\)=[^\s][^\s]*@\1@g'` ; \
		dst=`echo $$spec | sed -e 's@[^\s][^\s]*=\([^\s][^\s]*\)@\1@g'` ; \
		echo "src=$$src dst=$$dst" ; \
		if test "$$src" = "$$dst"; then \
			name=`basename $$src`; \
			if test "$$src" != "$(BUILD_DIR)/$$name"; then \
				cp $$src . ; \
				echo "Note: Copying datafile $$src to the build directory"; \
			else \
				echo "Note: Datafile $$name already in the build directory"; \
			fi \
		else \
			echo "Note: Copying datafile $$src to $$dst in the build directory"; \
			cp $$src $$dst ; \
		fi \
	done

sim : sim_main

sim_pre : $(SIM_PRE_TARGETS)

sim_main : $(SIM_TARGETS)

img : img_main

img_pre : $(IMG_PRE_TARGETS)

img_main : img_pre $(IMG_TARGETS)



include $(SYNTHSCRIPTS_DIR)/mkfiles/synth_mk/synth_mk_$(TOOL).mk
