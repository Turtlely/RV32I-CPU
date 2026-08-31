.PHONY: all lint
IV = iverilog
IVFLAGS = -g2012 -Wall
RTL = $(wildcard rtl/*v)
TB = $(wildcard tb/*v)

all: sim/regfile.vvp sim/regfile.vcd sim/counter.vvp sim/counter.vcd 

lint:
	$(IV) $(IVFLAGS) -t null $(RTL) $(TB)
	wsl verilator --lint-only -Wall --top-module counter $(RTL)
	@echo lint passed :D


sim/regfile.vvp: rtl/regfile.v tb/regfile_tb.v
	$(IV) $(IVFLAGS) -o $@ $^

sim/regfile.vcd: sim/regfile.vvp
	vvp $^


sim/counter.vvp: rtl/counter.v tb/counter_tb.v
	$(IV) $(IVFLAGS) -o $@ $^

sim/counter.vcd: sim/counter.vvp
	vvp $^
