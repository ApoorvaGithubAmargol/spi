# SPI Master-Slave Controller in Verilog

This project implements an **SPI (Serial Peripheral Interface) master and slave controller in Verilog**.

The design supports **all four SPI modes (0–3)**, **8-bit and 16-bit transfers**, register read/write operations, and basic error handling. The RTL was simulated using **Icarus Verilog**, and SPI timing was verified using **GTKWave**.

## Features

- Supports SPI Mode 0, Mode 1, Mode 2 and Mode 3
- Supports 8-bit and 16-bit transfers
- Generates the SPI clock from the system clock
- Handles MOSI and MISO data transfer
- Supports register read and write operations
- Provides `busy`, `done` and `error` status signals on the master
- Includes a register file on the slave side
- Includes an integration testbench
- Includes a dedicated waveform/debug testbench
- Verifies SPI timing across all four modes

## Project Structure

```text
spi/
├── rtl/
│   ├── spi_clock_gen.v
│   ├── spi_master_fsm.v
│   ├── spi_master_shift_reg.v
│   ├── spi_master.v
│   ├── spi_regfile.v
│   ├── spi_slave_reg_controller.v
│   ├── spi_slave_fsm.v
│   ├── spi_slave_shift_reg.v
│   ├── spi_slave.v
│   └── spi_master_slave_top.v
│
├── tb/
│   ├── tb_spi_master_slave.v
│   └── tb_spi_waveform_debug.v
│
└── sim/
    └── Simulation outputs and VCD waveform files
```

### Directory Description

- **`rtl/`** — Synthesizable Verilog RTL for the SPI master, slave, FSMs, shift registers, clock generation and register interface.
- **`tb/`** — Verilog testbenches used for functional verification and waveform debugging.
- **`sim/`** — Generated simulation executables and VCD waveform files.

## Basic Architecture

The design is divided into separate master and slave blocks. Clock generation, FSMs, shift registers and register handling are implemented as separate modules to simplify design, debugging and verification.

<img width="450" height="600" alt="image" src="https://github.com/user-attachments/assets/5c034897-9cf5-488c-8920-b59427ea0658" />


## SPI Modes

| Mode | CPOL | CPHA | Leading Edge | Trailing Edge |
|------|------|------|--------------|---------------|
| 0    | 0    | 0    | Rising       | Falling       |
| 1    | 0    | 1    | Rising       | Falling       |
| 2    | 1    | 0    | Falling      | Rising        |
| 3    | 1    | 1    | Falling      | Rising        |

For **CPHA = 0**, data is sampled on the leading edge and changed on the trailing edge.

For **CPHA = 1**, data is changed on the leading edge and sampled on the trailing edge.

During testing of the different SPI modes, a timing issue was identified in the master's MOSI generation for **CPHA = 1**. The transmit logic was modified so that the correct MOSI bit remains stable until the slave samples it.

After this correction, the integration tests passed for all four SPI modes.

## Register Interface

The first byte of an SPI transaction contains the read/write control bit and register address.

```text
bit 7     : Read/Write
bits 6:0  : Register address
```

The MSB determines the operation:

```text
MSB = 0  → Write
MSB = 1  → Read
```

### Write Operation

For example, to write `0x5A` to register `0x01`:

```text
Register address = 0x01
Data             = 0x5A

SPI transfer = 0x015A
```

### Read Operation

To read register `0x01`:

```text
Read command = 0x81
Dummy byte   = 0x00

SPI transfer = 0x8100
```

If register `0x01` contains `0x5A`, the slave returns:

```text
0x005A
```

The complete transaction is:

```text
Master → Slave : 0x8100
Slave  → Master: 0x005A
```

The dummy byte is transmitted by the master to generate the SPI clock cycles required for the slave to shift out the register data.

## Main RTL Blocks

### `spi_clock_gen.v`

Generates the SPI clock from the system clock and provides the required timing for the master.

### `spi_master_fsm.v`

Controls the master transaction, including chip select, transfer states and SPI sampling/shifting edges for each mode.

