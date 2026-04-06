FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

WORKDIR /home/nonroot/app
ENV HOME=/home/nonroot
ENV UV_CACHE_DIR=/home/nonroot/uv-cache

# Pre-create cache directory owned by non-root
RUN mkdir -p /home/nonroot/uv-cache && chown -R 999:999 /home/nonroot/uv-cache

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Switch to non-root user for all uv operations
USER nonroot

# Install dependencies using uv (as non-root)
RUN --mount=type=cache,target=/home/nonroot/uv-cache \
    uv sync --locked --no-install-project

# Copy project code
COPY --chown=999:999 . .

# Install project
RUN --mount=type=cache,target=/home/nonroot/uv-cache \
    uv sync --locked

# Run the app
CMD ["uv", "run", "main.py"]