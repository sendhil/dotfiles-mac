#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "boto3>=1.28.0",
#     "rich>=13.0.0",
# ]
# ///

import argparse
import collections
import sys
import boto3
from botocore.exceptions import ProfileNotFound, NoCredentialsError, ClientError

from rich.console import Console
from rich.table import Table
from rich.panel import Panel

def get_pricing(model_id, pricing_data):
    # Normalize model ID: strip prefixes like us., eu., apac., global.
    base_id = model_id
    for prefix in ["us.", "eu.", "apac.", "global."]:
        if base_id.startswith(prefix):
            base_id = base_id[len(prefix):]
            break
            
    keys_to_try = [
        model_id,
        base_id,
        f"bedrock/{model_id}",
        f"bedrock/{base_id}",
        f"bedrock_converse/{model_id}",
        f"bedrock_converse/{base_id}"
    ]
    
    for key in keys_to_try:
        if key in pricing_data:
            entry = pricing_data[key]
            input_cost = entry.get("input_cost_per_token")
            output_cost = entry.get("output_cost_per_token")
            if input_cost is not None or output_cost is not None:
                return {
                    "input_cost_1m": (input_cost * 1_000_000) if input_cost is not None else None,
                    "output_cost_1m": (output_cost * 1_000_000) if output_cost is not None else None,
                    "mode": entry.get("mode"),
                    "output_cost_per_image": entry.get("output_cost_per_image")
                }
    return None

def main():
    parser = argparse.ArgumentParser(
        description="List and group AWS Bedrock foundation models with context and pricing."
    )
    parser.add_argument(
        "--profile",
        default="claude-com",
        help="AWS CLI profile name (default: claude-com)"
    )
    parser.add_argument(
        "--region",
        default="us-west-2",
        help="AWS region name (default: us-west-2)"
    )
    parser.add_argument(
        "--search",
        "-q",
        help="Search query to filter model IDs and names (case-insensitive)"
    )
    parser.add_argument(
        "--active-only",
        "-a",
        action="store_true",
        help="Only show models with ACTIVE status (exclude LEGACY/DEPRECATED)"
    )
    parser.add_argument(
        "--no-pricing",
        action="store_true",
        help="Disable fetching and displaying pricing information"
    )

    args = parser.parse_args()
    console = Console()

    pricing_data = {}
    if not args.no_pricing:
        console.print("[dim]Downloading latest pricing directory from LiteLLM...[/dim]")
        try:
            import urllib.request
            import json
            req = urllib.request.Request(
                "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json",
                headers={'User-Agent': 'Mozilla/5.0'}
            )
            with urllib.request.urlopen(req, timeout=5) as response:
                pricing_data = json.loads(response.read().decode())
        except Exception as e:
            console.print(f"[dim yellow]Warning: Could not fetch pricing data ({e}). Running without prices.[/dim yellow]")

    try:
        session = boto3.Session(profile_name=args.profile)
        client = session.client("bedrock", region_name=args.region)
    except ProfileNotFound:
        console.print(f"[bold red]Error:[/bold red] AWS profile '{args.profile}' not found.", err=True)
        sys.exit(1)
    except Exception as e:
        console.print(f"[bold red]Error initializing AWS session:[/bold red] {e}", err=True)
        sys.exit(1)

    console.print(
        f"[bold blue]Fetching AWS Bedrock models for profile '{args.profile}' in region '{args.region}'...[/bold blue]"
    )

    try:
        response = client.list_foundation_models()
    except NoCredentialsError:
        console.print("[bold red]Error:[/bold red] AWS credentials not found.", err=True)
        sys.exit(1)
    except ClientError as e:
        console.print(f"[bold red]AWS API Error:[/bold red] {e.response['Error']['Message']}", err=True)
        sys.exit(1)
    except Exception as e:
        console.print(f"[bold red]Error calling list_foundation_models:[/bold red] {e}", err=True)
        sys.exit(1)

    models = response.get("modelSummaries", [])
    if not models:
        console.print("[yellow]No models found.[/yellow]")
        sys.exit(0)

    # Filtering
    filtered_models = []
    for model in models:
        # Check active-only
        if args.active_only:
            status = model.get("modelLifecycle", {}).get("status", "UNKNOWN")
            if status != "ACTIVE":
                continue

        # Check search query
        if args.search:
            q = args.search.lower()
            name = model.get("modelName", "").lower()
            model_id = model.get("modelId", "").lower()
            if q not in name and q not in model_id:
                continue

        filtered_models.append(model)

    if not filtered_models:
        console.print("[yellow]No models matched the search criteria.[/yellow]")
        sys.exit(0)

    # Grouping by provider
    grouped = collections.defaultdict(list)
    for model in filtered_models:
        provider = model.get("providerName", "Other")
        grouped[provider].append(model)

    # Render groups
    for provider in sorted(grouped.keys()):
        provider_models = sorted(grouped[provider], key=lambda x: x.get("modelName", ""))
        
        # Create a table for each provider
        table = Table(
            title=f"[bold cyan]{provider}[/bold cyan]",
            title_justify="left",
            expand=True,
            show_header=True,
            header_style="bold magenta",
        )
        table.add_column("Model Name", ratio=3)
        table.add_column("Model ID", ratio=4)
        table.add_column("Input / Output Modalities", ratio=2)
        if not args.no_pricing and pricing_data:
            table.add_column("Cost (per 1M) [In / Out]", ratio=2, justify="right")
        table.add_column("Status", ratio=1, justify="center")

        for m in provider_models:
            name = m.get("modelName", "Unknown")
            model_id = m.get("modelId", "Unknown")
            
            inputs = ", ".join(m.get("inputModalities", []))
            outputs = ", ".join(m.get("outputModalities", []))
            modalities = f"{inputs} -> {outputs}" if inputs and outputs else (inputs or outputs or "N/A")
            
            status_info = m.get("modelLifecycle", {})
            status = status_info.get("status", "ACTIVE")
            
            if status == "ACTIVE":
                status_str = f"[bold green]{status}[/bold green]"
            elif status == "LEGACY":
                status_str = f"[bold yellow]{status}[/bold yellow]"
            else:
                status_str = f"[bold red]{status}[/bold red]"

            row_data = [name, f"[dim]{model_id}[/dim]", modalities]

            if not args.no_pricing and pricing_data:
                pricing = get_pricing(model_id, pricing_data)
                pricing_str = "-"
                if pricing:
                    if pricing.get("mode") == "image_generation":
                        img_cost = pricing.get("output_cost_per_image")
                        if img_cost is not None:
                            pricing_str = f"${img_cost:.3f} / img"
                    else:
                        in_cost = pricing.get("input_cost_1m")
                        out_cost = pricing.get("output_cost_1m")
                        if in_cost is not None and out_cost is not None:
                            pricing_str = f"${in_cost:.2f} / ${out_cost:.2f}"
                        elif in_cost is not None:
                            pricing_str = f"${in_cost:.2f} (In)"
                        elif out_cost is not None:
                            pricing_str = f"${out_cost:.2f} (Out)"
                row_data.append(pricing_str)

            row_data.append(status_str)
            table.add_row(*row_data)

        console.print(Panel(table, border_style="dim"))

if __name__ == "__main__":
    main()
