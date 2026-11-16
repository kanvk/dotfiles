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
        self.checkout = self.home / "p/herdr-config"
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
        }
        self.environment = {
            **os.environ, "HOME": str(self.home), "HERDR_TEST_CALLS": str(self.calls),
            "XDG_RUNTIME_DIR": str(runtime),
        }
        self.environment.pop("HERDR_CONFIG_DIR", None)
        tools = self.base / "tools"
        tools.mkdir()
        wrapper = tools / "chezmoi"
        wrapper.write_text("#!/usr/bin/env bash\nexec " + shlex.join(self.command()) + ' "$@"\n')
        wrapper.chmod(0o755)
        self.environment["PATH"] = str(tools) + os.pathsep + os.environ["PATH"]

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
        self.command()
        return subprocess.run(["just", "--justfile", str(ROOT / "justfile"),
                               "herdr-" + action, *arguments], text=True,
                              capture_output=True, env=self.environment)

    def cli_arguments(self):
        self.assertTrue(self.calls.is_file(), "Explicit just command did not invoke the config CLI")
        return json.loads(self.calls.read_text())

    def test_just_commands_work_without_herdr_specific_answers(self):
        for action in ["bootstrap", "deploy", "doctor"]:
            with self.subTest(action=action):
                result = self.run_helper(action)
                self.assertEqual(result.returncode, 0, result.stderr)
                expected = [action]
                if action == "bootstrap":
                    expected += ["--settings-dir", str(ROOT / "dot_config/windows")]
                self.assertEqual(self.cli_arguments(), expected)

    def test_legacy_disabled_answer_does_not_block_an_explicit_command(self):
        self.data.update(herdr_enabled=False, herdr_checkout="/obsolete/path", herdr_repo_url="")
        result = self.run_helper("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cli_arguments(), ["doctor"])

    def test_non_wsl_reports_an_error_instead_of_silent_success(self):
        self.data["is_wsl"] = False
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("WSL", result.stderr)
        self.assertFalse(self.calls.exists())

    def test_bootstrap_reads_source_preferences_without_applying_dotfiles_first(self):
        result = self.run_helper("bootstrap", "--dry-run", "--no-activate")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cli_arguments(), [
            "bootstrap", "--settings-dir", str(ROOT / "dot_config/windows"),
            "--dry-run", "--no-activate",
        ])
        self.assertFalse((self.home / ".config/windows").exists())

    def test_deploy_and_doctor_do_not_select_personal_settings(self):
        for action in ["deploy", "doctor"]:
            result = self.run_helper(action, "--dry-run")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.cli_arguments(), [action, "--dry-run"])

    def test_checkout_override_handles_spaces_apostrophes_and_literal_shell_syntax(self):
        checkout = self.home / "custom config's $(do-not-execute)"
        self.checkout.rename(checkout)
        self.environment["HERDR_CONFIG_DIR"] = str(checkout)
        result = self.run_helper("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cli_arguments(), ["doctor"])

    def test_tilde_checkout_override_expands_under_current_home(self):
        self.environment["HERDR_CONFIG_DIR"] = "~/p/herdr-config"
        result = self.run_helper("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cli_arguments(), ["doctor"])

    def test_missing_checkout_reports_failure_without_creating_or_cloning_it(self):
        missing = self.home / "missing checkout"
        self.environment["HERDR_CONFIG_DIR"] = str(missing)
        for action in ["bootstrap", "deploy", "doctor"]:
            result = self.run_helper(action)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("checkout", result.stderr.lower())
        self.assertFalse(self.calls.exists())
        self.assertFalse(missing.exists())

    def test_cli_failures_are_not_reported_as_success(self):
        result = self.run_helper("deploy", "--fail")
        self.assertEqual(result.returncode, 7, result.stderr)

    def test_ordinary_apply_has_no_live_herdr_targets_or_hook_even_with_legacy_answers(self):
        self.data.update(herdr_enabled=True, herdr_wsl_core=True)
        result = subprocess.run(self.command() + ["managed", "--include=files,scripts"],
                                text=True, capture_output=True, env=self.environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        targets = {path for path in result.stdout.splitlines() if "herdr" in path.lower()}
        self.assertEqual(targets, {
            ".config/windows/herdr-app/settings.json", ".config/windows/herdr-core/config.toml",
        })
        self.assertFalse(self.calls.exists())

    def test_windows_preferences_contain_exactly_the_eight_safe_live_fields(self):
        settings = json.loads((ROOT / "dot_config/windows/herdr-app/settings.json").read_text())
        self.assertEqual(settings, {
            "zoom": 1.0, "sounds": {"enabled": False}, "font": "JetBrains Mono",
            "font_size": 15.0, "font_ligatures": False, "ui_font": "Segoe UI",
            "minimum_contrast": 1.0, "telemetry": False,
        })
        core = tomllib.loads((ROOT / "dot_config/windows/herdr-core/config.toml").read_text())
        self.assertEqual(core, {"shell": ["wsl.exe"]})

    def test_init_does_not_emit_herdr_answers_even_if_legacy_values_exist(self):
        self.data.update(herdr_enabled=True, herdr_checkout="~/old-checkout",
                         herdr_repo_url="", herdr_wsl_core=True)
        configured = tomllib.loads(self.render(Path(".chezmoi.toml.tmpl"), init=True))["data"]
        self.assertFalse(any(key.startswith("herdr_") for key in configured))


if __name__ == "__main__":
    unittest.main()
