FROM python:3.11-alpine

# runtime workspace where the repo will be mounted by Compose
WORKDIR /workspace

# install deps (copy only requirements into the image)
COPY etl/requirements.txt /tmp/requirements.txt
RUN apk add --no-cache build-base libpq \
 && pip install --no-cache-dir -r /tmp/requirements.txt

# keep container alive; we will exec scripts with docker compose exec
ENTRYPOINT ["sleep","infinity"]
