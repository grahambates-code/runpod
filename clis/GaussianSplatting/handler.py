"""
RunPod Serverless Handler for Gaussian Splatting Pipeline.

Receives a job with a video URL, downloads it, and runs the
Extract → COLMAP → Brush pipeline.

Input:
    {
        "url": "https://example.com/360-video.mp4",
        "fps": 3,           # optional, default: 3
        "stage": "brush"    # optional: "extract", "colmap", or "brush"
    }

Output:
    {
        "status": "complete",
        "stage": "brush",
        "frame_count": 42,
        "exports": ["export_5000.ply", "export_10000.ply", ...],
        "output_path": "/workspace/output/exports/"
    }
"""

import os
import glob
import subprocess

import runpod


SCRIPTS_DIR = "/opt/gaussian-splatting/scripts"
SCENE_DIR = "/workspace/output"


def run_step(cmd: list[str], step_name: str) -> None:
    """Run a subprocess and raise on failure."""
    print(f"[{step_name}] Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(result.stderr)
        raise RuntimeError(f"[{step_name}] Failed (exit {result.returncode}): {result.stderr[-500:]}")


def handler(job):
    """Process a Gaussian Splatting job."""
    job_input = job["input"]

    url = job_input.get("url")
    if not url:
        return {"error": "Missing required field: url"}

    fps = str(job_input.get("fps", os.environ.get("FPS", "3")))
    stage = job_input.get("stage", os.environ.get("STAGE", "brush"))

    if stage not in ("extract", "colmap", "brush"):
        return {"error": f"Invalid stage '{stage}'. Use: extract, colmap, or brush."}

    scene_dir = SCENE_DIR
    video_file = "/workspace/input_video.mp4"

    os.makedirs(scene_dir, exist_ok=True)

    # ── Download ─────────────────────────────────────────────────────────
    print(f"Downloading video from {url}...")
    run_step(["curl", "-fSL", "-o", video_file, url], "Download")
    print(f"Download complete.")

    # ── Stage 1: Extract ─────────────────────────────────────────────────
    print("Stage 1/3: Extracting sharp frames...")
    run_step(
        [f"{SCRIPTS_DIR}/extract.sh", "--scenedir", scene_dir, "--fps", fps, video_file],
        "Extract",
    )

    frame_count = len(glob.glob(f"{scene_dir}/frames/*"))
    print(f"Extracted {frame_count} frames.")

    if stage == "extract":
        return {
            "status": "complete",
            "stage": "extract",
            "frame_count": frame_count,
        }

    # ── Stage 2: COLMAP ──────────────────────────────────────────────────
    print("Stage 2/3: Running COLMAP reconstruction...")
    run_step(
        [f"{SCRIPTS_DIR}/colmap.py", "--scenedir", scene_dir],
        "COLMAP",
    )

    if stage == "colmap":
        return {
            "status": "complete",
            "stage": "colmap",
            "frame_count": frame_count,
        }

    # ── Stage 3: Brush ───────────────────────────────────────────────────
    print("Stage 3/3: Running Brush Gaussian Splatting training...")
    run_step(
        [f"{SCRIPTS_DIR}/brush.sh", "--scenedir", scene_dir],
        "Brush",
    )

    # Collect export filenames
    exports = sorted(
        os.path.basename(f) for f in glob.glob(f"{scene_dir}/exports/*.ply")
    )

    return {
        "status": "complete",
        "stage": "brush",
        "frame_count": frame_count,
        "exports": exports,
        "output_path": f"{scene_dir}/exports/",
    }


runpod.serverless.start({"handler": handler})
