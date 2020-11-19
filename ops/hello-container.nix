{
pkgs ? import <nixpkgs> {}
, name ? "hello-container"
}:
let
  hello = import ./hello.nix { inherit pkgs; };
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.coreutils}/bin/ls /
    ${hello}/hello.sh $1
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  contents = [ 
    hello
  ];
  config = {
    WorkingDir = "/hello";
    Cmd = [ "${hello}/hello.sh" ];
    #Entrypoint = [ entrypoint ];
  };
}
