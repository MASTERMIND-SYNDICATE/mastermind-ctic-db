FROM python:3.11-alpine

# Set up repo workspace
WORKDIR /workspace

# Install system dependencies for psycopg2
RUN apk add --no-cache build-base libpq python3-dev

# Install Python requirements
COPY etl/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# (Optional) Copy etl scripts if you need scripts inside the built container
# COPY etl/ /workspace/etl/

# Default: Keep container alive for docker compose exec
ENTRYPOINT ["sleep", "infinity"]
