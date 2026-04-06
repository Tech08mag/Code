FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

WORKDIR /app

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

# Copy project code
COPY --chown=999:999 . .

# Install project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Use non-root user
USER nonroot

# Run the app using UV-managed Python
CMD ["uv", "run", "main.py"]