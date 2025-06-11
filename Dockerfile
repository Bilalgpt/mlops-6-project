# Use Python 3.9 slim for smaller image size
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies needed for some Python packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and setup files first for better Docker layer caching
COPY requirements.txt setup.py pyproject.toml ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . /app

# Install the application in development mode
RUN pip install --no-cache-dir -e .

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Set environment variables (fixed syntax - no spaces around =)
ENV FLASK_APP=application.py
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port 5000 (keeping your original port)
EXPOSE 5000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Run the application
CMD ["python", "application.py"]