FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

WORKDIR /home/nonroot/app
ENV HOME=/home/nonroot
ENV UV_CACHE_DIR=/home/nonroot/uv-cache

# Set permissions on the cache directory
RUN mkdir -p /home/nonroot/uv-cache && \
    chown -R nonroot:nonroot /home/nonroot/uv-cache

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv as root (cache mount is root-owned)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project && \
    chown -R nonroot:nonroot /home/nonroot/uv-cache

# Copy project code
COPY . .

# Install project as root (cache mount is root-owned)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Change ownership of the project files to nonroot user
RUN chown -R nonroot:nonroot /home/nonroot/app

# Switch to non-root for runtime
USER nonroot
CMD ["uv", "run", "main.py"]
