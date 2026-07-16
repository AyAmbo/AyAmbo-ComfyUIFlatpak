#!/usr/bin/env python3
"""Compile and execute a minimal Triton CUDA kernel inside the Flatpak."""

import torch
import triton
import triton.language as tl


@triton.jit
def add_kernel(x, y, output, size: tl.constexpr):
    offsets = tl.arange(0, size)
    tl.store(output + offsets, tl.load(x + offsets) + tl.load(y + offsets))


x = torch.ones(256, device="cuda")
y = torch.ones(256, device="cuda")
output = torch.empty_like(x)
add_kernel[(1,)](x, y, output, size=256)
torch.testing.assert_close(output, x + y)
print("triton", triton.__version__, "CUDA JIT kernel ok")
