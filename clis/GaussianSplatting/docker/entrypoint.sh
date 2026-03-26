#!/usr/bin/env bash
# Gaussian Splatting Pipeline Entrypoint
#
# Usage:
#   entrypoint.sh [OPTIONS] <video_url>
#
# Options:
#   --fps <rate>       Frames per second to extract (default: 3)
#   --stage <stage>    Stop after stage: extract, colmap, or brush (default: brush)
#   --scenedir <path>  Override the output directory (default: /workspace/output)
#   -h, --help         Show this help message

set -euo pipefail

SCRIPTS_DIR="/opt/gaussian-splatting/scripts"

# ── Defaults (env vars → CLI args override) ──────────────────────────────────
FPS="${FPS:-3}"
STAGE="${STAGE:-brush}"
SCENE_DIR="${SCENE_DIR:-/workspace/output}"
VIDEO_URL="${VIDEO_URL:-}"

# ── Help ─────────────────────────────────────────────────────────────────────
usage() {
	echo "Usage: entrypoint.sh [OPTIONS] <video_url>"
	echo ""
	echo "Downloads a video from a URL and runs the Gaussian Splatting pipeline."
	echo ""
	echo "Options:"
	echo "  --fps <rate>       Frames per second to extract (default: 3)"
	echo "  --stage <stage>    Stop after stage: extract, colmap, or brush (default: brush)"
	echo "  --scenedir <path>  Override the output directory (default: /workspace/output)"
	echo "  -h, --help         Show this help message"
	exit 0
}

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|--help)
			usage ;;
		--fps)
			[[ -z "${2:-}" ]] && { echo "Error: --fps requires a value." >&2; exit 1; }
			FPS="$2"; shift 2 ;;
		--stage)
			[[ -z "${2:-}" ]] && { echo "Error: --stage requires a value." >&2; exit 1; }
			STAGE="$2"; shift 2 ;;
		--scenedir)
			[[ -z "${2:-}" ]] && { echo "Error: --scenedir requires a value." >&2; exit 1; }
			SCENE_DIR="$2"; shift 2 ;;
		-*)
			echo "Error: Unknown option '$1'" >&2; exit 1 ;;
		*)
			VIDEO_URL="$1"; shift ;;
	esac
done

if [[ -z "${VIDEO_URL}" ]]; then
	echo "Error: No video URL specified." >&2
	usage
fi

# Validate stage
case "${STAGE}" in
	extract|colmap|brush) ;;
	*) echo "Error: Invalid stage '${STAGE}'. Use: extract, colmap, or brush." >&2; exit 1 ;;
esac

# ── Download ─────────────────────────────────────────────────────────────────
echo "================================================"
echo "  Gaussian Splatting Pipeline"
echo "================================================"
echo "  URL    : ${VIDEO_URL}"
echo "  FPS    : ${FPS}"
echo "  Stage  : ${STAGE}"
echo "  Output : ${SCENE_DIR}"
echo "================================================"
echo ""

VIDEO_FILE="/workspace/input_video.mp4"

echo "Downloading video..."
curl -fSL --progress-bar -o "${VIDEO_FILE}" "${VIDEO_URL}"
echo "Download complete: $(du -h "${VIDEO_FILE}" | cut -f1)"
echo ""

# ── Stage 1: Extract ─────────────────────────────────────────────────────────
echo "================================================"
echo "  Stage 1/3: Extract sharp frames"
echo "================================================"
"${SCRIPTS_DIR}/extract.sh" --scenedir "${SCENE_DIR}" --fps "${FPS}" "${VIDEO_FILE}"

FRAME_COUNT=$(find "${SCENE_DIR}/frames" -type f | wc -l)
echo "Extracted ${FRAME_COUNT} frames."
echo ""

[[ "${STAGE}" == "extract" ]] && { echo "Done (stopped after extract stage)."; exit 0; }

# ── Stage 2: COLMAP ──────────────────────────────────────────────────────────
echo "================================================"
echo "  Stage 2/3: COLMAP reconstruction"
echo "================================================"
"${SCRIPTS_DIR}/colmap.py" --scenedir "${SCENE_DIR}"
echo ""

[[ "${STAGE}" == "colmap" ]] && { echo "Done (stopped after colmap stage)."; exit 0; }

# ── Stage 3: Brush ───────────────────────────────────────────────────────────
echo "================================================"
echo "  Stage 3/3: Brush Gaussian Splatting training"
echo "================================================"
"${SCRIPTS_DIR}/brush.sh" --scenedir "${SCENE_DIR}"
echo ""

# ── Complete ─────────────────────────────────────────────────────────────────
echo "================================================"
echo "  Pipeline complete!"
echo "================================================"
echo "  Exports: ${SCENE_DIR}/exports/"
ls -lh "${SCENE_DIR}/exports/" 2>/dev/null || echo "  (no exports found)"
echo "================================================"
