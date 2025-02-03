# Cloudflare Dynamic DNS Script.

The why: I want to be able to set up a simple cron job or systemd service that can periodically dispatch a request to the cloudflare api for the purposes of a dynamic DNS. Cloudflare provides a good api to this end, but for whatever reason there is not really a convienient existing tool. I have been using [Inadyn](https://github.com/troglobit/inadyn) which at the time of writing is a very well put together tool with its own configuration structure that does work pretty much straight out of the box (with docker). For my purposes, it is very much killing a mosquito with a rocket launcher.

## How to use

It is a simple python script. Any python3 environment should be able to run it as-is, but I have included a nix derivation because that is the platform I am on. You can find out about the args available by doing `python ./ --help`.
