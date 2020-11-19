
{
  pkgs ? import <nixpkgs> {}
, name ? "hello-node"
, src ? ../.
}:
let
  index = pkgs.writeText "index.js" ''
    let name = process.argv[2] || "World";
    console.log("Hello", name);
  '';
  entry = pkgs.writeScript "hello.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.nodejs-14_x}/bin/node ${index} $1
  '';
in
pkgs.stdenv.mkDerivation {
  name = name;
  src = src;
  buildInputs = [ pkgs.nodejs-14_x ];
  HOME=".";
  buildPhase = '''';
  installPhase = ''
   mkdir $out
   cp -r ${entry} $out/
  '';
}