### `spi_master_shift_reg.v`

Handles serial data transmission and reception on the master side. It manages TX data, RX data, MOSI and the transfer bit counter.

### `spi_slave_fsm.v`

Controls the slave-side SPI transaction and determines when data should be sampled or shifted based on CPOL and CPHA.

### `spi_slave_shift_reg.v`

Receives data from MOSI and shifts response data onto MISO.

### `spi_slave_reg_controller.v`

Decodes the SPI command and determines whether the transaction is a register read or write.

### `spi_regfile.v`

Stores the slave's internal register values.

### `spi_master_slave_top.v`

Connects the master and slave modules together and provides the top-level SPI interface.

## Verification

Two main testbenches are used for verification.

### Integration Testbench

`tb_spi_master_slave.v` verifies:

- SPI Modes 0–3
- 8-bit transfers
- 16-bit transfers
- Register writes
- Register reads
- Register data operations
- Error handling
- Attempting a transfer while the master is busy

The integration testbench passes for all four SPI modes.

### Waveform Debug Testbench

`tb_spi_waveform_debug.v` is used to inspect SPI timing using GTKWave.

It tests read and write operations in all four modes:

```text
Mode 0 → Write + Read
Mode 1 → Write + Read
Mode 2 → Write + Read
Mode 3 → Write + Read
```

The waveforms are used to verify the relationship between `CS`, `SCLK`, `MOSI` and `MISO`, with particular attention to the CPHA = 1 timing behavior.

## Simulation

The project can be simulated using **Icarus Verilog**.

### Integration Testbench

From the project root directory:

```bash
iverilog -o sim/spi_integration \
rtl/spi_clock_gen.v \
rtl/spi_master_fsm.v \
rtl/spi_master_shift_reg.v \
rtl/spi_master.v \
rtl/spi_regfile.v \
rtl/spi_slave_reg_controller.v \
rtl/spi_slave_fsm.v \
rtl/spi_slave_shift_reg.v \
rtl/spi_slave.v \
rtl/spi_master_slave_top.v \
tb/tb_spi_master_slave.v
```

Run the simulation:

```bash
vvp sim/spi_integration
```

### Waveform Simulation

Compile the waveform testbench:

```bash
iverilog -o sim/spi_waveform \
rtl/spi_clock_gen.v \
rtl/spi_master_fsm.v \
rtl/spi_master_shift_reg.v \
rtl/spi_master.v \
rtl/spi_regfile.v \
rtl/spi_slave_reg_controller.v \
rtl/spi_slave_fsm.v \
rtl/spi_slave_shift_reg.v \
rtl/spi_slave.v \
rtl/spi_master_slave_top.v \
tb/tb_spi_waveform_debug.v
```

Run:

```bash
vvp sim/spi_waveform
```

This generates the VCD waveform file:

```text
sim/spi_waveform.vcd
```

Open the waveform using GTKWave:

```bash
gtkwave sim/spi_waveform.vcd
```

## Tools Used

- **Verilog HDL**
- **Icarus Verilog**
- **GTKWave**
- **WSL / Ubuntu**
- **VS Code**

## Project Status

**Completed**

The SPI master-slave controller has been functionally simulated and verified for:

- All four SPI modes
- 8-bit and 16-bit transfers
- Register read/write operations
- Master/slave integration
- SPI timing and waveform behavior


## Verification Results

The SPI master-slave design was tested for all four SPI modes using the integration testbench.

| SPI Mode | Write Operation                   | Read Operation         | Result |
| -------- | --------------------------------- | ---------------------- | ------ |
| Mode 0   | `0x5A` written to register `0x01` | Read returned `0x005A` | PASS   |
| Mode 1   | `0x5A` written to register `0x01` | Read returned `0x005A` | PASS   |
| Mode 2   | `0x5A` written to register `0x01` | Read returned `0x005A` | PASS   |
| Mode 3   | `0x5A` written to register `0x01` | Read returned `0x005A` | PASS   |
