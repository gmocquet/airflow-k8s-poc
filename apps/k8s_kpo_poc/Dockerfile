# Multi-stage build using uv base image
FROM python:3.14.6-slim-trixie AS builder
WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:0.11.29 /uv /uvx /bin/

# Copy project metadata first for better layer caching
COPY pyproject.toml ./
COPY src ./src

# Install project into a local virtual environment without dev deps
RUN uv sync --no-dev --compile --package k8s-kpo-poc

# Runtime image
FROM python:3.14.6-slim-trixie
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src ./src
ENV PATH="/app/.venv/bin:${PATH}"

ENTRYPOINT ["k8s-kpo-poc"]
CMD ["hello"]
