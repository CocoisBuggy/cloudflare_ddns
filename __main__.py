import argparse
import json
import logging
import os
from datetime import datetime

import requests

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
parser.add_argument("--domain-name", default=os.getenv("CLOUDFLARE_DOMAIN_NAME"))

log = logging.getLogger(__name__)


def get_public_ip():
    """Fetch the public IP address."""
    try:
        response = requests.get("https://ifconfig.me", timeout=10)
        response.raise_for_status()
        return response.text.strip()
    except requests.RequestException as e:
        logging.error(f"Failed to fetch public IP: {e}")
        return None


def update_dns_record(
    ip: str,
    zone_id: str = "",
    record: str = "",
    api_key: str = "",
    dry_run=False,
):
    """Update the DNS record on Cloudflare."""

    if not zone_id:
        raise TypeError(f"{zone_id} is not a valid Zone Id")
    if not record:
        raise TypeError(f"{record} is not a valid Record Id")

    url = (
        "https://api.cloudflare.com/client/v4/zones/%(zone_id)s/dns_records/%(record_id)s"
        % {"zone_id": zone_id, "record_id": record}
    )

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }

    data = {
        "comment": "Domain verification record",
        "content": ip,
        # "name": domain,
        "proxied": True,
        "ttl": 3600,
        "type": "A",
    }

    log.debug(url)

    try:
        if dry_run:
            return

        response = requests.put(url, headers=headers, json=data, timeout=10)
        # response.raise_for_status()
        result = response.json()

        logging.info(json.dumps(result, indent=4))

        if result.get("success"):
            log.info(f"DNS record updated successfully for {zone_id} with IP {ip}.")
        else:
            log.error(f"Failed to update DNS record: {result}")
    except requests.RequestException as e:
        log.error(f"Error updating DNS record: {e}")


if __name__ == "__main__":
    args = parser.parse_args()

    # Configure logging
    logging.basicConfig(
        filename="ddns_update.log",
        level=logging.INFO if not args.verbose else logging.DEBUG,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    ConsoleOutputHandler = logging.StreamHandler()
    log.addHandler(ConsoleOutputHandler)

    # Fetch the public IP address
    public_ip = get_public_ip()
    log.debug(f"Will try and update cloudflare with local route to net {public_ip}")

    if not args.api_key and not args.dry_run:
        log.error("MISSING API KEY")
        raise Exception("You will need to supply an API key for this script to run.")

    if public_ip:
        log.info(f"Fetched public IP: {public_ip}")

        # Update DNS record
        update_dns_record(
            public_ip,
            zone_id=args.zone_id,
            record=args.record,
            api_key=args.api_key,
            dry_run=False,
        )
    else:
        log.error("Public IP not available. Skipping DNS update.")

    log.info("Script Exiting.")
