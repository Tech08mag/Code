# Use a Python image with full standard library
FROM python:3.13-bookworm

# Set working directory
WORKDIR /app

# Create a non-root user
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

# Copy dependency lockfiles first for caching
COPY pyproject.toml uv.lock* ./

# Create a virtual environment (includes system site packages to avoid missing stdlib)
RUN python -m venv /app/.venv \
    && /app/.venv/bin/pip install --upgrade pip setuptools wheel

# Install project dependencies using uv into the virtual environment
ENV PATH="/app/.venv/bin:$PATH"
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

# Copy the rest of the project into /app
COPY --chown=999:999 . .

# Install the project itself in editable mode
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Set environment to use our venv
ENV PATH="/app/.venv/bin:$PATH"

# Switch to non-root user
USER nonroot

# Run the app
CMD ["python", "main.py"]