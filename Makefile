GHDL:=ghdl
SRC:=$(wildcard *.vhd)
TB_SRC:=$(wildcard tb_*.vhd)
UNIT:=$(basename $(SRC))
TB_UNIT:=$(basename $(TB_SRC))
WAVE:=$(addsuffix .ghw,$(TB_UNIT))
WORK_OBJ:=work-obj93.cf

.PHONY: tb all run clean check

tb: $(WORK_OBJ) $(TB_UNIT)

all: $(WORK_OBJ) $(UNIT)

run: $(WORK_OBJ) $(WAVE)

clean:
	rm -f *.cf
	rm -f *.ghw

check: $(SRC)
	$(GHDL) -s $^
	$(GHDL) -a $^

$(WORK_OBJ): $(SRC)
	$(GHDL) -i $?

%.ghw: %
	$(GHDL) -r $(*F) --wave=$@

%: %.vhd
	$(GHDL) -m -v $@
