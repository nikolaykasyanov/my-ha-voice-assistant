{ user, home, apiKeyFile }:
{ config, pkgs, lib, ... }:
let
  kapitsa-bin = pkgs.callPackage ./packages/kapitsa-bin/package.nix {};
  omlx-bin = pkgs.callPackage ./packages/omlx-bin/package.nix {};
  parakeet = pkgs.fetchgit {
    url = "https://huggingface.co/mlx-community/parakeet-tdt-0.6b-v3";
    rev = "ed2b7e8c15f9aaa0b5772e2efb986255eaef7e15";
    fetchLFS = true;
    hash = "sha256-rT5tfVGSqtyOjrg4M+fWBy8GpAIdonYi10EAEi6Oh3E=";
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
    '')
    kapitsa-bin
    omlx-bin
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
        PATH = lib.makeBinPath [ pkgs.colima ] + ":/usr/bin:/bin:/usr/sbin:/sbin";
      };
      # Full colima shutdown takes some time and terminating it before that leaves it kind-of-running, see https://github.com/lima-vm/lima/pull/5088.
      ExitTimeOut = 60;
      ThrottleInterval = 30;
      StandardOutPath = "${home}/colima.log";
      StandardErrorPath = "${home}/colima.log";
    };
  };

  launchd.daemons.kapitsa = {
    script = ''
      exec ${kapitsa-bin}/bin/kapitsa \
        serve \
        --model qwen3.5-9b \
        --private \
        --port 8001 \
        --api-key "$(cat ${apiKeyFile})" \
        --mem-budget 10
    '';
    serviceConfig = {
      UserName = user;
      GroupName = "staff";
      WorkingDirectory = home;
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        HOME = home;
      };
      ThrottleInterval = 30;
      StandardOutPath = "${home}/kapitsa.log";
      StandardErrorPath = "${home}/kapitsa.log";
    };
  };

  launchd.daemons.omlx = {
    script = ''
      exec ${omlx-bin}/bin/omlx-cli \
        serve \
        --model-dir ${config.system.path}/share/models \
        --port 8000 \
        --api-key "$(cat ${apiKeyFile})" \
        --hot-cache-max-size 1GB \
        --paged-ssd-cache-max-size 5GB
    '';
    serviceConfig = {
      UserName = user;
      GroupName = "staff";
      WorkingDirectory = home;
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        HOME = home;
        # This env var is supposed to trigger service reload when the file path changes (and hence its contents).
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

  system.activationScripts.postActivation.text = let
    asUser = lib.concatStringsSep " " [
      "sudo -u ${user} -H env"
      "PATH=${lib.makeBinPath [ pkgs.docker pkgs.docker-compose ]}:/usr/bin:/bin"
      "DOCKER_HOST=unix://${home}/.colima/default/docker.sock"
    ];
  in ''
    install -d -o ${user} -g staff -m 700 ${home}/docker
    install -o ${user} -g staff -m 600 ${./docker/docker-compose.yml} ${home}/docker/docker-compose.yml
    cp  ${docker-compose-env} ${home}/docker/docker-compose.env
    ${pkgs.replace-secret}/bin/replace-secret @STT_API_KEY@ ${apiKeyFile} ${home}/docker/docker-compose.env

    docker_ready=0
    for _ in $(seq 1 60); do
      if ${asUser} ${pkgs.docker}/bin/docker info >/dev/null 2>&1; then
        docker_ready=1
        break
      fi
      sleep 2
    done

    if [ "$docker_ready" = 1 ]; then
      ${asUser} ${pkgs.docker-compose}/bin/docker-compose --file ${home}/docker/docker-compose.yml up --detach
    else
      echo "warning: docker not ready after 120s, skipping compose up" >&2
    fi
  '';
}
