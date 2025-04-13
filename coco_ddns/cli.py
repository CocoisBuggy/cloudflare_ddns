#!/usr/bin/env python

import json
import logging
from datetime import datetime

import requests

from .args import parser

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
    domain_name: str = "",
    cloudflare_proxy=True,
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
        "comment": f"Domain verification record @ ({datetime.now()})",
        "content": ip,
        "proxied": cloudflare_proxy,
        "ttl": 3600,
        "type": "A",
    }

    if domain_name:
        data["name"] = domain_name

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


def main():
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
            domain_name=args.domain_name,
            dry_run=False,
            cloudflare_proxy=args.proxy,
        )
    else:
        log.error("Public IP not available. Skipping DNS update.")

    log.info("Script Exiting.")


if __name__ == "__main__":
    main()
