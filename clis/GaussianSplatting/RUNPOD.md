# RunPod Hub Deployment Guide

## Overview

```
You push to GitHub → Add repo to RunPod Hub → Users deploy with one click
```

## Project Structure (RunPod Hub required files)

| File | Purpose |
|------|---------|
| `hub.json` | Metadata, GPU config, env vars, presets |
| `tests.json` | Test cases RunPod runs to validate your image |
| `handler.py` | Serverless handler — receives API jobs |
| `docker/Dockerfile` | Builds the container image |
| `README.md` | Displayed on the Hub listing |

## Step-by-Step

### 1. Push to GitHub

```sh
git add .
git commit -m "Add Gaussian Splatting Docker pipeline"
git push origin main
```

### 2. Publish to RunPod Hub

1. Go to [RunPod Console → Hub](https://www.console.runpod.io/hub)
2. Click **"Get Started"** under "Add your repo"
3. Enter your GitHub repo URL
4. Follow the UI steps — RunPod will find your `hub.json` and `tests.json`
5. **Create a GitHub Release** (the Hub indexes releases, not commits)

### 3. Using the Endpoint

Once published, users deploy your endpoint from the Hub. Send jobs via the RunPod API:

```sh
curl -X POST "https://api.runpod.ai/v2/<your-endpoint>/runsync" \
  -H "Authorization: Bearer <RUNPOD_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "url": "https://example.com/360-video.mp4",
      "fps": 3,
      "stage": "brush"
    }
  }'
```

**Response:**
```json
{
  "status": "complete",
  "stage": "brush",
  "frame_count": 42,
  "exports": ["export_5000.ply", "export_10000.ply", "export_30000.ply"],
  "output_path": "/workspace/output/exports/"
}
```

### 4. Update Your Repo

When you push changes and create a new GitHub Release, RunPod Hub automatically re-indexes it.

## Local Testing

```sh
# Build the image
make docker-build

# Test extract + colmap stages (no GPU needed, works on Mac)
make docker-test URL=https://example.com/360.mp4

# Full pipeline (needs GPU)
make docker-run URL=https://example.com/360.mp4
```

## Configuration (set via RunPod Hub UI or API)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `FPS` | number | 3 | Frames per second to extract |
| `STAGE` | option | brush | extract, colmap, or brush |
