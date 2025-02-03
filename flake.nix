{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python3;
        pythonPackages = python.pkgs;
      in
      {
        packages = {
          default = pkgs.python3Packages.buildPythonApplication {
            pname = "coco-ddns";
            version = "0.1.0";
            src = ./.;
            pyproject = true;

            nativeBuildInputs = [
              pkgs.python3Packages.setuptools
              pkgs.python3Packages.wheel
              pkgs.python3Packages.pyproject-hooks
            ];

            propagatedBuildInputs = with pythonPackages; [
              # Add your Python dependencies here
              requests
            ];

            postInstall = ''
              mkdir -p $out/bin
              echo "Checking for coco-ddns:"
              ls -l $out/bin/coco-ddns || exit 1
            '';
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/coco-ddns";
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pythonPackages; [
            python
            requests
            pip
            setuptools
            wheel
            self.packages.${system}.default
          ];

          shellHook = ''
            echo "Cloudflare DDNS Client development shell"
          '';
        };
      }
    );
}
