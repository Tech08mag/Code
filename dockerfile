# Base Python image with full stdlib
FROM python:3.13-bookworm

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Create virtual environment including system site packages (optional)
RUN python -m venv /app/.venv \
    && /app/.venv/bin/pip install --upgrade pip setuptools wheel

# Install dependencies inside the venv
RUN /app/.venv/bin/pip install "flask>=3.1.3" "flask-cors>=6.0.2" "spotiflac>=0.2.8"

# Copy the rest of the project
COPY . .

# Set PATH so the venv is used
ENV PATH="/app/.venv/bin:$PATH"

# Use non-root user
RUN useradd -m nonroot
USER nonroot

# Run your app
CMD ["python", "main.py"]