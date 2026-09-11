#!/usr/bin/env python3
"""Regression checks that universal or wrong-architecture native sources fail closed."""
import copy
import json
from pathlib import Path
import unittest

from check_native_wheels import check_native_wheels


class NativeWheelSelectionTests(unittest.TestCase):
    def setUp(self):
        source = Path(__file__).resolve().parents[1] / 'packaging/pypi-dependencies.json'
        self.manifest = json.loads(source.read_text())

    def test_current_native_wheels(self):
        check_native_wheels(self.manifest)

    def test_universal_wheel_rejected_for_each_package(self):
        for name in ('comfy-kitchen', 'comfy-aimdo'):
            with self.subTest(name=name):
                manifest = copy.deepcopy(self.manifest)
                module = next(m for m in manifest['modules'] if m['name'] == 'python3-' + name)
                module['sources'][0]['url'] = 'https://files.pythonhosted.org/example-1.0-py3-none-any.whl'
                with self.assertRaises(ValueError):
                    check_native_wheels(manifest)

    def test_wrong_architecture_rejected(self):
        module = next(m for m in self.manifest['modules'] if m['name'] == 'python3-comfy-aimdo')
        module['sources'][0]['only-arches'] = ['aarch64']
        with self.assertRaises(ValueError):
            check_native_wheels(self.manifest)


if __name__ == '__main__':
    unittest.main()
