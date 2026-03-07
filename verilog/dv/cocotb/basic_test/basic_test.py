import cocotb
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
@report_test
async def basic_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=500000)
    cocotb.log.info("[TEST] Starting basic_test")
    await caravelEnv.release_csb()
    
    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.start()
    
    cocotb.log.info("[TEST] Waiting for firmware ready (vgpio=1)")
    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Firmware ready")
    
    cocotb.log.info("[TEST] Waiting for phase 2 (vgpio=2)")
    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] Phase 2 complete")
    
    cocotb.log.info("[TEST] Waiting for phase 3 (vgpio=3)")
    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] Phase 3 complete")
    
    cocotb.log.info("[TEST] Waiting for phase 4 (vgpio=4)")
    await vgpio.wait_output(4)
    cocotb.log.info("[TEST] Phase 4 complete")
    
    cocotb.log.info("[TEST] Waiting for test pass (vgpio=5)")
    await vgpio.wait_output(5)
    cocotb.log.info("[TEST] Test PASSED")
    
    cocotb.log.info("[TEST] basic_test completed successfully")
