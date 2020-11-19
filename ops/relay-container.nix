{
pkgs ? import <nixpkgs> {}
, version ? "latest"
, name ? "walletconnect/relay"
}:
let
  relay = import ./relay.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = version;
  contents = [ 
    relay
    pkgs.python38Packages.certbot-dns-cloudflare
  ];
  #extraCommands = "${pkgs.nodePackages.lerna}/bin/lerna run build";
  config = {
    WorkingDir = "/dist";
    Entrypoint = [ "${pkgs.nodejs-14_x}/bin/node /dist" ];
  };
}
