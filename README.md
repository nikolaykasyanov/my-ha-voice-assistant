This repo contains the config & prompts of my [Home Assistant]-powered voice assistant.

# Home Assistant

The setup relies on the following HA integrations:
- [llama.cpp][HA llama.cpp] to add & configure [oMLX] as a conversation agent
- [Tools for Assist][HA LLM intents] (custom integration) for additional tools & better home
control tools' configuratbility
- [Wyoming Protocol] to add & configure speech-to-text and text-to-speech services

# Models

For the conversation agent [mlx-community/unsloth-gemma-4-26B-A4B-it-qat-oQ4] is used, its detailed
settings may land later once I publish the oMLX configuration files.

For speech-to-text [ggml-large-v3-turbo-q5_0.bin][whisper.cpp stt model] is used.

# Layout

## services/macos

The necessary macOS launch daemons' Plist files are stored here, along with the script to deploy them.
The services are:
- [colima]: container runtime for Docker
- [oMLX]: macOS-native OpenAI-compatible LLM server
- [whisper.cpp]: speech-to-text server

## services/docker

Contains a Docker Compose stack with the following services:
- [wyoming-piper]: text-to-speech server compatible with HA's [Wyoming Protocol]
- [wyoming-whisper]: an adapter making the whisper.cpp service compatible with [Wyoming Protocol]
- [ha-llm-tool-call-sanitizer]: a tiny proxy between HA and oMLX to account for HA's inability to handle tool calls with comma separated strings as floor/area/device names

[colima]: https://colima.run
[HA llama.cpp]: https://www.home-assistant.io/integrations/llama_cpp
[HA LLM intents]: https://github.com/skye-harris/llm_intents
[ha-llm-tool-call-sanitizer]: https://github.com/nikolaykasyanov/ha-llm-tool-call-sanitizer
[Home Assistant]: https://www.home-assistant.io
[mlx-community/unsloth-gemma-4-26B-A4B-it-qat-oQ4]: https://huggingface.co/mlx-community/unsloth-gemma-4-26B-A4B-it-qat-oQ4
[oMLX]: https://omlx.ai
[whisper.cpp stt model]: https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3-turbo-q5_0.bin
[whisper.cpp]: https://github.com/ggml-org/whisper.cpp
[Wyoming Protocol]: https://www.home-assistant.io/integrations/wyoming/
[wyoming-piper]: https://github.com/OHF-Voice/wyoming-piper
[wyoming-whisper]: https://github.com/roryeckel/wyoming_openai
