#!/usr/bin/env python3
"""
AWS Notify CLI Tool
==================

A command-line interface for sending notifications through the aws_notify service.

Installation
-----------
Make sure you have the required dependencies installed:
    make install

Usage
-----
1. Send a notification:
    ./notify_cli.py send "Your message here"

2. Send with a custom subject:
    ./notify_cli.py send "Your message" --subject "Custom Subject"
    ./notify_cli.py send "Your message" -s "Custom Subject"  # Short form

3. Get JSON output (useful for scripts):
    ./notify_cli.py send "Your message" --json

4. Check service health:
    ./notify_cli.py health

Examples
--------
Basic notification:
    $ ./notify_cli.py send "Deployment completed successfully"

With subject line:
    $ ./notify_cli.py send "CPU usage above 90%" -s "High CPU Alert"

JSON output:
    $ ./notify_cli.py send "Test message" --json
    {
      "success": true,
      "message": "Notification sent successfully (ID: msg-123...)"
    }

Health check:
    $ ./notify_cli.py health
    Service is healthy

Exit Codes
---------
0: Success
1: Error (service unreachable, invalid input, etc.)

Requirements
-----------
- Python 3.6+
- Running aws_notify service (localhost:5889)
- Virtual environment with dependencies installed
"""

import click
import requests
import sys
import json
from typing import Optional

def send_notification(message: str, subject: Optional[str] = None) -> tuple[bool, str]:
    """
    Send a notification through the aws_notify service.

    Args:
        message: The message to send
        subject: Optional subject line for the notification

    Returns:
        Tuple of (success: bool, message: str)
    """
    url = "http://localhost:5889/notify"
    payload = {"message": message}
    if subject:
        payload["subject"] = subject

    try:
        response = requests.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            return True, f"Notification sent successfully (ID: {data['message_id']})"
        else:
            return False, f"Failed to send notification: {response.text}"

    except requests.RequestException as e:
        return False, f"Connection error: {str(e)}"

@click.group()
def cli():
    """CLI tool for sending notifications through aws_notify service."""
    pass

@cli.command()
@click.argument('message', required=True)
@click.option('--subject', '-s', help='Optional subject for the notification')
@click.option('--json', 'json_output', is_flag=True, help='Output response in JSON format')
def send(message: str, subject: Optional[str], json_output: bool):
    """Send a notification through the service.

    MESSAGE is the text content to send in the notification.
    """
    success, result = send_notification(message, subject)

    if json_output:
        output = {
            "success": success,
            "message": result
        }
        click.echo(json.dumps(output, indent=2))
    else:
        if success:
            click.secho(result, fg='green')
        else:
            click.secho(result, fg='red')
            sys.exit(1)

@cli.command()
def health():
    """Check if the notification service is healthy."""
    try:
        response = requests.get("http://localhost:5889/health", timeout=5)
        if response.status_code == 200:
            click.secho("Service is healthy", fg='green')
        else:
            click.secho(f"Service is unhealthy (HTTP {response.status_code})", fg='red')
            sys.exit(1)
    except requests.RequestException as e:
        click.secho(f"Service is unreachable: {str(e)}", fg='red')
        sys.exit(1)

if __name__ == '__main__':
    cli()