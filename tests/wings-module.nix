{ nixpkgs, wingsModule, system }:
let
  pkgs = nixpkgs.legacyPackages.${system};
  makeConfig = settings: extra: (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      wingsModule
      {
        system.stateVersion = "26.05";
        boot.isContainer = true;
        services.wings = {
          node = {
            uuid = "test-node";
            tokenId = "test-id";
            tokenPath = "/run/wings-token";
            remote = "https://panel.example";
          };
        } // settings;
      }
      extra
    ];
  }).config;
  docker = makeConfig { enable = true; } { };
  podman = makeConfig {
    enable = true;
    containerBackend = "podman";
  } { };
  both = makeConfig { enable = true; containerBackend = "podman"; } {
    virtualisation.docker.enable = true;
  };
  disabled = makeConfig { enable = false; containerBackend = "podman"; } { };
in
assert docker.services.wings.containerBackend == "docker";
assert docker.services.wings.containerLogConfig == null;
assert docker.virtualisation.docker.enable;
assert !docker.virtualisation.podman.enable;
assert builtins.elem "docker.service" docker.systemd.services.wings.requires;
assert builtins.elem "docker.service" docker.systemd.services.wings.after;
assert docker.systemd.services.wings.serviceConfig.SupplementaryGroups == [ "docker" ];
assert docker.users.users.pelican.extraGroups == [ "docker" ];
assert !(docker.systemd.services.wings.environment ? DOCKER_HOST);
assert podman.virtualisation.podman.enable;
assert podman.services.wings.containerLogConfig.type == "k8s-file";
assert podman.services.wings.containerLogConfig.config == { };
assert !podman.virtualisation.docker.enable;
assert !podman.virtualisation.podman.dockerSocket.enable;
assert podman.systemd.sockets.podman.socketConfig.SocketGroup == "podman";
assert builtins.elem "podman.socket" podman.systemd.services.wings.requires;
assert builtins.elem "podman.socket" podman.systemd.services.wings.after;
assert !(builtins.elem "docker.service" podman.systemd.services.wings.requires);
assert podman.systemd.services.wings.environment.DOCKER_HOST == "unix:///run/podman/podman.sock";
assert podman.systemd.services.wings.serviceConfig.SupplementaryGroups == [ "podman" ];
assert podman.users.users.pelican.extraGroups == [ "podman" ];
assert both.virtualisation.docker.enable;
assert both.virtualisation.podman.enable;
assert !both.virtualisation.podman.dockerSocket.enable;
assert both.systemd.services.wings.environment.DOCKER_HOST == "unix:///run/podman/podman.sock";
assert !disabled.virtualisation.podman.enable;
pkgs.runCommand "wings-module-evaluation" { } "touch $out"
