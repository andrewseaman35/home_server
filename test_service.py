#!/usr/bin/env python3
import requests
import sys
import time
from typing import Tuple

def check_health(retries: int = 5, delay: float = 1.0) -> Tuple[bool, str]:
    """
    Check the health endpoint of the service.

    Args:
        retries: Number of times to retry if the service is not healthy
        delay: Delay in seconds between retries

    Returns:
        Tuple of (success: bool, message: str)
    """
    url = "http://localhost:5889/health"

    for attempt in range(retries):
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                return True, "Service is healthy"
            else:
                message = f"Unhealthy response (HTTP {response.status_code}): {response.text}"
        except requests.RequestException as e:
            message = f"Connection error: {str(e)}"

        if attempt < retries - 1:
            print(f"Attempt {attempt + 1} failed. Retrying in {delay} seconds...")
            time.sleep(delay)

    return False, message

def main():
    print("Testing aws_notify service health...")
    success, message = check_health()

    print(message)
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
