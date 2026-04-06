FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

WORKDIR /home/nonroot/app
ENV HOME=/home/nonroot

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv **as root**
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

# Copy project code
COPY . .

# Install project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Switch to non-root user to run
USER nonroot

CMD ["uv", "run", "main.py"]