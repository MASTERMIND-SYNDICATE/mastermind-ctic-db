FROM python:3.11-alpine

WORKDIR /workspace

RUN apk add --no-cache build-base libpq python3-dev

COPY etl/requirements.txt /tmp/requirements.txt

# Upgrade pip BEFORE installing requirements
RUN pip install --upgrade pip && pip install --no-cache-dir -r /tmp/requirements.txt

# Optional: Copy etl scripts if needed
# COPY etl/ /workspace/etl/

ENTRYPOINT ["sleep", "infinity"]
