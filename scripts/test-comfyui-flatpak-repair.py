#!/usr/bin/env python3
"""Disposable profile/Git/installer regression tests; never access the real app data."""
import argparse
import fcntl
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
loader = importlib.machinery.SourceFileLoader('repair', str(ROOT / 'packaging/comfyui-flatpak-repair'))
spec = importlib.util.spec_from_loader(loader.name, loader)
repair = importlib.util.module_from_spec(spec)
loader.exec_module(repair)


class RepairTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = patch.dict(os.environ, {'XDG_DATA_HOME': str(self.root / 'data'),
                                          'XDG_CACHE_HOME': str(self.root / 'cache'),
                                          'HOME': str(self.root),
                                          'PATH': '/app/bin:/usr/bin:/bin'}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)
        self.profile, self.data, self.packages, self.backups = repair.profile_paths('test')
        self.nodes = self.data / 'custom_nodes'
        self.nodes.mkdir(parents=True)

    def args(self, command, **kwargs):
        return argparse.Namespace(profile='test', command=command, **kwargs)

    def test_profile_isolation_and_overrides(self):
        self.assertNotEqual(repair.profile_paths('other')[1], self.data)
        self.assertEqual(repair.profile_paths('gpu/1')[0], 'gpu_1')
        for key, value in [('COMFYUI_FLATPAK_DATA_ROOT', '/'),
                           ('COMFYUI_FLATPAK_PY_USER_BASE', ''),
                           ('COMFYUI_FLATPAK_CUSTOM_NODES_DIR', str(self.root)),
                           ('XDG_DATA_HOME', '')]:
            with self.subTest(key=key), patch.dict(os.environ, {key: value}):
                with self.assertRaises(repair.RepairError):
                    repair.profile_paths('test')
        for profile in ('.', '..'):
            with self.assertRaises(repair.RepairError):
                repair.profile_paths(profile)

    def test_node_traversal_symlink_and_collision(self):
        for name in ('', '.', '..', '../outside', '/outside', 'a/b', 'a\\b'):
            with self.subTest(name=name), self.assertRaises(repair.RepairError):
                repair.child_name(name)
        outside = self.root / 'outside'
        outside.mkdir()
        (self.nodes / 'link').symlink_to(outside)
        with self.assertRaises(repair.RepairError):
            repair.run(self.args('nodes', action='disable', name='link'))
        node = self.nodes / 'example'
        node.mkdir()
        (node / 'code.py').write_text('unchanged')
        repair.run(self.args('nodes', action='disable', name='example'))
        self.assertFalse(node.exists())
        node.mkdir()
        with self.assertRaises(repair.RepairError):
            repair.run(self.args('nodes', action='restore', name='example'))
        node.rmdir()
        repair.run(self.args('nodes', action='restore', name='example'))
        self.assertEqual((node / 'code.py').read_text(), 'unchanged')
        self.assertEqual(list(outside.iterdir()), [])

    def test_running_profile_refused(self):
        lock = self.data / '.flatpak-profile.lock'
        with lock.open('w') as f:
            fcntl.flock(f, fcntl.LOCK_SH)
            with self.assertRaisesRegex(repair.RepairError, 'running'):
                repair.run(self.args('reset-packages'))
        with repair.maintenance_lock(self.data):
            self.assertNotEqual(subprocess.run(['flock', '-sn', str(lock), 'true']).returncode, 0)

    def test_reset_restore_preserves_contents_and_other_profile(self):
        self.packages.mkdir(parents=True)
        (self.packages / 'old-package').write_text('old')
        for path in ('models/model', 'custom_nodes/example/code.py', 'user/workflow.json'):
            f = self.data / path
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text('preserve')
        other = repair.profile_paths('other')[2]
        other.mkdir(parents=True)
        (other / 'keep').write_text('other')
        marker = self.data / 'user/__flatpak_requirements/x.sha256'
        marker.parent.mkdir(parents=True)
        marker.write_text('cached')
        with patch.object(repair, 'requirements') as retry:
            repair.run(self.args('reset-packages'))
            retry.assert_called_once_with('test')
        self.assertFalse(marker.exists())
        backup = next(self.backups.iterdir())
        self.assertEqual((backup / 'old-package').read_text(), 'old')
        self.packages.mkdir()
        (self.packages / 'new-package').write_text('new')
        repair.run(self.args('restore-packages', backup=backup.name))
        self.assertEqual((self.packages / 'old-package').read_text(), 'old')
        self.assertEqual((next(self.backups.iterdir()) / 'new-package').read_text(), 'new')
        self.assertEqual((other / 'keep').read_text(), 'other')
        for path in ('models/model', 'custom_nodes/example/code.py', 'user/workflow.json'):
            self.assertEqual((self.data / path).read_text(), 'preserve')

    def test_reset_collision_and_failure_keep_backup(self):
        self.packages.mkdir(parents=True)
        (self.packages / 'keep').write_text('safe')
        (self.backups / 'collision').mkdir(parents=True)
        with patch.object(repair, 'backup_name', return_value='collision'):
            with self.assertRaisesRegex(repair.RepairError, 'exists'):
                repair.run(self.args('reset-packages'))
        self.assertEqual((self.packages / 'keep').read_text(), 'safe')
        with patch.object(repair, 'requirements', side_effect=repair.RepairError('fixture failure')):
            with self.assertRaisesRegex(repair.RepairError, 'fixture failure'):
                repair.run(self.args('reset-packages'))
        self.assertTrue(any((p / 'keep').exists() for p in self.backups.iterdir()))

    def test_requirements_explicit_retry_and_failure(self):
        with patch.object(repair.subprocess, 'call', return_value=0) as call:
            repair.run(self.args('requirements'))
            self.assertEqual(call.call_args.args[0], ['/app/bin/comfyui-install-requirements', '--retry-all'])
        with patch.object(repair.subprocess, 'call', return_value=1):
            with self.assertRaisesRegex(repair.RepairError, 'Some requirements failed'):
                repair.run(self.args('requirements'))

    def git(self, *args):
        return subprocess.check_output(['git', '-c', 'user.name=Fixture', '-c',
                                        'user.email=fixture@example.invalid', *map(str, args)],
                                       stderr=subprocess.DEVNULL, text=True).strip()

    def test_clean_git_fast_forward_dirty_and_divergence(self):
        origin = self.root / 'origin.git'
        seed = self.root / 'seed'
        node = self.nodes / 'git-node'
        self.git('init', '--bare', origin)
        self.git('clone', origin, seed)
        (seed / 'code').write_text('first')
        self.git('-C', seed, 'add', 'code')
        self.git('-C', seed, 'commit', '-m', 'first')
        self.git('-C', seed, 'push', 'origin', 'HEAD')
        self.git('clone', origin, node)
        (seed / 'code').write_text('second')
        self.git('-C', seed, 'commit', '-am', 'second')
        self.git('-C', seed, 'push', 'origin', 'HEAD')
        repair.update_node(node)
        self.assertEqual((node / 'code').read_text(), 'second')
        (node / 'code').write_text('dirty')
        with self.assertRaisesRegex(repair.RepairError, 'dirty'):
            repair.update_node(node)
        self.git('-C', node, 'commit', '-am', 'local')
        (seed / 'code').write_text('third')
        self.git('-C', seed, 'commit', '-am', 'third')
        self.git('-C', seed, 'push', 'origin', 'HEAD')
        with self.assertRaises(subprocess.CalledProcessError):
            repair.update_node(node)
        self.assertEqual((node / 'code').read_text(), 'dirty')
        (self.nodes / 'non-git').mkdir()
        with self.assertRaisesRegex(repair.RepairError, 'Not updated'):
            repair.run(self.args('nodes', action='update', name=None, all=True))
        (node / '.git' / 'unsafe').symlink_to(self.root)
        with self.assertRaisesRegex(repair.RepairError, 'symlinked'):
            repair.update_node(node)

    def test_installer_marker_retry_and_failure_status(self):
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        capture = self.root / 'calls'
        # Mock only pip; retain real Python for marker discovery and metadata.
        import sys
        python = bin_dir / 'python3'
        python.write_text('#!/bin/bash\nif [ "$1" = -m ] && [ "$2" = pip ]; then\n'
                          ' echo pip >> "$CAPTURE"\n exit "${FAIL_PIP:-0}"\nfi\n'
                          f'exec {sys.executable} "$@"\n')
        python.chmod(0o755)
        node = self.nodes / 'fixture'
        node.mkdir()
        (node / 'requirements.txt').write_text('fixture==1\n')
        env = dict(os.environ, PATH=f'{bin_dir}:/usr/bin:/bin', CAPTURE=str(capture),
                   COMFYUI_FLATPAK_PROFILE='test')
        installer = ['bash', str(ROOT / 'packaging/comfyui-flatpak-install-requirements')]
        for args in ([], [], ['--retry-all']):
            subprocess.run(installer + args, env=env, check=True, stdout=subprocess.DEVNULL)
        self.assertEqual(capture.read_text().splitlines(), ['pip', 'pip'])
        result = subprocess.run(installer + ['--retry-all'], env=dict(env, FAIL_PIP='1'),
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(list((self.data / 'user/__flatpak_requirements').glob('*.sha256')), [])


if __name__ == '__main__':
    unittest.main()
