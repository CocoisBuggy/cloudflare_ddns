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
          # The package itself is a simple utility. it does not do its own caching, it's own scheduling
          # it's own instrumentation, or it's own setup. As a result it's pretty straightforward to package
          # this python program into the flake
          default = pkgs.python3Packages.buildPythonApplication {
            pname = "coco-ddns";
            version = "0.2.0";
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
          let
            inherit (lib) types;
            hostOptions =
              { ... }:
              {
                options = {
                  interval = lib.mkOption {
                    type = lib.types.str;
                    default = "*-*-* 00/05:00:00";
                    description = "Systemd timer interval (see systemd.time(7))";
                  };

                  proxy = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Disable or enable cloudlfares proxy";
                  };

                  zone_id = lib.mkOption {
                    type = lib.types.str;
                  };

                  record = lib.mkOption {
                    type = lib.types.str;
                  };

                  api_key_file = lib.mkOption {
                    type = lib.types.str;
                    description = "For security, I like to pass this in as a file that contains the keyfile (sops, for example)";
                    example = "/run/secrets/keys/cloudflare";
                  };

                  zone_id_file = lib.mkOption {
                    type = lib.types.str;
                  };

                  record_file = lib.mkOption {
                    type = lib.types.str;
                  };
                };
              };
          in
          {
            options.services.coco-ddns = {
              enable = lib.mkEnableOption "Enable coco-ddns service";
              hosts = lib.mkOption {
                type = with types; attrsOf (submodule hostOptions);
              };
            };

            config =
              let
                cfg = config.services.coco-ddns;
                readFile = file_name: "$(cat ${file_name})";

                serviceUnits = lib.mapAttrs (
                  name: instance:
                  let
                    pass = val: if instance ? "${val}_file" then "$(cat ${instance."${val}_file"})" else val;
                    script = pkgs.writers.writeBash "coco-ddns-wrapper-${name}" ''
                      ${self.packages."${system}".default}/bin/coco-ddns \
                        --zone_id=${pass "zone_id"} \
                        --record=${pass "record"} \
                        --domain_name=${name} \
                        --api_key=${readFile instance.api_key_file} \
                        --proxy=${toString (instance.proxy or true)}
                    '';
                  in
                  {
                    "coco-ddns-${name}" = {
                      description = "coco-ddns service for ${name}";
                      serviceConfig = {
                        Type = "oneshot";
                        ExecStart = script;
                        Restart = "no";
                      };
                    };
                  }
                ) cfg.hosts;

                # Create a systemd timer for each enabled instance.
                timerUnits = lib.mapAttrs (name: instance: {
                  "coco-ddns-${name}" = {
                    wantedBy = [ "timers.target" ];
                    timerConfig = {
                      # Use the instance-specific interval if provided.
                      OnCalendar = instance.interval or "*-*-* 00/05:00:00";
                      Persistent = true;
                    };
                  };
                }) { } cfg.hosts;
              in
              lib.mkIf config.services.coco-ddns.enable {
                systemd.services = serviceUnits;
                systemd.timers = timerUnits;
              };
          };
      }
    );
}
