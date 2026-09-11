#!/usr/bin/env python3
"""Exercise the bundled kitchen CUDA kernel and aimdo VRAM buffers, not a model workflow."""
import gc

import torch
from comfy_aimdo import control
from comfy_kitchen.backends import cuda as kitchen_cuda

assert kitchen_cuda._EXT_AVAILABLE, kitchen_cuda._EXT_ERROR
print('Kitchen native extension:', kitchen_cuda._module_path)
assert control.init('cuda'), 'aimdo native library did not initialize'
try:
    assert control.init_devices(list(range(torch.cuda.device_count())))
    print('aimdo native library:', control.lib._name)
    # Import after control.init(): the native buffer wrapper captures control.lib.
    from comfy_aimdo.vram_buffer import VRAMBuffer
    from comfy_aimdo.torch import aimdo_to_tensor

    for index in range(torch.cuda.device_count()):
        # DLPack export used by the native kernel requires the current device.
        torch.cuda.set_device(index)
        device = f'cuda:{index}'
        q = torch.arange(1024, device=device).to(torch.int8).reshape(32, 32)
        scale = torch.tensor(0.125, device=device)
        result = kitchen_cuda.dequantize_int8_simple(q, scale)
        torch.testing.assert_close(result, q.float() * scale)
        print('Kitchen native INT8 dequantization verified on', device)

        buffer = VRAMBuffer(16 * 1024 * 1024, index)
        allocation = buffer.get(4096)
        view = aimdo_to_tensor(allocation, device)
        view.fill_(37)
        assert bool((view == 37).all())
        torch.cuda.synchronize(index)
        print('aimdo VRAM buffer write/read verified on', device, 'bytes:', view.numel())
        del view, allocation, buffer
        gc.collect()
finally:
    control.deinit()
print('Native backend smoke passed; model offloading/full DynamicVRAM workflows are not tested.')
