{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-rc.2";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-BYrBL1zXygPLZKGfsLrrRDzIrTWvSn5F1Z3sVoTgGTA=";
  };

  vendorHash = "sha256-mOba5VECZIj+u9Dw1nOdaxom/zV4PltEE4QpqbHDdTw=";

  patches = [ ./wings-sandbox-tests.patch ];

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
