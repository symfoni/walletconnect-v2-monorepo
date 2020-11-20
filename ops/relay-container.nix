{
pkgs ? import <nixpkgs> {}
, version ? "latest"
, name ? "walletconnect/relay"
, relaysrc ? ../dist/relay.tar.gz
}:
let
  relay = import ./relay.nix { inherit pkgs; src = relaysrc; };
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.nodejs-14_x}/bin/node ${relay}/dist
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = version;
  contents = [ 
    pkgs.python38Packages.certbot-dns-cloudflare
    relay
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
