{
  pkgs ? import <nixpkgs> { },
}:
pkgs.python3Packages.buildPythonApplication {
  pname = "cloudflare_ddns";
  version = "0.1";
  src = ./.;

  propogatedBuildImports = with pkgs.python3Packages; [
    requests
  ];

  # Set up an entry point for your application
  postInstall = ''
    mkdir -p $out/bin
    echo '#!/usr/bin/env python3' > $out/bin/ddns_update
    echo 'import sys; from __main__ import main; sys.exit(main())' >> $out/bin/ddns_update
    chmod +x $out/bin/ddns_update
  '';

  meta = {
    description = "A simple Python DDNS update script for Cloudflare zones";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [ cocoIsBuggy ];
  };
}
