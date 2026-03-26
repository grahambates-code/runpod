# Gaussian Splatting Pipeline (RunPod Hub Serverless)
# Runs: Extract (ffmpeg+sharp-frames) → COLMAP (pycolmap) → Brush (Gaussian splatting)
#
# Build:     docker build -t gaussian-splatting -f docker/Dockerfile .
# Serverless: Starts automatically via RunPod Hub (handler.py)
# Standalone: docker run --gpus all gaussian-splatting /opt/gaussian-splatting/entrypoint.sh https://example.com/360.mp4
#
FROM --platform=linux/amd64 nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-dev \
        ffmpeg \
        curl \
        xz-utils \
        zip \
        libgl1-mesa-glx libglib2.0-0 \
        libvulkan1 mesa-vulkan-drivers vulkan-tools \
    && rm -rf /var/lib/apt/lists/*

# ── Python dependencies ─────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir \
        Pillow \
        scipy \
        sharp-frames \
        pycolmap \
        opencv-python-headless \
        tqdm \
        runpod

# ── Brush binary (Linux x86_64) ─────────────────────────────────────────────
RUN curl -sL https://github.com/ArthurBrussee/brush/releases/download/v0.3.0/brush-app-x86_64-unknown-linux-gnu.tar.xz \
    | tar xJf - \
    && mv brush-app-x86_64-unknown-linux-gnu/brush_app /usr/local/bin/brush \
    && chmod +x /usr/local/bin/brush \
    && rm -rf brush-app-x86_64-unknown-linux-gnu

# ── Pipeline scripts ────────────────────────────────────────────────────────
COPY scripts/ /opt/gaussian-splatting/scripts/
RUN chmod +x /opt/gaussian-splatting/scripts/*

COPY docker/entrypoint.sh /opt/gaussian-splatting/entrypoint.sh
RUN chmod +x /opt/gaussian-splatting/entrypoint.sh

# ── RunPod serverless handler ────────────────────────────────────────────────
COPY handler.py /opt/gaussian-splatting/handler.py

# ── Workspace ────────────────────────────────────────────────────────────────
WORKDIR /workspace
RUN mkdir -p /workspace/output

# RunPod serverless mode (default)
CMD ["python3", "/opt/gaussian-splatting/handler.py"]
