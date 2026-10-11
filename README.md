This repo contains the config & prompts of my [Home Assistant]-powered voice assistant.

# Layout

## services/macos

The necessary macOS launch daemons' Plist files are stored here, along with the script to deploy them.
The services are:
- [colima]: container runtime for Docker
- [oMLX]: macOS-native OpenAI-compatible LLM server
- [whisper.cpp]: speech-to-text server

## services/docker

Contains a Docker compose stack with the following services:
- [wyoming-piper]: text-to-speech server compatible with HA's [Wyoming Protocol]
- [wyoming-whisper]: an adapter making the whisper.cpp service compatible with [Wyoming Protoocl]
- [ha-llm-tool-call-sanitizer]: a tiny proxy between HA and oMLX to account for HA's inability to handle tool calls with comma separated strings as floor/area/device names

[colima]: https://colima.run
[ha-llm-tool-call-sanitizer]: https://github.com/nikolaykasyanov/ha-llm-tool-call-sanitizer
[Home Assistant]: https://www.home-assistant.io
[oMLX]: https://omlx.ai
[whisper.cpp]: https://github.com/ggml-org/whisper.cpp
[Wyoming Protocol]: https://www.home-assistant.io/integrations/wyoming/
[wyoming-piper]: https://github.com/OHF-Voice/wyoming-piper
[wyoming-whisper]: https://github.com/roryeckel/wyoming_openai
