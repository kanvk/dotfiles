#!/usr/bin/env python3
"""Render and run only Herdr entrypoints against an isolated home and fake CLI."""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")
HELPER = Path("dot_local/bin/executable_herdr-config.tmpl")
HOOK = Path(".chezmoiscripts/run_onchange_after_80-herdr.sh.tmpl")


class HerdrTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="chezmoi-herdr-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.home = self.base / "home"
        self.home.mkdir()
        runtime = self.base / "runtime"
        runtime.mkdir(mode=0o700)
        self.config = self.base / "chezmoi.json"
        self.calls = self.base / "calls.json"
        self.checkout = self.home / "p" / "personal config's checkout"
        (self.checkout / "scripts").mkdir(parents=True)
        (self.checkout / "scripts/deploy.py").write_text(
            "import json, os, sys\nfrom pathlib import Path\n"
            "Path(os.environ['HERDR_TEST_CALLS']).write_text(json.dumps(sys.argv[1:]))\n"
            "sys.exit(7 if '--fail' in sys.argv else 0)\n"
        )
        self.data = {
            "name": "Test User", "email": "test@example.invalid", "tier": "base",
            "use_gpg_signing": False, "gpg_signing_key": "", "ssh_age_identity": "",
            "ssh_age_recipient": "", "encrypt_locals": False,
            "is_wsl": True, "is_debian_like": True,
            "herdr_enabled": True, "herdr_checkout": str(self.checkout),
            "herdr_repo_url": "", "herdr_wsl_core": False,
        }
        self.environment = {
            **os.environ, "HOME": str(self.home), "HERDR_TEST_CALLS": str(self.calls),
            "XDG_RUNTIME_DIR": str(runtime),
        }

    def command(self):
        self.config.write_text(json.dumps({"encryption": "age", "data": self.data}))
        return [CHEZMOI, "--source", str(ROOT), "--config", str(self.config),
                "--destination", str(self.home), "--cache", str(self.base / "cache"),
                "--persistent-state", str(self.base / "state.boltdb")]

    def render(self, path, init=False):
        command = self.command() + ["execute-template"] + (["--init"] if init else [])
        result = subprocess.run(command, input=(ROOT / path).read_text(), text=True,
                                capture_output=True, env=self.environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def run_helper(self, action="bootstrap", *arguments):
        result = subprocess.run(["bash", "-s", "--", action, *arguments],
                                input=self.render(HELPER), text=True, capture_output=True,
                                env=self.environment)
        return result

    def test_missing_opt_in_keys_remain_disabled(self):
        self.data = {key: value for key, value in self.data.items() if not key.startswith("herdr_")}
        for action in ["bootstrap", "deploy", "doctor"]:
            result = self.run_helper(action)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("disabled", result.stdout.lower())
        self.assertFalse(self.calls.exists())

    def test_explicitly_disabled_desktop_never_invokes_cli(self):
        self.data["herdr_enabled"] = False
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.calls.exists())

    def test_non_wsl_is_harmless_even_when_enabled(self):
        self.data["is_wsl"] = False
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WSL", result.stdout)
        self.assertFalse(self.calls.exists())

    def test_bootstrap_alone_selects_staged_personal_files_and_preserves_arguments(self):
        result = self.run_helper("bootstrap", "--dry-run", "--no-activate")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.calls.read_text()), [
            "bootstrap", "--settings-dir", str(self.home / ".config/windows"),
            "--dry-run", "--no-activate",
        ])

    def test_deploy_and_doctor_never_select_personal_settings(self):
        for action in ["deploy", "doctor"]:
            result = self.run_helper(action, "--dry-run")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(self.calls.read_text()), [action, "--dry-run"])

    def test_default_checkout_expands_relative_to_the_current_home(self):
        expected = self.home / "p/herdr-config"
        self.checkout.rename(expected)
        self.data.pop("herdr_checkout")
        result = self.run_helper("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.calls.read_text()), ["doctor"])

    def test_missing_checkout_and_unset_url_do_not_clone_or_deploy(self):
        self.data["herdr_checkout"] = str(self.home / "missing checkout")
        for action in ["bootstrap", "deploy", "doctor"]:
            result = self.run_helper(action)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("URL", result.stdout)
        ready = self.run_helper("ready")
        self.assertEqual(ready.returncode, 0, ready.stderr)
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.home / "missing checkout").exists())

    def test_configured_url_still_requires_manual_clone(self):
        self.data["herdr_checkout"] = str(self.home / "missing")
        self.data["herdr_repo_url"] = "git@example.invalid:private/config.git"
        result = self.run_helper()
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("manual", result.stdout.lower())
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.home / "missing").exists())

    def test_missing_python_fails_manual_actions_but_not_readiness(self):
        empty_path = self.base / "empty-path"
        empty_path.mkdir()
        script = self.render(Path(".chezmoitemplates/herdr-command")) + '\nherdr_command "$@"\n'
        for action in ["bootstrap", "deploy", "doctor", "ready"]:
            result = subprocess.run([shutil.which("bash"), "-s", "--", action],
                                    input=script, text=True, capture_output=True,
                                    env={**self.environment, "PATH": str(empty_path)})
            self.assertEqual(result.returncode, 0 if action == "ready" else 1, result.stderr)
            if action != "ready":
                self.assertIn("python3", result.stdout)
        self.assertFalse(self.calls.exists())

    def test_optional_after_hook_only_announces_readiness(self):
        for updates in [{}, {"herdr_enabled": False}, {"is_wsl": False},
                        {"herdr_checkout": str(self.home / "missing")}]:
            with self.subTest(updates=updates):
                original = self.data.copy()
                self.data.update(updates)
                result = subprocess.run(["bash", "-s"], input=self.render(HOOK), text=True,
                                        capture_output=True, env=self.environment)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(self.calls.exists())
                self.data = original

    def test_cli_failures_are_not_reported_as_success(self):
        result = self.run_helper("deploy", "--fail")
        self.assertEqual(result.returncode, 7, result.stderr)

    def test_wsl_core_is_managed_only_when_explicitly_enabled_on_wsl(self):
        for wsl, enabled, desktop, expected in [
            (True, False, True, False), (False, True, True, False),
            (True, True, True, True), (True, True, False, True),
        ]:
            with self.subTest(wsl=wsl, core=enabled, desktop=desktop):
                self.data.update(is_wsl=wsl, herdr_wsl_core=enabled, herdr_enabled=desktop)
                result = subprocess.run(self.command() + ["managed", "--include=files"],
                                        text=True, capture_output=True, env=self.environment)
                self.assertEqual(result.returncode, 0, result.stderr)
                target = ".config/herdr-core/config.toml"
                self.assertEqual(target in result.stdout.splitlines(), expected)
        core = tomllib.loads(self.render(Path("dot_config/herdr-core/config.toml.tmpl")))
        self.assertEqual(core["shell"], ["sh", "-c", 'exec "$SHELL" -l'])

    def test_windows_preferences_contain_exactly_the_eight_safe_live_fields(self):
        settings = json.loads((ROOT / "dot_config/windows/herdr-app/settings.json").read_text())
        self.assertEqual(settings, {
            "zoom": 1.0, "sounds": {"enabled": False}, "font": "JetBrains Mono",
            "font_size": 15.0, "font_ligatures": False, "ui_font": "Segoe UI",
            "minimum_contrast": 1.0, "telemetry": False,
        })
        core = tomllib.loads((ROOT / "dot_config/windows/herdr-core/config.toml").read_text())
        self.assertEqual(core, {"shell": ["wsl.exe"]})

    def test_init_preserves_explicit_feature_data_and_defaults_missing_keys_off(self):
        configured = tomllib.loads(self.render(Path(".chezmoi.toml.tmpl"), init=True))["data"]
        self.assertTrue(configured["herdr_enabled"])
        self.assertFalse(configured["herdr_wsl_core"])
        self.assertEqual(configured["herdr_checkout"], str(self.checkout))
        self.assertEqual(configured["herdr_repo_url"], "")
        self.data = {key: value for key, value in self.data.items() if not key.startswith("herdr_")}
        defaults = tomllib.loads(self.render(Path(".chezmoi.toml.tmpl"), init=True))["data"]
        self.assertFalse(defaults["herdr_enabled"])
        self.assertFalse(defaults["herdr_wsl_core"])
        self.assertEqual(defaults["herdr_checkout"], "~/p/herdr-config")
        self.assertEqual(defaults["herdr_repo_url"], "")

    def test_just_entrypoints_delegate_without_losing_arguments(self):
        tools = self.base / "tools"
        tools.mkdir()
        wrapper = tools / "chezmoi"
        wrapper.write_text("#!/usr/bin/env bash\nexec " + shlex.join(self.command()) + ' "$@"\n')
        wrapper.chmod(0o755)
        for action in ["bootstrap", "deploy", "doctor"]:
            result = subprocess.run(["just", "--justfile", str(ROOT / "justfile"),
                                     "herdr-" + action, "--dry-run", "--no-activate"],
                                    text=True, capture_output=True,
                                    env={**self.environment, "PATH": str(tools) + os.pathsep + os.environ["PATH"]})
            self.assertEqual(result.returncode, 0, result.stderr)
            expected = [action]
            if action == "bootstrap":
                expected += ["--settings-dir", str(self.home / ".config/windows")]
            self.assertEqual(json.loads(self.calls.read_text()), expected + ["--dry-run", "--no-activate"])


if __name__ == "__main__":
    unittest.main()
