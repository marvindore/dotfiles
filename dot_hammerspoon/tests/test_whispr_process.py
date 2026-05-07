"""Unit tests for whispr_process.py pure text-processing functions."""
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "whispr_process",
    Path(__file__).parent.parent / "whispr_process.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class TestStripTimestamps:
    def test_strips_single_timestamp(self):
        assert mod.strip_timestamps("[00:00:00.000 --> 00:00:05.000] hello world") == "hello world"

    def test_strips_multiple_timestamps(self):
        raw = "[00:00:00.000 --> 00:00:03.000] hello\n[00:00:03.000 --> 00:00:06.000] world"
        assert mod.strip_timestamps(raw) == "hello\nworld"

    def test_no_timestamps_unchanged(self):
        assert mod.strip_timestamps("kubectl apply -f deployment.yaml") == "kubectl apply -f deployment.yaml"

    def test_empty_string(self):
        assert mod.strip_timestamps("") == ""

    def test_all_timestamps_produces_empty(self):
        raw = "[00:00:00.000 --> 00:00:03.000]  \n[00:00:03.000 --> 00:00:06.000]  "
        assert mod.strip_timestamps(raw) == ""


class TestApplyReplacements:
    def test_github_space(self):
        assert mod.apply_replacements("push to git hub") == "push to GitHub"

    def test_kubectl_cuddle(self):
        assert mod.apply_replacements("run kube cuddle get pods") == "run kubectl get pods"

    def test_postgresql(self):
        assert mod.apply_replacements("connect to post gress") == "connect to PostgreSQL"

    def test_grpc(self):
        assert mod.apply_replacements("using grpc service") == "using gRPC service"

    def test_case_insensitive(self):
        assert mod.apply_replacements("using GRPC service") == "using gRPC service"

    def test_oauth_not_corrupted_in_oauth2(self):
        result = mod.apply_replacements("using oauth2 tokens")
        assert result == "using oauth2 tokens"

    def test_api_spelled_out(self):
        assert mod.apply_replacements("call the a p i endpoint") == "call the API endpoint"

    def test_neovim_split(self):
        assert mod.apply_replacements("open neo vim") == "open Neovim"

    def test_no_match_unchanged(self):
        assert mod.apply_replacements("docker run hello-world") == "docker run hello-world"


class TestTranscribe:
    def test_unknown_backend_returns_false(self, tmp_path):
        txt = str(tmp_path / "out.txt")
        ok, err = mod.transcribe("/tmp/x.wav", "unknown-backend", "/usr/bin/false", "/tmp/model.bin", txt)
        assert not ok
        assert "unknown-backend" in err.lower() or "unknown" in err.lower()

    def test_backend_failure_nonzero_exit(self, tmp_path):
        txt = str(tmp_path / "out.txt")
        ok, err = mod.transcribe("/tmp/x.wav", "whisper-cpp", "/usr/bin/false", "/tmp/model.bin", txt)
        assert not ok
        assert err  # some error message present

    def test_backend_no_output_file(self, tmp_path):
        txt = str(tmp_path / "out.txt")
        # /usr/bin/true exits 0 but writes nothing
        ok, err = mod.transcribe("/tmp/x.wav", "whisper-cpp", "/usr/bin/true", "/tmp/model.bin", txt)
        assert not ok
        assert err  # some error message present
