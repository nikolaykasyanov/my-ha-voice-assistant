This repo contains the config & prompts of my [Home Assistant]-powered voice assistant.

# Home Assistant

The setup relies on the following HA integrations:
- [llama.cpp][HA llama.cpp] to add & configure [oMLX] as a conversation agent
- [Tools for Assist][HA LLM intents] (custom integration) for additional tools & better home
control tools' configuratbility
- [Wyoming Protocol] to add & configure speech-to-text and text-to-speech services

# Models

For the conversation agent [mlx-community/mlx-community/Qwen3.5-4B-MLX-4bit] is used, its detailed
settings can be found in [here](omlx/model_settings.json).

For speech-to-text [parakeet-tdt-0.6b-v3][stt model] is used.

# Layout

## module.nix

Contains a [nix-darwin] module that:
- defines the user that runs all the services
- defines & provisions macOS launchd services
    - [colima]
    - [oMLX]
- provisions the docker compose setup
- defines & downloads the necessary models

## docker

Contains a Docker Compose stack with the following services:
- [wyoming-piper]: text-to-speech server compatible with HA's [Wyoming Protocol]
- [wyoming-whisper]: an adapter making OpenAI-compatible endpoints compatible with the [Wyoming Protocol]
- [ha-llm-tool-call-sanitizer]: a tiny proxy between HA and oMLX to account for HA's inability to handle tool calls with comma separated strings as floor/area/device names

## omlx

Contains [oMLX] settings.

# Running

This repo assumes that [nix-darwin] is used via flakes. The setup can be added to your flake like this:

```nix
{
  ...
  inputs = {
    ...
    my-ha-voice-assistant = {
      url = "git+https://github.com/nikolaykasyanov/my-ha-voice-assistant.git";
      flake = false;
    };
  };

  let
    ...
  in
  {
    darwinConfigurations."foobar" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        (import "${my-ha-voice-assistant}/module.nix" {
          user = "_voice_assistant";
          home = "/var/lib/_voice_assistant";
          apiKeyFile = "/path/to/.omlx-api-key";
        })
      ]
    };
  };
}
```

## Installing oMLX

Download the latest release DMG and put oMLX.app into /Applications.
You may want to run it before proceeding to adjust the settings, download the model and adjust its
settings. This will become unnecessary once oMLX settings are a part of this repo.

[colima]: https://colima.run
[HA llama.cpp]: https://www.home-assistant.io/integrations/llama_cpp
[HA LLM intents]: https://github.com/skye-harris/llm_intents
[ha-llm-tool-call-sanitizer]: https://github.com/nikolaykasyanov/ha-llm-tool-call-sanitizer
[Home Assistant]: https://www.home-assistant.io
[mlx-community/mlx-community/Qwen3.5-4B-MLX-4bit]: https://huggingface.co/mlx-community/mlx-community/Qwen3.5-4B-MLX-4bit
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[oMLX]: https://omlx.ai
[stt model]: https://huggingface.co/mlx-community/parakeet-tdt-0.6b-v3/tree/main
[Wyoming Protocol]: https://www.home-assistant.io/integrations/wyoming/
[wyoming-piper]: https://github.com/OHF-Voice/wyoming-piper
[wyoming-whisper]: https://github.com/roryeckel/wyoming_openai
