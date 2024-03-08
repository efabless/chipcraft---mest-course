# Reference Designs for Makerchip Tiny Tapeout Projects

This directory collects reference designs and starter templates that may be useful for final project and the Makerchip-based Tiny Tapeout ecosystem in general.

Here are some final projects from ChipCraft 1 AFRL OH:

  * [Universal Asynchronous Receiver-Transmitter (UART) programmable RISC-V CPU](https://github.com/enieman/uart_programmable_rv32i): This project connects the course CPU's IMem and DMem via UART, enabling the CPU to be programmed from an external source. The DMem can be read via UART as well.
    Next steps include improved modularity, additional testing, CPU extensions, and software programmability.
  * [Serial Peripheral Interface (SPI) programmable RISC-V CPU](https://github.com/devin-macy/tt06-riscv32i-spi-wrapper/blob/main/docs/info.md): This project connects the course CPU's IMem via SPI, enabling the CPU to be programmed from an external source. It provides
    memory-mapped SPI control registers for transmitting and receiving data as well. Next steps include modularity of the UART controller, further testing/debugging, and proper CSR support in the CPU.
  * [Timer](https://github.com/JHsu01/tt06-simple-clock): Counts in seconds on a 2-digit 7-segment display. Next steps include support for minutes/hours, alarms, real-time clock, etc.
  * [Open FPGA Configurable Logic Block](https://github.com/MisguidedBadge/tt06-tzeentchFPGA): A configurable logic block (CLB) built using Open FPGA. Next steps include external programmability using SPI or UART.

Final projects from ChipCraft 2 Crane:

  * Andrew N. Die roller: TBD
  * Max, Amada, Andrew: Calculator: TBD
  * Brent, Bo, Lee: AES encryption: https://github.com/bogibso15/efabless-tt-fpga-dl-demo
  * Joel, Catherine: Traffic light controller: TBD
  * Isaac: Multiplier: TBD
  * Neal: Stopwatch: TBD
  * Bryce, Grant, Shakhar: UART SHA encryption: 
  * Tristan, Gabriel, Connor: Timer game: https://github.com/gabejessil/tt06-verilog-template
