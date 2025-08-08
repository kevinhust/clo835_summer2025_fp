# Use Python 3.9 slim image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    pkg-config \
    default-libmysqlclient-dev \
    default-mysql-client \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt /tmp/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt

# Copy application code
COPY --chown=appuser:appuser . /app

# Create static directory for S3 downloads
RUN mkdir -p /app/static && chown -R appuser:appuser /app/static

# Keep root user for now to avoid permission issues
# USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import requests; requests.get('http://localhost:81/about', timeout=5)" || exit 1

# Expose port
EXPOSE 81

# Run application
ENTRYPOINT ["python3"]
CMD ["app.py"]