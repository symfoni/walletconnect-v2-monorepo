{
pkgs ? import <nixpkgs> {}
, version ? "latest"
, name ? "walletconnect/relay"
}:
let
  relay = import ./relay.nix { inherit pkgs; };
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    "${pkgs.coreutils}/bin/ls -R /nix/store" 
    "${pkgs.coreutils}/bin/ls /dist" 
    "${pkgs.coreutils}/bin/ls ${relay}/dist" 
    "${pkgs.nodejs-14_x}/bin/node /dist" 
  '';
in
#pkgs.dockerTools.buildLayeredImage {
# buildImage only saves the final docker layer derivation 
pkgs.dockerTools.buildImage {
  name = name;
  tag = version;
  contents = [ 
    pkgs.bash
    relay
    pkgs.python38Packages.certbot-dns-cloudflare
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
