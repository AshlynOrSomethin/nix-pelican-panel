# Nix Pelican Panel

Run Pelican Panel on NixOS

> [!WARNING]
> This readme assumes you did not modify default settings. Some commands may need to change if you do.

The automated updater follows the most recently published Panel and Wings releases,
including GitHub prereleases. Draft releases are excluded.

## Usage

**Update your flake**

```nix
inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    pelican-panel = {
      url = "github:mpeterson2/nix-pelican-panel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
outputs =
  {
    nixpkgs,
    ...
  }@inputs:
  {
    nixosConfigurations = {
      <hostname> = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ... ];
      };
    };
  };
```

**Update your configuration.nix**

```nix
{ inputs, config, ... }:
{
  imports = [
    inputs.pelican-panel.nixosModules.pelican-panel
  ];

  services.pelican-panel = {
    enable = true;
    nginx.enable = true;
  };
}
```

**Setup the env file**

Run `sudo -u pelican-panel pelican-panel-artisan p:environment:setup`.

You can now modify the env in `/srv/http/pelican-panel/.env`.

Note: prior to running this, you may see some services failing. These services are typically enabled when you install the panel.

**Run migrations**

Run `sudo -u pelican-panel pelican-panel-artisan migrate`.

**Install your panel**

Navigate to your pelican panel's `/installer` route and follow the instructions. When it comes to the page where it asks you to run commands, you can ignore it, they're already ran for you.

**Setup Wings**

On the panel, create a wing, note the config and translate it to nix config:

```nix
{ inputs, config, ... }:
{
  imports = [
    inputs.pelican-panel.nixosModules.wings
  ];

  services.wings = {
    enable = true;
    node = {
      uuid = "<node-uuid>";
      tokenId = "<node-token>";
      # Recommended to use sops or another form of encrypting this value
      tokenPath = config.sops.secrets.wings-token.path;
      remote = "<node-remote>";
    };
  };
}
```

Note: This package provides the rest of the config as defaults, so no need to edit if you want to keep those.

**Use Podman for Wings**

Wings uses Docker by default. To use the rootful Podman system socket instead,
set `services.wings.containerBackend = "podman";`. This enables Podman and
does not replace Docker's socket, so other Docker services can continue running.
Access to the rootful Podman socket grants root-equivalent control of the host.

Docker and Podman keep separate containers, images, and networks. Switching the
backend does not migrate running servers or their data: stop Wings-managed
containers, back up server data, and plan for downtime and rollback before
switching. Verify port bindings, networking, server startup, and backups after
the change. Wings' configured data directory remains the same. In particular,
Wings uses the `pelican0` bridge and a default `172.18.0.0/16` subnet; an
existing Docker Wings network may conflict with the new Podman network. Plan
and test the network transition before starting Wings against Podman.
