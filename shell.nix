{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  buildInputs = [
    (pkgs.python312.withPackages (
      ps: with ps; [
        requests
      ]
    ))
  ];

  mkShell = ''
    if [ -f ".env" ]; then
      set -a
      source .env
      echo "Sourcing local .env into dev environment 😄"
    fi
  '';
}
