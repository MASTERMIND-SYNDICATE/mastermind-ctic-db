FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY misp_pull.py wazuh_sightings.py ./
USER 65532
ENTRYPOINT ["bash","-lc","python misp_pull.py && python wazuh_sightings.py"]
