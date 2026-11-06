{ user, home, apiKeyFile }:
{ config, pkgs, lib, ... }:
let
  parakeet = pkgs.fetchgit {
    url = "https://huggingface.co/mlx-community/parakeet-tdt-0.6b-v3";
    rev = "ed2b7e8c15f9aaa0b5772e2efb986255eaef7e15";
    fetchLFS = true;
    hash = "sha256-rT5tfVGSqtyOjrg4M+fWBy8GpAIdonYi10EAEi6Oh3E=";
  };
  qwen354b = pkgs.fetchgit {
    url = "https://huggingface.co/mlx-community/Qwen3.5-4B-MLX-4bit";
    rev = "32f3e8ecf65426fc3306969496342d504bfa13f3";
    fetchLFS = true;
    hash = "sha256-f90e4d8LnPIV8aMGWsqXsUTxfMzw1eizOhb/3WtO55o=";
  };
  docker-compose-env = pkgs.replaceVars ./docker/docker-compose.env.template {
    STT_API_KEY = null;
    STT_MODEL = "parakeet-tdt-0.6b-v3";
  };
in
{
  # Dedicated account for services
  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = 600;
    gid = 20;
    home = home;
    shell = "/usr/bin/false";
    isHidden = true; # keep it off the login window
  };

  environment.systemPackages = [
    (pkgs.runCommand "omlx-models" {} ''
      mkdir -p $out/share/models/mlx-community
      ln -s ${parakeet} $out/share/models/mlx-community/parakeet-tdt-0.6b-v3
      ln -s ${qwen354b} $out/share/models/mlx-community/Qwen3.5-4B-MLX-4bit
    '')
    pkgs.colima
    pkgs.docker
  ];
  environment.pathsToLink = [ "/share/models" ];

  launchd.daemons.colima = {
    serviceConfig = {
      ProgramArguments = [ (lib.getExe pkgs.colima) "start" "--foreground" "--memory" "1" ];
      UserName = user;
      GroupName = "staff";
      WorkingDirectory = home;
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        HOME = home;
        USER = user;
        PATH = lib.makeBinPath [ pkgs.colima pkgs.docker pkgs.lima ]
          + ":/usr/bin:/bin:/usr/sbin:/sbin";
      };
      ExitTimeOut = 60;
      ThrottleInterval = 30;
      StandardOutPath = "${home}/colima.log";
      StandardErrorPath = "${home}/colima.log";
    };
  };
  
  launchd.daemons.omlx = {
    script = ''
      exec /Applications/oMLX.app/Contents/MacOS/omlx-cli \
        serve \
        --model-dir ${config.system.path}/share/models \
        --port 8000 \
        --api-key "$(cat ${apiKeyFile})"
    '';
    serviceConfig = {
      UserName = user;
      GroupName = "staff";
      WorkingDirectory = home;
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        HOME = home;
        MODEL_SETTINGS_SRC = "${./omlx/model_settings.json}";
      };
      ThrottleInterval = 30;
      StandardOutPath = "${home}/omlx.log";
      StandardErrorPath = "${home}/omlx.log";
    };
  };

  system.activationScripts.preActivation.text = ''
      install -d -o ${user} -g staff -m 700 ${home}

      ln -sfn ${./omlx/model_settings.json} ${home}/.omlx/model_settings.json
  '';

  system.activationScripts.postActivation.text = ''
    install -d -o ${user} -g staff -m 700 ${home}/docker
    install -o ${user} -g staff -m 600 ${./docker/docker-compose.yml} ${home}/docker/docker-compose.yml
    cp  ${docker-compose-env} ${home}/docker/docker-compose.env
    ${pkgs.replace-secret}/bin/replace-secret @STT_API_KEY@ ${apiKeyFile} ${home}/docker/docker-compose.env

    #TODO wait for colima to start/docker daemon to be available!
    sudo -u ${user} -H ${pkgs.docker}/bin/docker compose --file ${home}/docker/docker-compose.yml up --detach 
  '';
}
