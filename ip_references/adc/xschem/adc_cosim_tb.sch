v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
B 2 160 620 960 1020 {flags=graph
y1=0
y2=3.3
ypos1=0
ypos2=3.3
divy=5
subdivy=1
unity=1
x1=3.3693349e-06
x2=7.6378796e-06
divx=5
subdivx=1
xlabmag=1.0
ylabmag=1.0


dataset=-1
unitx=1
logx=0
logy=0
digital=1
color="4 5 6 7"
node="d[11:0];d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0
hold
ena
rst"}
B 2 160 1040 960 1440 {flags=graph
y1=-0.39
y2=2.7
ypos1=0
ypos2=3.3
divy=5
subdivy=1
unity=1
x1=3.3693349e-06
x2=7.6378796e-06
divx=5
subdivx=1
xlabmag=1.0
ylabmag=1.0


dataset=-1
unitx=1
logx=0
logy=0
digital=0

color="10 15"
node="vout
vin"}
T {12-bit ADC cosimulation testbench} 0 0 0 0 1 1 {}
T {See README;  works with ngspice-42 or newer, and verilator
Transient simulation with SAR controller in verilog sampling a sine wave and generating values} 10 80 0 0 0.5 0.5 {}
N 770 430 810 430 {
lab=vout}
N 770 340 810 340 {
lab=vcm}
N 810 320 810 340 {
lab=vcm}
N 770 320 810 320 {
lab=vcm}
N 810 320 1020 320 {
lab=vcm}
N 770 280 1100 280 {
lab=vdda}
N 1100 280 1100 470 {
lab=vdda}
N 940 530 1170 530 {
lab=GND}
N 940 220 940 470 {
lab=vss}
N 770 220 940 220 {
lab=vss}
N 770 260 940 260 {
lab=vss}
N 1170 240 1170 470 {
lab=vccd}
N 770 240 1170 240 {
lab=vccd}
N 770 200 1100 200 {
lab=vdda}
N 1100 200 1100 280 {
lab=vdda}
N 770 300 940 300 {
lab=vss}
N 1020 320 1020 470 {
lab=vcm}
N 420 200 470 200 {
lab=vin}
N -270 340 -270 370 {
lab=vin}
N -170 220 -140 220 {
lab=vout}
N 30 220 470 220 {
lab=ena}
N 30 480 470 480 {
lab=rst}
N 30 500 470 500 {
lab=hold}
N 30 460 50 460 {
lab=d11}
N 30 440 50 440 {
lab=d10}
N 30 420 50 420 {
lab=d9}
N 30 400 50 400 {
lab=d8}
N 30 380 50 380 {
lab=d7}
N 30 360 50 360 {
lab=d6}
N 30 340 50 340 {
lab=d5}
N 30 320 50 320 {
lab=d4}
N 30 300 50 300 {
lab=d3}
N 30 280 50 280 {
lab=d2}
N 30 260 50 260 {
lab=d1}
N 30 240 40 240 {
lab=d0}
N 450 240 470 240 {
lab=d11.d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0}
C {sky130_ef_ip__adc3v_12bit.sym} 620 330 0 0 {name=x1}
C {devices/vsource.sym} 1020 500 0 0 {name=V1 value=1.65 savecurrent=false}
C {devices/vsource.sym} 1100 500 0 0 {name=V2 value=3.3 savecurrent=false}
C {devices/opin.sym} 810 430 0 0 {name=p1 lab=vout}
C {devices/lab_pin.sym} 810 340 0 1 {name=p2 sig_type=std_logic lab=vcm}
C {devices/vsource.sym} 1170 500 0 0 {name=V3 value=1.8 savecurrent=false}
C {devices/vsource.sym} 940 500 0 0 {name=V4 value=0 savecurrent=false}
C {devices/gnd.sym} 980 530 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} -270 400 0 0 {name=V5 value="SIN(1.65 1.65 10k 0 0)" savecurrent=false}
C {devices/lab_pin.sym} 1100 310 0 1 {name=p3 sig_type=std_logic lab=vdda}
C {devices/lab_pin.sym} 1170 240 0 1 {name=p4 sig_type=std_logic lab=vccd}
C {devices/lab_pin.sym} 940 400 0 1 {name=p5 sig_type=std_logic lab=vss}
C {devices/lab_pin.sym} -270 340 0 1 {name=p6 sig_type=std_logic lab=vin}
C {devices/lab_pin.sym} 420 220 0 0 {name=p7 sig_type=std_logic lab=ena}
C {devices/gnd.sym} -270 430 0 0 {name=l3 lab=GND}
C {sky130_fd_pr/corner.sym} 1260 440 0 0 {name=CORNER only_toplevel=false corner=tt}
C {devices/code_shown.sym} 1270 220 0 0 {name=Commands only_toplevel=false value=".include $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hvl/spice/sky130_fd_sc_hvl.spice
.include $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice
.control
   **save all
   save hold ena rst d11 d10 d9 d8 d7 d6 d5 d4 d3 d2 d1 d0
   save vin vout
   tran 1n 10.45u
   write simdata.raw
.endc
"}
C {devices/lab_pin.sym} 420 480 0 0 {name=p8 sig_type=std_logic lab=rst}
C {devices/lab_pin.sym} 420 500 0 0 {name=p11 sig_type=std_logic lab=hold}
C {devices/lab_pin.sym} 450 240 0 0 {name=p33 sig_type=std_logic lab=d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0}
C {devices/launcher.sym} 230 1480 0 0 {name=h2
descr="Load waves TRAN" 
tclcommand="
xschem raw_read $netlist_dir/simdata.raw tran
"
}
C {adc_testbench.sym} -50 340 0 0 {}
C {devices/lab_pin.sym} 420 200 0 0 {name=p12 sig_type=std_logic lab=vin}
C {devices/lab_pin.sym} -170 220 0 0 {name=p13 sig_type=std_logic lab=vout}
C {lab_pin.sym} 50 460 0 1 {name=p9 sig_type=std_logic lab=d11}
C {lab_pin.sym} 50 440 0 1 {name=p10 sig_type=std_logic lab=d10}
C {lab_pin.sym} 50 420 0 1 {name=p14 sig_type=std_logic lab=d9}
C {lab_pin.sym} 50 400 0 1 {name=p15 sig_type=std_logic lab=d8}
C {lab_pin.sym} 50 380 0 1 {name=p16 sig_type=std_logic lab=d7}
C {lab_pin.sym} 50 360 0 1 {name=p17 sig_type=std_logic lab=d6}
C {lab_pin.sym} 50 340 0 1 {name=p18 sig_type=std_logic lab=d5}
C {lab_pin.sym} 50 320 0 1 {name=p19 sig_type=std_logic lab=d4}
C {lab_pin.sym} 50 300 0 1 {name=p20 sig_type=std_logic lab=d3}
C {lab_pin.sym} 50 280 0 1 {name=p21 sig_type=std_logic lab=d2}
C {lab_pin.sym} 50 260 0 1 {name=p22 sig_type=std_logic lab=d1}
C {lab_pin.sym} 40 240 0 1 {name=p23 sig_type=std_logic lab=d0}
