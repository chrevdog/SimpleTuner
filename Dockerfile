# syntax=docker/dockerfile:1.4

FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    POETRY_REQUESTS_TIMEOUT=300 \
    PATH="/root/.local/bin:$PATH"

WORKDIR /workspace

# Install system dependencies, pip tools, jupyterlab, poetry, and git-lfs
RUN apt-get update && \
    apt-get install -y \
        git \
        git-lfs \
        curl \
        dos2unix \
        ffmpeg \
        libgl1-mesa-glx \
        libglib2.0-0 \
        unzip \
        openssh-server && \
    git lfs install && \
    pip install --upgrade pip && \
    pip install --no-cache-dir --retries 10 --timeout 60 poetry jupyterlab ipykernel lycoris-lora optimum-quanto && \
    rm -rf /var/lib/apt/lists/*

# Copy SimpleTuner source code into image
COPY SimpleTuner /workspace/simpletuner

# Copy Training_Configs into SimpleTuner directory
COPY Training_Configs /workspace/simpletuner/Training_Configs

WORKDIR /workspace/simpletuner

# Install SimpleTuner dependencies with poetry (no virtualenv)
RUN poetry install --no-root --no-interaction --no-ansi

# Register ipykernel so Jupyter can find kernel
RUN python3 -m ipykernel install --sys-prefix

# Configure Jupyter: allow CORS, remote access, and disable XSRF/token
RUN mkdir -p /root/.jupyter && \
    echo "c.ServerApp.token = ''" >> /root/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /root/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.disable_check_xsrf = True" >> /root/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /root/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /root/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_credentials = True" >> /root/.jupyter/jupyter_server_config.py

# Copy and prepare entrypoint/start script
COPY start.sh /workspace/start.sh
RUN dos2unix /workspace/start.sh && chmod +x /workspace/start.sh

# Expose Jupyter and SSH ports
EXPOSE 8888 22

# Entrypoint to run start.sh script
ENTRYPOINT ["/workspace/start.sh"]

# Default command to launch JupyterLab (overridable by start.sh)
CMD ["jupyter", "lab", \
    "--ip=0.0.0.0", \
    "--port=8888", \
    "--no-browser", \
    "--allow-root", \
    "--NotebookApp.notebook_dir=/workspace/simpletuner", \
    "--NotebookApp.default_url=/lab/tree/"]
