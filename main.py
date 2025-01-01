import requests
import logging
import os
from datetime import datetime

# Configure logging
logging.basicConfig(
    filename="ddns_update.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def get_public_ip():
    """Fetch the public IP address."""
    try:
        response = requests.get("https://ifconfig.me", timeout=10)
        response.raise_for_status()
        return response.text.strip()
    except requests.RequestException as e:
        logging.error(f"Failed to fetch public IP: {e}")
        return None

def update_dns_record(zone_id, dns_record_id, email, api_key, domain, ip):
    """Update the DNS record on Cloudflare."""
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{dns_record_id}"
    headers = {
        "Content-Type": "application/json",
        "X-Auth-Email": email,
        "X-Auth-Key": api_key
    }
    data = {
        "comment": "Domain verification record",
        "content": ip,
        "name": domain,
        "proxied": True,
        "ttl": 3600,
        "type": "A"
    }

    try:
        response = requests.put(url, headers=headers, json=data, timeout=10)
        response.raise_for_status()
        result = response.json()

        if result.get("success"):
            logging.info(f"DNS record updated successfully for {domain} with IP {ip}.")
        else:
            logging.error(f"Failed to update DNS record: {result}")
    except requests.RequestException as e:
        logging.error(f"Error updating DNS record: {e}")

if __name__ == "__main__":
    # Cloudflare credentials and DNS info (set these as environment variables for security)
    ZONE_ID = os.getenv("CLOUDFLARE_ZONE_ID")
    DNS_RECORD_ID = os.getenv("CLOUDFLARE_DNS_RECORD_ID")
    CLOUDFLARE_EMAIL = os.getenv("CLOUDFLARE_EMAIL")
    CLOUDFLARE_API_KEY = os.getenv("CLOUDFLARE_API_KEY")
    DOMAIN = "febe.co.za"

    # Fetch the public IP address
    public_ip = get_public_ip()

    if public_ip:
        logging.info(f"Fetched public IP: {public_ip}")

        # Update DNS record
        update_dns_record(ZONE_ID, DNS_RECORD_ID, CLOUDFLARE_EMAIL, CLOUDFLARE_API_KEY, DOMAIN, public_ip)
    else:
        logging.error("Public IP not available. Skipping DNS update.")
