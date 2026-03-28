.PHONY: setup extract colmap brush docker-build docker-run

# ── OS and Architecture Detection ───────────────────────────────────────────
OS := $(shell uname -s)
ARCH := $(shell uname -m)

# Define the Brush version
BRUSH_VERSION := v0.3.0
LOCAL_BIN := $(HOME)/.local/bin

# ── Setup Target (Cross-Platform) ───────────────────────────────────────────

setup:
	@echo "Detected OS: $(OS), Architecture: $(ARCH)"
	@echo "Installing Python dependencies..."
	pip3 install Pillow scipy sharp-frames pycolmap --user || python3 -m pip install Pillow scipy sharp-frames pycolmap --user || true
	
	@if [ "$(OS)" = "Darwin" ]; then \
		echo "Installing macOS system dependencies via Homebrew..."; \
		brew install ffmpeg xz pyenv || true; \
		BRUSH_URL="https://github.com/ArthurBrussee/brush/releases/download/$(BRUSH_VERSION)/brush-app-aarch64-apple-darwin.tar.xz"; \
		BRUSH_DIR="brush-app-aarch64-apple-darwin"; \
	elif [ "$(OS)" = "Linux" ]; then \
		echo "Installing Linux system dependencies via apt-get..."; \
		apt-get update && apt-get install -y ffmpeg xz-utils curl python3-pip || true; \
		BRUSH_URL="https://github.com/ArthurBrussee/brush/releases/download/$(BRUSH_VERSION)/brush-app-x86_64-unknown-linux-gnu.tar.xz"; \
		BRUSH_DIR="brush-app-x86_64-unknown-linux-gnu"; \
	fi; \
	\
	echo "Downloading and installing Brush from: $$BRUSH_URL"; \
	mkdir -p $(LOCAL_BIN); \
	curl -sL $$BRUSH_URL | tar xJf -; \
	mv $$BRUSH_DIR/brush_app $(LOCAL_BIN)/brush; \
	rm -rf $$BRUSH_DIR; \
	echo "Setup complete. Ensure $(LOCAL_BIN) is in your PATH."

# ── Script Execution Targets ────────────────────────────────────────────────

# Dynamic PATH construction to include local python bins and the brush bin
ENV_PATH := PATH="$$(python3 -m site --user-base)/bin:$(LOCAL_BIN):$$PATH"

extract:
	@echo "Running Extract.sh..."
	$(ENV_PATH) ./Exctract.sh --scenedir ~/Desktop/Project --fps 3 ../360.mp4

colmap:
	@echo "Running A1PyColmap.py..."
	$(ENV_PATH) ./A1PyColmap.py --scenedir ~/Desktop/Project

brush:
	@echo "Running Brush.sh..."
	$(ENV_PATH) ./Brush.sh --scenedir ~/Desktop/Project

# ── Docker targets ───────────────────────────────────────────────────────────

IMAGE_NAME ?= gaussian-splatting
FPS        ?= 3
STAGE      ?= brush
OUTPUT_DIR ?= $(PWD)/output

docker-build:
	docker build -t $(IMAGE_NAME) -f docker/Dockerfile .

docker-run:
ifndef URL
	$(error URL is required. Usage: make docker-run URL=https://example.com/360.mp4)
endif
	mkdir -p $(OUTPUT_DIR)
	docker run --rm \
		--gpus all \
		-v $(OUTPUT_DIR):/workspace/output \
		$(IMAGE_NAME) \
		/opt/gaussian-splatting/entrypoint.sh --fps $(FPS) --stage $(STAGE) $(URL)

docker-test:
ifndef URL
	$(error URL is required. Usage: make docker-test URL=https://example.com/360.mp4)
endif
	mkdir -p $(OUTPUT_DIR)
	docker run --rm \
		-v $(OUTPUT_DIR):/workspace/output \
		$(IMAGE_NAME) \
		/opt/gaussian-splatting/entrypoint.sh --fps $(FPS) --stage colmap $(URL)