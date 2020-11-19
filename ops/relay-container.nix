{
pkgs ? import <nixpkgs> {}
, version ? "latest"
, name ? "walletconnect/relay"
}:
let
  relay = import ./relay.nix { inherit pkgs; };
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.coreutils}/bin/ls ${relay}
    ${pkgs.coreutils}/bin/ls ${relay}/dist
    ${pkgs.nodejs-14_x}/bin/node ${relay}/dist
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = version;
  contents = [ 
    relay
    pkgs.python38Packages.certbot-dns-cloudflare
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
