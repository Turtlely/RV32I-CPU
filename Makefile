.PHONY: all lint test clean asm execute debug trace viewer vcd
IV = iverilog
IVFLAGS = -g2012 -Wall -Wno-timescale -Wno-sensitivity-entire-array
RISCV_PREFIX ?= riscv64-unknown-elf-
RISCV_AS = $(RISCV_PREFIX)as
RISCV_LD = $(RISCV_PREFIX)ld
RISCV_OBJCOPY = $(RISCV_PREFIX)objcopy
RISCV_ASFLAGS = -march=rv32i -mabi=ilp32
RISCV_LDFLAGS = -m elf32lriscv -Ttext=0x00000000 -nostdlib
DEBUG_CYCLES ?= 20
DEBUG_MEM_BYTES ?= 32
TRACE_CYCLES ?= 100
RTL = $(wildcard rtl/*v)
TB = $(wildcard tb/*v)
TEST_NAMES = alu alu_mux branch_cond control counter decoder mem pc pc_mux regfile wb_mux cpu
TEST_BINS = $(addprefix sim/,$(addsuffix _tb.vvp,$(TEST_NAMES)))

all: test

lint:
	$(IV) $(IVFLAGS) -t null $(RTL) $(TB)
	wsl verilator --lint-only -Wall --top-module counter $(RTL)
	@echo lint passed :D

test: | sim
	@powershell -NoProfile -Command "$$failed = 0; $$rtl = @(Get-ChildItem rtl/*.v | ForEach-Object FullName); foreach ($$name in ('$(TEST_NAMES)' -split ' ')) { Write-Host ('=== ' + $$name + ' ==='); & '$(IV)' '-g2012' '-Wall' '-s' ($$name + '_tb') '-o' ('sim/' + $$name + '_tb.vvp') $$rtl ('tb/' + $$name + '_tb.v'); if ($$LASTEXITCODE -eq 0) { & 'vvp' ('sim/' + $$name + '_tb.vvp') }; if ($$LASTEXITCODE -ne 0) { $$failed = 1 } }; exit $$failed"

sim/%_tb.vvp: tb/%_tb.v $(RTL) | sim
	$(IV) $(IVFLAGS) -s $*_tb -o $@ $(RTL) $<

sim:
	mkdir -p sim

clean:
	rm -f $(TEST_BINS) sim/*.vcd sim/program_trace.csv sw/program.o sw/program.elf sw/program.hex

asm: sw/program.hex

sw/program.o: sw/program.s
	$(RISCV_AS) $(RISCV_ASFLAGS) -o $@ $<

sw/program.elf: sw/program.o
	$(RISCV_LD) $(RISCV_LDFLAGS) -o $@ $<

sw/program.hex: sw/program.elf
	$(RISCV_OBJCOPY) -O verilog $< $@

execute:
	$(MAKE) sim/program_tb.vvp
	vvp sim/program_tb.vvp

debug: sim/program_tb.vvp
	vvp $< +debug +cycles=$(DEBUG_CYCLES) +mem_bytes=$(DEBUG_MEM_BYTES)

trace: sim/program_tb.vvp
	vvp $< +trace +cycles=$(TRACE_CYCLES)

viewer: trace
	powershell -NoProfile -Command "Start-Process 'tools/trace_viewer.html'"

vcd: sim/program.vcd

sim/program.vcd: sim/program_tb.vvp
	vvp $<

sim/program_tb.vvp: tb/program_tb.v sw/program.hex $(RTL) | sim
	$(IV) $(IVFLAGS) -s program_tb -o $@ $(RTL) tb/program_tb.v
