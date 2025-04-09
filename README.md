# Cloudflare Dynamic DNS Script.

The why: I want to be able to set up a simple cron job or systemd service that can periodically dispatch a request to the cloudflare api for the purposes of a dynamic DNS. Cloudflare provides a good api to this end, but for whatever reason there is not really a convienient existing tool. I have been using [Inadyn](https://github.com/troglobit/inadyn) which at the time of writing is a very well put together tool with its own configuration structure that does work pretty much straight out of the box (with docker). For my purposes, it is very much killing a mosquito with a rocket launcher.

## How to use

It is a simple python script. Any python3 environment should be able to run it as-is, but I have included a nix derivation because that is the platform I am on. You can find out about the args available by doing `python ./ --help`.

The CLI takes a handful of args that you can easily supply.

### Nix Flake

```nix
{
    description = "Example sys config";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        coco-ddns.url = "github:CocoisBuggy/cloudflare_ddns";
    };
    ...
}
```

and then in your `configuration.nix`

```nix
{ ... }:
{
    imports = [
            inputs.coco-ddns.nixosModules."<YOUR SYSTEM>".default
    ];

    services.coco-ddns = {
        enable = true;
        hosts = {
            "example.com" = {
                interval = "*-*-* 00/5:00:00";
                zone_id_file = "/run/secrets/cloudflare/zone_id";
                record_file = "/run/secrets/cloudflare/record_id";
                api_key_file = "/run/secrets/cloudflare/token";
            };
            "wireguard.example.com" = {
                proxy = false;
                interval = "*-*-* 00/5:00:00";
                zone_id_file = "/run/secrets/cloudflare/zone_id";
                record = "sdfkjsdfkjsdf";
                api_key_file = "/run/secrets/cloudflare/token";
            };
        };
    };
    ...
}
```

The above example uses files, which I feel is the most secure way to go about it. If, however, you cannot be bothered to set up your secrets in this way you can pass the values down that you want with

```nix
{ ... }:
{
    imports = [
            inputs.coco-ddns.nixosModules."<YOUR SYSTEM>".default
    ];

    services.coco-ddns = {
        enable = true;
        hosts = {
            "example.com" = {
                interval = "*-*-* 00/5:00:00";
                zone_id = "...";
                record = "...";
                # I won't let you pass this down, sorry. If you make a little keyfile locally you can pass it in as a nix path
                # and it should get copied to the nix store (ALSO A NONO) and interpreted as a string.
                # It is not a good vibe to pass this in literally, so i'm opinionated here.
                api_key_file = "<key>";
            };
        };
    };
    ...
}
```

But if you are intending to use the ddns service for something in the real world I would not advise hard coding these things in your config, as they would help attackers to identify where your services are running.

I am happy to field issues if you create them, but for the time being there is no architechture here that would make implementing other providers (basically, only cloudflare.)
