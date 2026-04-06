FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

WORKDIR /app

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

# Copy dependency files for caching
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv (without creating another venv)
ENV UV_TOOL_BIN_DIR=/usr/local/bin
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

# Copy the rest of the source code
COPY --chown=999:999 . .

# Install the project itself
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Use UV's Python automatically; no venv needed
ENV PATH="/app/.venv/bin:$PATH"

USER nonroot
CMD ["python", "main.py"]