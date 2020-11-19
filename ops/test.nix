{
pkgs ? import <nixpkgs> {}
}:
let
  index = pkgs.writeFile "index.js" ''
    let name = process.argv[2] || "World";
    console.log("Hello", name);
  '';
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.nodejs-14_x}/bin/node ${index}
  '';
in
pkgs.dockerTools.buildImage {
  name = "hello";
  contents = [ 
    pkgs.hello
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
