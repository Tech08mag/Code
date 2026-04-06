FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

WORKDIR /app

RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

COPY pyproject.toml uv.lock* ./

# Create a venv using copies to avoid broken stdlib links
RUN python -m venv --copies /app/.venv \
    && /app/.venv/bin/pip install --upgrade pip setuptools wheel

ENV PATH="/app/.venv/bin:$PATH"

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

COPY --chown=999:999 . .

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

USER nonroot

# ⚠ Explicitly call Python from the virtual environment
CMD ["/app/.venv/bin/python", "main.py"]