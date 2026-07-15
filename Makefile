GHDL := ghdl
TB_SRC := $(wildcard tb_*.vhd)
SRC := $(filter-out $(TB_SRC),$(wildcard *.vhd))
WAVE := $(addsuffix .ghw,$(basename $(TB_SRC)))

.PHONY: all check run clean

all: check run

check: $(SRC) $(TB_SRC)
	$(GHDL) -a $?

run: check $(WAVE)

%.ghw: $(SRC) %.vhd
#	Elaboration is optional for the mcode backend
#	$(GHDL) -e $*
	$(GHDL) -r $* --wave=$@

clean:
	$(GHDL) --remove
	del *.ghw
