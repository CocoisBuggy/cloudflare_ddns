import argparse
import os

parser = argparse.ArgumentParser("DDNS script")
parser.add_argument(
    "--dry-run",
    help="If set, the script will not send off requests to the cloudflare API",
    action="store_true",
)

parser.add_argument(
    "--verbose",
    help="Increase log verbosity to the STDOut",
    action="store_true",
)

parser.add_argument(
    "--zone_id",
    help="""You can find this ID in the cloudflare dashboard - Just scroll 
    down on the domain view, there is an 'API' section. There are good reasons
    not to make this ID be fetched via the API (Though that is actually possible,
    it is for now out of scope for this script.)
    """,
    default=os.getenv("CLOUDFLARE_ZONE_ID"),
)

parser.add_argument(
    "--record",
    help="""
    Like zones in cloudflare, records have arbitrarily assigned IDs that you can
    use to address a record. This can be useful because if you edit this record
    in the cloudflare dashboard, even in drastic ways, this script will be able to
    find and update it in perpetuity. If you have this value, you should use it.
    """,
    default=os.getenv("CLOUDFLARE_DNS_RECORD_ID"),
)

parser.add_argument(
    "--api_key",
    help="""
    Your cloudflare API key is used to update the DNS record - it is a good idea
    to set this up as scoped to the domain(s) that you are interested in updating.
    Head over to the [cloudflare dashboard]() to set up a token if you do not already
    have one.

    I would suggest not passing this as an arg, since it would be more secure to
    set the CLOUDFLARE_API_KEY environment variable 
    """,
    default=os.getenv("CLOUDFLARE_API_KEY"),
)

parser.add_argument("--domain_name", default=os.getenv("CLOUDFLARE_DOMAIN_NAME"))

parser.add_argument(
    "--proxy",
    help="""
    By default, the tool will keep Cloudflare's proxy setting ON. This is a good idea for
    many use cases but you may find that in some instances you need to disable this.
    If, for example, you are trying to hit certain ports or use UDP traffic for non HTTP/S
    traffic you may run into problems (This may only apply to people who are using the free
    version of the cloudflare services, so don't quote me on it).

    A concrete example would be trying to create a wireguard link to a home network. If you are
    trying to not pay a lot, you can just toggle proxy off.
    """,
    default=True,
)
