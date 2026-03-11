v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
B 2 630 820 1430 1220 {flags=graph
y1=0
y2=2
ypos1=0
ypos2=2
divy=5
subdivy=1
unity=1
x1=0
x2=1.45e-06
divx=5
subdivx=1
xlabmag=1.0
ylabmag=1.0


dataset=-1
unitx=1
logx=0
logy=0
digital=1
color="4 10 6 7 4"
node="d[11:0];d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0
rst
hold
x1.x2.x1.voutanalog
vout"}
T {0.75v = 3.3*0.223 = 930/4096
930 = hex 0x3a2} 430 220 0 0 0.4 0.4 {}
T {12-bit ADC testbench} 0 0 0 0 1 1 {}
N 1160 520 1200 520 {
lab=vout}
N 1160 410 1200 410 {
lab=vcm}
N 1200 410 1410 410 {
lab=vcm}
N 1160 370 1490 370 {
lab=vdda}
N 1490 370 1490 560 {
lab=vdda}
N 1330 620 1560 620 {
lab=GND}
N 1330 310 1330 560 {
lab=vss}
N 1160 310 1330 310 {
lab=vss}
N 1160 350 1330 350 {
lab=vss}
N 1560 330 1560 560 {
lab=vccd}
N 1160 330 1560 330 {
lab=vccd}
N 1160 290 1490 290 {
lab=vdda}
N 1490 290 1490 370 {
lab=vdda}
N 1160 390 1330 390 {
lab=vss}
N 730 570 790 570 {
lab=rst}
N 730 570 730 610 {
lab=rst}
N 1410 410 1410 560 {
lab=vcm}
N 790 570 860 570 {
lab=rst}
N 730 310 860 310 {
lab=vccd}
N 800 590 860 590 {
lab=hold}
N 800 590 800 670 {
lab=hold}
N 730 730 800 730 {
lab=GND}
N 730 670 730 730 {
lab=GND}
N 90 470 130 470 {
lab=GND}
N 90 790 130 790 {
lab=GND}
N 90 710 130 710 {
lab=GND}
N 90 630 130 630 {
lab=GND}
N 90 550 130 550 {
lab=GND}
N 130 410 170 410 {
lab=d11}
N 130 490 170 490 {
lab=d10}
N 130 570 170 570 {
lab=d9}
N 130 650 170 650 {
lab=d8}
N 130 730 170 730 {
lab=d7}
N 90 870 130 870 {
lab=GND}
N 130 810 170 810 {
lab=d6}
N 130 890 170 890 {
lab=d5}
N 90 950 130 950 {
lab=GND}
N 560 290 560 610 {
lab=vin}
N 560 290 860 290 {
lab=vin}
N 560 670 730 670 {
lab=GND}
N 130 970 170 970 {
lab=d4}
N 90 1030 130 1030 {
lab=GND}
N 130 1050 170 1050 {
lab=d3}
N 90 1110 130 1110 {
lab=GND}
N 90 470 90 1150 {
lab=GND}
N 90 1150 90 1350 {
lab=GND}
N 90 1350 130 1350 {
lab=GND}
N 130 1130 170 1130 {
lab=d2}
N 130 1210 170 1210 {
lab=d1}
N 130 1290 170 1290 {
lab=d0}
N 90 1190 130 1190 {
lab=GND}
N 90 1270 130 1270 {
lab=GND}
N 730 330 860 330 {
lab=d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0}
N 1160 430 1330 430 {
lab=vss}
C {sky130_ef_ip__adc3v_12bit.sym} 1010 420 0 0 {name=x1}
C {devices/vsource.sym} 1410 590 0 0 {name=V1 value=1.65 savecurrent=false}
C {devices/vsource.sym} 1490 590 0 0 {name=V2 value=3.3 savecurrent=false}
C {devices/opin.sym} 1200 520 0 0 {name=p1 lab=vout}
C {devices/lab_pin.sym} 1410 410 0 1 {name=p2 sig_type=std_logic lab=vcm}
C {devices/vsource.sym} 1560 590 0 0 {name=V3 value=1.8 savecurrent=false}
C {devices/vsource.sym} 1330 590 0 0 {name=V4 value=0 savecurrent=false}
C {devices/gnd.sym} 1370 620 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 560 640 0 0 {name=V5 value=0.75 savecurrent=false}
C {devices/lab_pin.sym} 1490 400 0 1 {name=p3 sig_type=std_logic lab=vdda}
C {devices/lab_pin.sym} 1560 330 0 1 {name=p4 sig_type=std_logic lab=vccd}
C {devices/lab_pin.sym} 1330 490 0 1 {name=p5 sig_type=std_logic lab=vss}
C {devices/lab_pin.sym} 560 290 0 0 {name=p6 sig_type=std_logic lab=vin}
C {devices/lab_pin.sym} 730 310 0 0 {name=p7 sig_type=std_logic lab=vccd}
C {devices/vsource.sym} 730 640 0 0 {name=V6 value="PWL(0 0 50n 0 55n 1.8 200n 1.8 205n 0)"  savecurrent=false}
C {devices/gnd.sym} 730 730 0 0 {name=l3 lab=GND}
C {sky130_fd_pr/corner.sym} 640 80 0 0 {name=CORNER only_toplevel=false corner=tt}
C {devices/code_shown.sym} 780 70 0 0 {name=Commands only_toplevel=false value=".include $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hvl/spice/sky130_fd_sc_hvl.spice
.include $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice
.control
   save all
   tran 1n 1.45u
   write simdata.raw
.endc
"}
C {devices/lab_pin.sym} 730 570 0 0 {name=p8 sig_type=std_logic lab=rst}
C {devices/vsource.sym} 800 700 0 0 {name=V9 value="PWL(0 0 150n 0 155n 1.8)"  savecurrent=false}
C {devices/lab_pin.sym} 800 590 0 0 {name=p11 sig_type=std_logic lab=hold}
C {devices/vsource.sym} 130 440 0 0 {name=V10 value="PWL(0 0 100n 0 105n 1.8 300n 1.8 305n 0)" savecurrent=false}
C {devices/vsource.sym} 130 520 0 0 {name=V11 value="PWL(0 0 300n 0 305n 1.8 400n 1.8 405n 0)" savecurrent=false}
C {devices/lab_pin.sym} 170 410 0 1 {name=p12 sig_type=std_logic lab=d11}
C {devices/lab_pin.sym} 170 490 0 1 {name=p13 sig_type=std_logic lab=d10}
C {devices/lab_pin.sym} 170 570 0 1 {name=p14 sig_type=std_logic lab=d9}
C {devices/lab_pin.sym} 170 650 0 1 {name=p15 sig_type=std_logic lab=d8}
C {devices/lab_pin.sym} 170 730 0 1 {name=p16 sig_type=std_logic lab=d7}
C {devices/vsource.sym} 130 600 0 0 {name=V12 value="PWL(0 0 400n 0 405n 1.8 500n 1.8 505n 1.8)" savecurrent=false}
C {devices/vsource.sym} 130 680 0 0 {name=V13 value="PWL(0 0 500n 0 505n 1.8 600n 1.8 605n 1.8)" savecurrent=false}
C {devices/vsource.sym} 130 760 0 0 {name=V14 value="PWL(0 0 600n 0 605n 1.8 700n 1.8 705n 1.8)" savecurrent=false}
C {devices/lab_pin.sym} 170 810 0 1 {name=p21 sig_type=std_logic lab=d6}
C {devices/vsource.sym} 130 840 0 0 {name=V7 value="PWL(0 0 700n 0 705n 1.8 800n 1.8 805n 0)" savecurrent=false}
C {devices/gnd.sym} 90 1350 0 0 {name=l2 lab=GND}
C {devices/vsource.sym} 130 920 0 0 {name=V8 value="PWL(0 0 800n 0 805n 1.8 900n 1.8 905n 0)" savecurrent=false}
C {devices/lab_pin.sym} 170 890 0 1 {name=p22 sig_type=std_logic lab=d5}
C {devices/vsource.sym} 130 1000 0 0 {name=V15 value="PWL(0 0 900n 0 905n 1.8 1000n 1.8 1005n 1.8)" savecurrent=false}
C {devices/lab_pin.sym} 170 970 0 1 {name=p24 sig_type=std_logic lab=d4}
C {devices/vsource.sym} 130 1080 0 0 {name=V16 value="PWL(0 0 1000n 0 1005n 1.8 1100n 1.8 1105n 1.8)" savecurrent=false}
C {devices/lab_pin.sym} 170 1050 0 1 {name=p26 sig_type=std_logic lab=d3}
C {devices/vsource.sym} 130 1160 0 0 {name=V17 value="PWL(0 0 1100n 0 1105n 1.8 1200n 1.8 1205n 0)" savecurrent=false}
C {devices/vsource.sym} 130 1240 0 0 {name=V18 value="PWL(0 0 1200n 0 1205n 1.8 1300n 1.8 1305n 0)" savecurrent=false}
C {devices/vsource.sym} 130 1320 0 0 {name=V19 value="PWL(0 0 1300n 0 1305n 1.8 1400n 1.8 1405n 0)" savecurrent=false}
C {devices/lab_pin.sym} 170 1130 0 1 {name=p28 sig_type=std_logic lab=d2}
C {devices/lab_pin.sym} 170 1210 0 1 {name=p29 sig_type=std_logic lab=d1}
C {devices/lab_pin.sym} 170 1290 0 1 {name=p30 sig_type=std_logic lab=d0}
C {devices/lab_pin.sym} 730 330 0 0 {name=p33 sig_type=std_logic lab=d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0}
C {devices/launcher.sym} 690 1270 0 0 {name=h1
descr="Load waves TRAN" 
tclcommand="
xschem raw_read $netlist_dir/simdata.raw tran
"
}
