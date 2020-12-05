{ pkgs ? import <nixpkgs> {}, npmlock2nix ? ../../../../programs/npmlock2nix }:
npmlock2nix.shell {
  src = ./.;
  nodejs = pkgs.nodejs-14_x;
  # node_modules_mode = "symlink", (default; or "copy")
  # You can override attributes passed to `node_modules` by setting
  # `node_modules_attrs` like below.
  # A few attributes (such as `nodejs` and `src`) are always inherited from the
  # shell's arguments but can be overriden.
  # node_modules_attrs = {
  #   buildInputs = [ pkgs.libwebp ];
  # };
}
