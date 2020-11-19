{
pkgs ? import <nixpkgs> {}
}:
let
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.hello}/bin/hello
  '';
in
#pkgs.dockerTools.buildLayeredImage {
# buildImage only saves the final docker layer derivation 
pkgs.dockerTools.buildImage {
  name = "hello";
  contents = [ 
    pkgs.hello
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
