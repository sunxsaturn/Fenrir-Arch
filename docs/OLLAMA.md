# Fenrir local inference

Fenrir installs the official Arch `ollama` and `ollama-vulkan` packages. The Vulkan split package is used so AMD graphics can be benchmarked without assuming ROCm support for every Radeon model.

The service is configured for one active model, one parallel request, an 8,192-token context and an 8-bit KV cache. This is a starting point for the workstation's 12 GiB Radeon RX 6750 XT, not a promise of a fixed throughput.

## Initial candidates

- `qwen3.5:9b` — primary balanced candidate, multimodal.
- `gemma3:12b` — larger single-GPU candidate.
- `gemma3:4b` — lower-memory fallback.

The installer downloads all candidates, warms them up, runs three fixed-context generation trials per model, records median output tokens/second and captures `ollama ps` processor allocation. The default recommendation is the fastest large candidate that Ollama reports using GPU. If none is confirmed on GPU, the report explicitly warns that acceleration was not validated.

Reports are written to `~/.local/share/fenrir/ollama/benchmark.json`; the chosen model is written to `default-model.txt`. Models remain in Ollama's system model store and are never placed under `/mnt/storage`.

A later Doctor release will expose model status and benchmark history. No benchmark result should be presented as proof of GPU acceleration unless Ollama reports GPU allocation and the target Radeon adapter has been identified.
