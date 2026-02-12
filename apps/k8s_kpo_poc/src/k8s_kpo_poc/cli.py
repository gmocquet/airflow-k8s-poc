from __future__ import annotations

import time

import typer

from k8s_kpo_poc.product import sample_product

app = typer.Typer(add_completion=False, help="Kubernetes KPO PoC CLI")
product_app = typer.Typer(add_completion=False, help="Product demo commands")


@app.command()
def hello(name: str = "World") -> None:
    """Print a friendly greeting."""
    typer.echo(f"Hello, {name}!")


@app.command()
def sleep(seconds: int = typer.Option(5, "--seconds", "-s", min=1, help="Seconds to sleep")) -> None:
    """Sleep for the requested time (used by the Airflow PoC)."""
    typer.echo(f"Sleeping for {seconds} seconds...")
    time.sleep(seconds)
    typer.echo("Done sleeping.")


@product_app.command("sample")
def product_sample(tags: list[str] = typer.Option(None, "--tag", "-t")) -> None:
    """Show the sample product payload."""
    product = sample_product(tags)
    typer.echo(product.to_json())


app.add_typer(product_app, name="product")


if __name__ == "__main__":
    app()
