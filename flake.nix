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
          let
            docs = {
              zone = ''
                You can find this ID in the cloudflare dashboard - Just scroll down on the
                domain view, there is an 'API' section. There are good reasons not to make
                this ID be fetched via the API (Though that is actually possible, it is for
                now out of scope for this script.)
              '';
              record = ''
                Like zones in cloudflare, records have arbitrarily assigned IDs that you can
                use to address a record. This can be useful because if you edit this record in
                the cloudflare dashboard, even in drastic ways, this script will be able to
                find and update it in perpetuity. If you have this value, you should use it.
              '';
              domain = "If this is an A record, you can specify a domain name or sub domain name";
            };
          in
          {
            options.services.coco-ddns = {
              enable = lib.mkEnableOption "Enable coco-ddns service";
              interval = lib.mkOption {
                type = lib.types.str;
                default = "*-*-* 00/05:00:00";
                description = "Systemd timer interval (see systemd.time(7))";
              };

              zone_id = lib.mkOption {
                type = lib.types.str;
                description = docs.zone;
              };

              record = lib.mkOption {
                type = lib.types.str;
                description = docs.record;
              };

              domain_name = lib.mkOption {
                type = lib.types.str;
                example = "example.com";
                description = docs.domain;
              };

              api_key_file = lib.mkOption {
                type = lib.types.str;
                description = "For security, I like to pass this in as a file that contains the keyfile (sops, for example)";
                example = "/run/secrets/keys/cloudflare";
              };

              zone_id_file = lib.mkOption {
                type = lib.types.str;
                description = docs.zone;
              };

              record_file = lib.mkOption {
                type = lib.types.str;
                description = docs.record;
              };

              domain_name_file = lib.mkOption {
                type = lib.types.str;
                example = "example.com";
                description = docs.domain;
              };
            };

            config =
              let
                cfg = config.services.coco-ddns;
                readFile = file_name: "$(cat ${file_name})";
                pass = val: if cfg ? "${val}_file" then "$(cat ${cfg."${val}_file"})" else val;
                script = pkgs.writers.writeBash "coco-ddns-wrapper" ''
                  ${self.packages."${system}".default}/bin/coco-ddns \
                    --zone_id=${pass "zone_id"} \
                  --record=${pass "record"} \
                    --domain_name=${pass "domain_name"} \
                    --api_key=${readFile cfg.api_key_file}
                '';
              in
              lib.mkIf config.services.coco-ddns.enable {
                systemd.services.coco-ddns = {
                  description = "Dynamic DNS updater";
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = script;
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
