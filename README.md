# RV32I five-stage CPU

This project is an educational implementation of a pipelined 32-bit RISC-V
processor. It implements the base RV32I integer instructions used by the test
program and resolves common pipeline hazards with forwarding, stalling, and
flushing.

## Pipeline overview

```text
               load-use stall
                      |
                      v
 IF  ->  IF/ID  ->  ID  ->  ID/EX  ->  EX  ->  EX/MEM  ->  MEM  ->  MEM/WB  ->  WB
 PC      instr      decode          ALU       result       data       value      rd
  ^                                    |
  |                                    +-- branch/jump target and flush
  +------------------------------------+

                         EX/MEM -----+
                                     +--> operand forwarding --> EX
                         MEM/WB -----+
```

Each signal inside `cpu.v` ends with the stage where it is currently valid:

- `_if`: instruction fetch
- `_id`: instruction decode and register read
- `_ex`: execute and branch resolution
- `_mem`: data-memory access
- `_wb`: register write-back

For example, `destination_id` is the decoded `rd` field, while
`destination_wb` is the register number that is ready to be written.

## Recommended reading order

1. `rtl/cpu.v` — follow the five stages from top to bottom.
2. `rtl/decoder.v` and `rtl/control.v` — see how an instruction becomes fields
   and control signals.
3. `rtl/id_ex_reg.v`, `rtl/ex_mem_reg.v`, and `rtl/mem_wb_reg.v` — see which
   values must travel with an instruction.
4. `rtl/alu_mux.v`, `rtl/alu.v`, and `rtl/branch_cond.v` — study execution.
5. `rtl/hazard_detect.v` and `rtl/forward_unit.v` — study pipeline hazards.
6. `tb/cpu_tb.v` — see directed pipeline tests.
7. `sw/program.s` — run a self-checking stress program on the complete CPU.

## Project layout

```text
rtl/
  cpu.v               top-level pipeline, organized in stage order
  pc.v                program-counter register
  decoder.v           instruction fields and immediate generation
  control.v           instruction control decoding
  regfile.v            32 integer registers
  alu_mux.v            ALU operand selection
  alu.v                arithmetic, logic, shifts, and comparisons
  branch_cond.v        conditional-branch decision
  pc_mux.v             sequential/branch/jump PC selection
  mem.v                byte-addressable instruction/data memory model
  wb_mux.v             write-back value selection
  if_id_reg.v          IF-to-ID pipeline register
  id_ex_reg.v          ID-to-EX pipeline register
  ex_mem_reg.v         EX-to-MEM pipeline register
  mem_wb_reg.v         MEM-to-WB pipeline register
  hazard_detect.v      load-use stall detection
  forward_unit.v       EX operand forwarding control

tb/                    unit and end-to-end testbenches
sw/program.s            self-checking pipeline stress program
tools/trace_viewer.html five-stage execution-trace viewer
sim/                   generated simulation files
```

## Prerequisites

- Icarus Verilog
- GNU Make
- GTKWave, optionally
- A `riscv64-unknown-elf-` toolchain for assembling `sw/program.s`

Windows with Chocolatey:

```powershell
choco install iverilog gtkwave make
```

Debian or Ubuntu:

```sh
sudo apt install iverilog gtkwave make
```

## Testing

Run every unit and CPU test:

```powershell
make test
```

Run only the complete CPU test:

```powershell
make sim/cpu_tb.vvp
vvp sim/cpu_tb.vvp
```

Run lint checks:

```powershell
make lint
```

## Running the stress program

Assemble the program and generate `sw/program.hex`:

```powershell
make asm
```

Generate a pipeline trace and open the viewer:

```powershell
make viewer
```

The stress program writes these final values to data memory:

```text
address 248: 0x600DCAFE  success signature
address 252: 1           pass
address 252: -N          failed test N
```

The viewer shows all five occupied stages, bubbles, stalls, flushes, register
commits, memory writes, registers, and data memory for each cycle.

## Waveforms

```powershell
make vcd
gtkwave sim/program.vcd
```

Useful top-level signal groups are named by stage, such as `pc_if`,
`instruction_id`, `alu_result_ex`, `memory_read_value_mem`, and
`writeback_value_wb`.
