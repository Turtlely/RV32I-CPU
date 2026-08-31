# RV32I-CPU

# Directory Structure

```
riscv-cpu/
├── rtl/                    # hardware modules
│   ├── alu.v
│   ├── regfile.v
│   ├── imm_gen.v
│   ├── control.v
│   ├── cpu.v               # entry point
│   └── mem.v
├── tb/                     # testbenches
│   ├── alu_tb.v
│   ├── regfile_tb.v
│   └── cpu_tb.v
├── sw/                     # CPU executable test programs (TODO)
│   ├── test1.s
│   └── test1.hex           
└── sim/                    # build artifacts and simulation folder
    └── wave.vcd
```

# Prerequisites
This project uses iverilog (11.0.0) and gtkwave (3.3.100)

Installing iverilog:
> Windows (Chocolatey): ```choco install iverilog gtkwave make```

> Debian / Ubuntu: ```sudo apt install iverilog gtkwave make```

> MacOS (Homebrew): ```brew install icarus-verilog gtkwave make```


# Usage

This project uses Make.

Linter:
> ``` make lint```

Compile and simulate all files:
> ``` make all```

Compile using ```iverilog```:
> ```iverilog -g2012 -o sim/counter.vvp rtl/counter.v tb/counter_tb.v```
- Produces a .vvp simulation file

Simulate using ```vvp```:
> ``` vvp sim/counter.vvp```
- Produces a .vcd file for GTKWave

View using ```gtkwave```:
> ``` gtkwave sim/counter.vcd```

Alternatively, you can simply run ```make```
> ``` make sim/counter.vvp```
> ```make sim/counter.vcd```

