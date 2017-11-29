
DEVICE ?= cyclonev
TOOL ?= quartus
ROM_FILE ?= rom.hex
# MEM_FILE ?= rom.dat

.phony: all sim target_build

IMG_TARGETS += img-post
SIM_TARGETS += sim-post

all :
	echo "Error: specify target of sim or img"
	exit 1
	
uname_o := $(shell uname -o)

ifeq ($(uname_o),Cygwin)
	SYNTH_DIR_A := $(shell cygpath -w $(SYNTH_DIR) | sed -e 's%\\%/%g')
else
	SYNTH_DIR_A := $(SYNTH_DIR)
endif

DATAFILES_DST = $(shell echo $(DATAFILES) | sed -e 's@[^\s][^\s]*=\([^\s][^\s]*\)@\1@g')
DATAFILES_SRC = $(shell echo $(DATAFILES) | sed -e 's@\([^\s][^\s]*\)=[^\s][^\s]*@\1@g')

MK_INCLUDES += $(SYNTHSCRIPTS_DIR)/mkfiles/synth_mk/synth_mk_$(TOOL).mk

vpath %.f $(SRC_DIRS)
vpath %.sdc $(SRC_DIRS)
vpath %.dat $(SRC_DIRS)

include $(MK_INCLUDES)


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


img-pre-compile : $(IMG_PRECOMPILE_TARGETS)
	@touch $@
	
img-compile : img-pre-compile $(IMG_COMPILE_TARGETS)
	@touch $@
	
$(IMG_COMPILE_TARGETS) : img-pre-compile

img-post-compile : img-compile $(IMG_POSTCOMPILE_TARGETS)
	@touch $@

$(IMG_POSTCOMPILE_TARGETS) : img-compile

img-post : img-post-compile $(IMG_POST_TARGETS)	
	@touch $@
	
$(IMG_POST_TARGETS) : img-post-compile

img : img-post
	@echo "img-pre-compile: $(IMG_PRECOMPILE_TARGETS)"
	@echo "img-compile: $(IMG_COMPILE_TARGETS)"
	@echo "img-post-compile: $(IMG_POSTCOMPILE_TARGETS)"

sim-pre-compile : $(SIM_PRECOMPILE_TARGETS)
	@touch $@
	
sim-compile : sim-pre-compile $(SIM_COMPILE_TARGETS)
	@touch $@
	
$(SIM_COMPILE_TARGETS) : sim-pre-compile

sim-post-compile : sim-compile $(SIM_POSTCOMPILE_TARGETS)
	@touch $@

$(SIM_POSTCOMPILE_TARGETS) : sim-compile

sim-post : $(SIM_POST_TARGETS)	
	@touch $@
	
sim : sim-post
	@echo "sim-pre-compile: $(SIM_PRECOMPILE_TARGETS)"
	@echo "sim-compile: $(SIM_COMPILE_TARGETS)"
	@echo "sim-post-compile: $(SIM_POSTCOMPILE_TARGETS)"

include $(MK_INCLUDES)

