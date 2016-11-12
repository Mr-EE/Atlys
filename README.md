# Atlys

My playground for the Spartan 6 FPGA ATLAS development board from Digilent.

http://store.digilentinc.com/atlys-spartan-6-fpga-trainer-board-limited-time-see-nexys-video/

Not that much documentation since I was only playing around but here's the quick breakdown:

- ATLYS_Gigabit:
  - My platform for the FPGA ATLYS development board. The main bus is a 16-bit Wishbone bus. The UART is the master of the bus and via the Bazlink protol (see "docs" folder) you can control various parts for the development board, including the Gigabit Ethernet IC
