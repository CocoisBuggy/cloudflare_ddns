{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  buildInputs = [
    (python312.witchPackages (
      ps: with ps; [
        requests
      ]
    ))
  ];
}
