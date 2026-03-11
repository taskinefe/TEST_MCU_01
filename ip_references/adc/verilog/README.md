# Cosimulation using ngspice-43 (or newer) and verilator

To compile the shared library run the script:

```
./run_make_obj.sh
```

This will compile the shared object library for the digital testbench
stimulus and copy it into the default xschem simulation directory
(~/.xschem/simulations).

The script runs ngspice with a special option that handles the
verilator shared object library compile:

```
ngspice vlnggen -- --timing adc_testbench.v
```

The output file is `adc_testbench.so`.

This compilation and simulation has been tested with:

	ngspice-43+
	verilator 5.031 devel rev v5.030-78-g5470cf9fa

Earlier versions may result in a non-functioning digital block in
simulation without indicating any error at compile time or run
time.

Note that due to the cosimulation setup, xschem will report
errors when netlisting due to signals that are connected within
the code block but not to a symbol.  This would presumably be
fixed by creating a symbol for the xspice element.
