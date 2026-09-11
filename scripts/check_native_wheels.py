#!/usr/bin/env python3
"""Reject universal/stub wheels for the two required native Comfy packages."""
import json
import sys
import urllib.parse


def check_native_wheels(manifest):
    modules = {module['name']: module for module in manifest['modules']}
    for name in ('comfy-kitchen', 'comfy-aimdo'):
        sources = modules['python3-' + name]['sources']
        if len(sources) != 1:
            raise ValueError(f'{name}: expected one x86_64 native wheel')
        source = sources[0]
        filename = urllib.parse.urlparse(source['url']).path.rsplit('/', 1)[-1]
        if not (filename.endswith('.whl') and '-abi3-' in filename
                and 'manylinux' in filename and 'x86_64' in filename
                and source.get('only-arches') == ['x86_64']):
            raise ValueError(f'{name}: expected native Linux x86_64 ABI3 wheel, got {filename}')


if __name__ == '__main__':
    with open(sys.argv[1]) as source:
        check_native_wheels(json.load(source))
    print('Native comfy-kitchen/comfy-aimdo wheel selection: PASS')
