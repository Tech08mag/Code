FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

# Set workdir and home
USER nonroot
WORKDIR /home/nonroot/app
ENV HOME=/home/nonroot

# Pre-create cache directory so uv can write to it
RUN mkdir -p /home/nonroot/.cache/uv

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv
RUN --mount=type=cache,target=/home/nonroot/.cache/uv \
    uv sync --locked --no-install-project

# Copy project code
COPY --chown=999:999 . .

# Install project
RUN --mount=type=cache,target=/home/nonroot/.cache/uv \
    uv sync --locked

# Run the app
CMD ["uv", "run", "main.py"]