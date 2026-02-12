from __future__ import annotations

import json

from typer.testing import CliRunner

from k8s_kpo_poc.cli import app


runner = CliRunner()


def test_hello_default() -> None:
    result = runner.invoke(app, ["hello"])
    assert result.exit_code == 0
    assert "Hello, World!" in result.stdout


def test_product_sample_default() -> None:
    result = runner.invoke(app, ["product", "sample"])
    assert result.exit_code == 0
    payload = json.loads(result.stdout)
    assert payload["id"] == "demo-001"
    assert payload["name"] == "Hello Widget"
    assert payload["price"] == 19.99
    assert "demo" in payload["tags"]


def test_product_sample_tags() -> None:
    result = runner.invoke(app, ["product", "sample", "--tag", "cli", "--tag", "poc"])
    assert result.exit_code == 0
    payload = json.loads(result.stdout)
    assert payload["tags"] == ["cli", "poc"]
