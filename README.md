![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# VGA Tic‑Tac‑Toe

An FPGA‑based implementation of the classic Tic‑Tac‑Toe game with VGA output, designed for Tiny Tapeout.

Link to VGA Playground: https://vga-playground.com/?repo=https://github.com/bagaHU/tt_um_vga_tictactoe

<img width="278" height="269" alt="image" src="https://github.com/user-attachments/assets/f2a44560-0191-4484-a170-13ed9bf27018" />

## 2D View

<img width="2021" height="1550" alt="image" src="https://github.com/user-attachments/assets/7304182d-a692-42a0-a517-32a4acb5eefd" />

## 3D View

Link to the 3D Viewer: https://gds-viewer.tinytapeout.com/?model=https://bagahu.github.io/tt_um_vga_tictactoe/tinytapeout.oas&pdk=ihp-sg13g2

<img width="854" height="677" alt="image" src="https://github.com/user-attachments/assets/f3f695b1-0080-4b65-8485-697bf8ad8485" />

## Stats 

### Routing stats

| Utilisation (%) | Wire length (um) |
|-------------|------------------|
| 51.204 % | 33733 |

### Cell usage by Category

| Category | Cells | Count |
|---------------|----------|-------|
|Fill | [decap](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#10) [fill](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#21) | 1746|
|Combo Logic | [a21oi](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#1) [o21ai](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#39) [a21o](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#7) [a221oi](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#2) [a22oi](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#3) | 269|
|NOR | [nor2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#35) [nor3](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#36) [xnor2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#47) [nor4](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#37) [nor2b](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#34) | 263|
|NAND | [nand2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#30) [nand3b](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#31) [nand2b](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#28) [nand4](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#33) [nand3](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#32) | 248|
|Buffer | [buf](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#9) | 106|
|AND | [and2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#4) [and3](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#5) [and4](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#6) | 82|
|Misc | [dlygate4sd3](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#19) | 67|
|OR | [or2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#40) [or3](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#41) [xor2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#48) [or4](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#42) | 62|
|Flip Flops | [dfrbpq](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#0) | 57|
|Inverter | [inv](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#23) | 37|
|Multiplexer | [mux2](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#26) [mux4](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/refs/heads/main/ihp-sg13g2/libs.ref/sg13g2_stdcell/doc/sg13g2_stdcell_typ_1p20V_25C.pdf#27) | 9|
### 1200 total cells (excluding fill and tap cells)
