v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N -340 -140 -280 -140 {
lab=adc_dac_val[0]}
N -340 -120 -280 -120 {
lab=adc_dac_val[1]}
N -340 -100 -280 -100 {
lab=adc_dac_val[2]}
N -340 -80 -280 -80 {
lab=adc_dac_val[3]}
N -340 -60 -280 -60 {
lab=adc_dac_val[4]}
N -340 -40 -280 -40 {
lab=adc_dac_val[5]}
N -340 -20 -280 -20 {
lab=adc_dac_val[6]}
N -340 0 -280 0 {
lab=adc_dac_val[7]}
N -340 20 -280 20 {
lab=adc_dac_val[8]}
N -340 40 -280 40 {
lab=adc_dac_val[9]}
N -340 60 -280 60 {
lab=adc_dac_val[10]}
N -340 80 -280 80 {
lab=adc_dac_val[11]}
N -340 120 -280 120 {
lab=adc_reset}
N 230 80 280 80 {
lab=adc_ena}
N 580 -40 620 -40 {
lab=adc0_comp_out}
N 20 60 50 60 {
lab=#net1}
N 20 40 280 40 {
lab=adc_aval}
N -340 100 -280 100 {
lab=adc_hold}
N -440 -220 -390 -220 {
lab=adc_dac_val[11:0]}
C {sky130_ef_ip__cdac3v_12bit.sym} -130 -20 0 0 {name=x1}
C {devices/lab_pin.sym} 20 -140 0 1 {name=p1 sig_type=std_logic lab=vdda}
C {devices/lab_pin.sym} 20 -120 0 1 {name=p2 sig_type=std_logic lab=vccd}
C {devices/lab_pin.sym} 20 -100 0 1 {name=p3 sig_type=std_logic lab=vssd}
C {devices/lab_pin.sym} 20 -80 0 1 {name=p4 sig_type=std_logic lab=vssa}
C {devices/lab_pin.sym} 20 -60 0 1 {name=p5 sig_type=std_logic lab=adc_vrefH}
C {devices/lab_pin.sym} 20 -20 0 1 {name=p6 sig_type=std_logic lab=adc_vrefL}
C {devices/lab_pin.sym} 280 20 0 0 {name=p7 sig_type=std_logic lab=vssa}
C {devices/lab_pin.sym} 280 0 0 0 {name=p8 sig_type=std_logic lab=vdda}
C {devices/lab_pin.sym} 280 -20 0 0 {name=p9 sig_type=std_logic lab=vssd}
C {devices/lab_pin.sym} 280 -40 0 0 {name=p10 sig_type=std_logic lab=vccd}
C {devices/opin.sym} 620 -40 0 0 {name=p34 lab=adc_comp_out}
C {devices/ipin.sym} 240 -150 0 0 {name=p11 lab=adc_in}
C {devices/ipin.sym} 230 80 0 0 {name=p30 lab=adc_ena}
C {devices/ipin.sym} -340 120 0 0 {name=p31 lab=adc_reset}
C {devices/iopin.sym} 230 -350 0 0 {name=p13 lab=vdda}
C {devices/iopin.sym} 230 -330 0 0 {name=p32 lab=vssa}
C {devices/iopin.sym} 230 -310 0 0 {name=p35 lab=vccd}
C {devices/iopin.sym} 230 -290 0 0 {name=p36 lab=vssd}
C {devices/iopin.sym} 230 -260 0 0 {name=p37 lab=adc_vrefH}
C {devices/iopin.sym} 230 -240 0 0 {name=p38 lab=adc_vrefL}
C {devices/ipin.sym} -440 -220 0 0 {name=p40 lab=adc_dac_val[11:0]}
C {devices/lab_wire.sym} 150 40 0 0 {name=p14 sig_type=std_logic lab=adc_aval}
C {devices/noconn.sym} 50 60 0 1 {name=l1}
C {devices/iopin.sym} 230 -220 0 0 {name=p16 lab=adc_trim}
C {devices/lab_pin.sym} 20 0 0 1 {name=p17 sig_type=std_logic lab=adc_trim}
C {devices/lab_pin.sym} 20 20 0 1 {name=p12 sig_type=std_logic lab=adc_in}
C {devices/iopin.sym} 230 -200 0 0 {name=p18 lab=adc_vCM}
C {devices/ipin.sym} -340 100 0 0 {name=p20 lab=adc_hold}
C {devices/lab_pin.sym} 20 -40 0 1 {name=p19 sig_type=std_logic lab=adc_vCM}
C {devices/lab_pin.sym} 280 60 0 0 {name=p21 sig_type=std_logic lab=adc_vCM}
C {sky130_ef_ip__scomp3v.sym} 430 10 0 0 {name=x2}
C {lab_pin.sym} -390 -220 0 1 {name=p15 sig_type=std_logic lab=adc_dac_val[11:0]}
C {lab_pin.sym} -340 -140 0 0 {name=p22 sig_type=std_logic lab=adc_dac_val[0]}
C {lab_pin.sym} -340 -120 0 0 {name=p23 sig_type=std_logic lab=adc_dac_val[1]}
C {lab_pin.sym} -340 -100 0 0 {name=p24 sig_type=std_logic lab=adc_dac_val[2]}
C {lab_pin.sym} -340 -80 0 0 {name=p25 sig_type=std_logic lab=adc_dac_val[3]}
C {lab_pin.sym} -340 -60 0 0 {name=p26 sig_type=std_logic lab=adc_dac_val[4]}
C {lab_pin.sym} -340 -40 0 0 {name=p27 sig_type=std_logic lab=adc_dac_val[5]}
C {lab_pin.sym} -340 -20 0 0 {name=p28 sig_type=std_logic lab=adc_dac_val[6]}
C {lab_pin.sym} -340 0 0 0 {name=p29 sig_type=std_logic lab=adc_dac_val[7]}
C {lab_pin.sym} -340 20 0 0 {name=p33 sig_type=std_logic lab=adc_dac_val[8]}
C {lab_pin.sym} -340 40 0 0 {name=p39 sig_type=std_logic lab=adc_dac_val[9]}
C {lab_pin.sym} -340 60 0 0 {name=p41 sig_type=std_logic lab=adc_dac_val[10]}
C {lab_pin.sym} -340 80 0 0 {name=p42 sig_type=std_logic lab=adc_dac_val[11]}
