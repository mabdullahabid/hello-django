# Use Python 3.12 slim image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE="hello_django.settings"

# Set work directory
WORKDIR /app

# Install system dependencies and uv
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        gettext \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH (uv installs to /root/.local/bin)
ENV PATH="/root/.local/bin:$PATH"

# Copy dependency files and clean them for production
COPY pyproject.toml uv.lock /app/

# Remove local development dependencies for production build
RUN sed -i '/^\[tool\.uv\.sources\]/,/^$/d' pyproject.toml

# Install Python dependencies using uv
RUN uv sync --frozen --no-dev

# Copy project
COPY . /app/

# Create staticfiles directory
RUN mkdir -p /app/staticfiles

# Collect static files
RUN uv run python manage.py collectstatic --noinput

# Create volume for SQLite database (if using SQLite)
RUN mkdir -p /app/data
VOLUME ["/app/data"]

# Expose port
EXPOSE 8000

# Health check using curl (more reliable than requests)
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/django-coolify/health/ || exit 1

# Start server
CMD ["uv", "run", "python", "manage.py", "runserver", "0.0.0.0:8000"]
