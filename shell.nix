{
  pkgs ? import <nixpkgs> { },
}:
let

  client = import ./default.nix { inherit pkgs; };

in
pkgs.mkShell {
  buildInputs = [ client ];
}
