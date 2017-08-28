
ifneq (1,$(RULES))

SIM_TARGETS += $(TOP_MODULE).qpf $(TOP_MODULE).map $(TOP_MODULE).fit $(TOP_MODULE).sta $(TOP_MODULE).sim

IMG_TARGETS += $(TOP_MODULE).qpf $(TOP_MODULE).map $(TOP_MODULE).fit $(TOP_MODULE).sta $(TOP_MODULE).sof $(TOP_MODULE).rbf

DATAFILES += $(SYNTH_DIR)/scripts/$(TOP_MODULE).sdc

ifneq (,$(DATAFILES))
QUARTUS_MAP_DEPS += copy_datafiles
QUARTUS_MAP_DEPS += copy_datafiles
endif

else


ifeq (,$(wildcard $(SYNTH_DIR)/scripts/$(TOP_MODULE)_project.f))
QPF_FLAGS += -f $(SYNTH_DIR_A)/scripts/$(TOP_MODULE)_quartus.f
endif


$(TOP_MODULE).qpf : $(PRE_QPF_TARGETS)
	echo "SYNTH_DIR=$(SYNTH_DIR)"
	quartus_sh -t $(SYNTHSCRIPTS_DIR_A)/lib/altera/quartus_utils.tcl \
		-project $(TOP_MODULE) \
		-top $(TOP_MODULE) \
		+define+FPGA \
		$(TOP_MODULE).sdc \
		-family "Cyclone V" \
		-device "$(DEVICE)" \
		-f $(SYNTHSCRIPTS_DIR_A)/lib/altera/quartus_common_settings.f \
		$(QPF_FLAGS)

%.map : %.qpf $(QUARTUS_MAP_DEPS)
	quartus_map $(subst .qpf,,$(*))
	touch $@
	
%.fit : %.map
	quartus_fit $(subst .map,,$(*))
	touch $@
	
%.sim : %.fit
	quartus_eda $(subst .fit,,$(*)) --tool=modelsim --format=verilog --gen_testbench 
	quartus_eda $(subst .fit,,$(*)) \
		--simulation --tool=modelsim --format=verilog \
		--maintain_design_hierarchy=on \
		--gen_script=rtl_and_gate_level
	touch $@
	
%.sta : %.fit	
	quartus_sta $(subst .fit,,$(*))
	touch $@
	
%.sof : %.fit	
	quartus_asm $(subst .fit,,$(*))
	cp output/$(subst .fit,,$(*)).sof $@
	
%.rbf : %.sof
	quartus_cpf -c $^ $@

	
endif
