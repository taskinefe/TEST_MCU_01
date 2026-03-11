#!/bin/bash

# Generate the .so file
ngspice vlnggen -- --timing adc_testbench.v

# Copy the .so file into the xschem simulation directory
cp adc_testbench.so ~/.xschem/simulations
