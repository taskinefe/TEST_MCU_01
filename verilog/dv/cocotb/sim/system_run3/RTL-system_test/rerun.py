
import os
import shutil
import argparse

parser = argparse.ArgumentParser(description="Run cocotb tests")
parser.add_argument("-extend", help="extend the command")
args = parser.parse_args()

os.environ["CARAVEL_ROOT"] = "/nc/templates/caravel"
os.environ["MCW_ROOT"] = "/nc/templates/mgmt_core_wrapper"

os.chdir("/workspace/caravel_multi_peripheral/verilog/dv/cocotb")

command = "python3 /usr/local/bin/caravel_cocotb -test system_test -tag system_run3/RTL-system_test/rerun   -sim RTL -corner nom-t  -seed 1772747145 "
if args.extend is not None:
    command += f" {args.extend}"
os.system(command)

shutil.copyfile("/workspace/caravel_multi_peripheral/verilog/dv/cocotb/sim/system_run3/RTL-system_test/rerun.py", "/workspace/caravel_multi_peripheral/verilog/dv/cocotb/sim/system_run3/RTL-system_test/rerun/RTL-system_test/rerun.py")
