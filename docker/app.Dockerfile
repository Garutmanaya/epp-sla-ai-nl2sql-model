# =====================================
# STAGE 1: BUILDER
# =====================================
FROM python:3.12-slim AS builder

WORKDIR /app

# System deps (build only)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

#RUN uv sync --frozen

# Install dependencies globally (NO .venv)
RUN uv pip install --system --no-cache -r pyproject.toml
# Install CPU-only torch (IMPORTANT: after uv sync)
#RUN uv pip install --system torch --index-url https://download.pytorch.org/whl/cpu
#RUN uv pip install \
#    --system \
#    --index-url https://download.pytorch.org/whl/cpu \
#    -r pyproject.toml

# =====================================
# STAGE 2: RUNTIME
# =====================================
FROM python:3.12-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local /usr/local

# Copy app code
COPY src ./src
COPY config ./config
RUN mkdir -p /app/hub && chmod -R 777 /app/hub
# Migrate to S3
#COPY hub/artifacts/  ./hub/artifacts
# Need pyproject.toml to identify the root
COPY pyproject.toml uv.lock ./

ENV PYTHONPATH=/app/src

# Reduce Python overhead
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

COPY docker/serve /usr/local/bin/serve
RUN chmod +x /usr/local/bin/serve
ENV PATH="/usr/local/bin:${PATH}"

ENTRYPOINT ["serve"]

# Start API
#CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8080"] 


#================================================================================
#docker build -f docker/app.Dockerfile -t epp-sla-ai-nl2sql-model .
# run 
#docker run -it  -p 8000:8000 epp-sla-anomaly-detection-multimodel:latest
#=====================================================================================
