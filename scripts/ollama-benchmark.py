#!/usr/bin/env python3
"""Benchmark Fenrir's preselected local Ollama candidates at a fixed context."""
from __future__ import annotations

import json
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "http://127.0.0.1:11434/api/generate"
MODELS = ("qwen3.5:9b", "gemma3:12b", "gemma3:4b")
PROMPT = (
    "Write a detailed, factual 180-word explanation of how a modern desktop "
    "operating system schedules processes, manages memory, and handles I/O. "
    "Use complete sentences and do not stop after the introduction."
)


def request(model: str, predict: int) -> dict:
    body = json.dumps({
        "model": model,
        "prompt": PROMPT,
        "stream": False,
        "keep_alive": "5m",
        "options": {
            "temperature": 0,
            "num_ctx": 8192,
            "num_predict": predict,
            "num_batch": 256,
        },
    }).encode()
    req = urllib.request.Request(
        API, data=body, headers={"Content-Type": "application/json"}, method="POST"
    )
    with urllib.request.urlopen(req, timeout=600) as response:
        value = json.loads(response.read().decode("utf-8"))
    return value


def ollama_processor() -> str:
    result = subprocess.run(
        ["ollama", "ps"], check=False, capture_output=True, text=True, timeout=15
    )
    return result.stdout.strip()


def main() -> int:
    results = []
    for model in MODELS:
        print(f"[Fenrir AI] Downloading {model}", flush=True)
        subprocess.run(["ollama", "pull", model], check=True, timeout=7200)
        print(f"[Fenrir AI] Warming up {model}", flush=True)
        request(model, 32)
        rates, samples = [], []
        for iteration in range(3):
            started = time.monotonic()
            response = request(model, 192)
            wall_seconds = time.monotonic() - started
            count = int(response.get("eval_count") or 0)
            duration = int(response.get("eval_duration") or 0) / 1_000_000_000
            rate = count / duration if duration > 0 else 0.0
            rates.append(rate)
            samples.append({
                "iteration": iteration + 1,
                "generated_tokens": count,
                "eval_tokens_per_second": round(rate, 2),
                "wall_seconds": round(wall_seconds, 2),
                "load_seconds": round(int(response.get("load_duration") or 0) / 1e9, 2),
            })
            print(f"[Fenrir AI] {model}: {rate:.2f} tokens/s", flush=True)
        processor = ollama_processor()
        gpu = "GPU" in processor.upper()
        results.append({
            "model": model,
            "median_tokens_per_second": round(statistics.median(rates), 2),
            "gpu_reported_by_ollama": gpu,
            "processor_report": processor,
            "samples": samples,
        })

    large = [item for item in results if item["model"] != "gemma3:4b"]
    gpu_large = [item for item in large if item["gpu_reported_by_ollama"]]
    pool = gpu_large or large or results
    selected = max(pool, key=lambda item: item["median_tokens_per_second"])
    report = {
        "schema": "org.fenrir.ollama-benchmark.v1",
        "benchmark_context_tokens": 8192,
        "models": results,
        "recommended_default": selected["model"],
        "selection_basis": (
            "highest median generation rate among large candidates confirmed on GPU"
            if gpu_large else
            "highest median generation rate among large candidates; GPU use was not confirmed"
        ),
    }
    output = Path.home() / ".local/share/fenrir/ollama/benchmark.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    temporary.replace(output)
    (output.parent / "default-model.txt").write_text(selected["model"] + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    if not gpu_large:
        print(
            "[Fenrir AI] WARNING: no 8B+ candidate was confirmed on GPU; "
            "inspect the report before considering GPU acceleration complete.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, urllib.error.URLError, subprocess.SubprocessError, json.JSONDecodeError) as exc:
        print(f"[Fenrir AI] Benchmark failed: {exc}", file=sys.stderr)
        raise SystemExit(2)
