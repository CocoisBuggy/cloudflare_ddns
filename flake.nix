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

        # For the sake of my adoring fans, we expose some nixos module services.
        nixosModules.default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            options.services.coco-ddns = {
              enable = lib.mkEnableOption "Enable coco-ddns service";
              interval = lib.mkOption {
                type = lib.types.str;
                default = "*-*-* 00/05:00:00";
                description = "Systemd timer interval (see systemd.time(7))";
              };
            };

            config = lib.mkIf config.services.coco-ddns.enable {
              systemd.services.coco-ddns = {
                description = "Dynamic DNS updater";
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${self.packages."${system}"}/bin/coco-ddns";
                  Restart = "no";
                };
              };

              systemd.timers.coco-ddns = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = config.services.coco-ddns.interval;
                  Persistent = true;
                };
              };
            };
          };
      }
    );
}
