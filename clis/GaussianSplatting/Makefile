.PHONY: setup extract colmap brush docker-build docker-run

# ── Local (macOS) targets ────────────────────────────────────────────────────

setup:
	@echo "Installing dependencies..."
	pip3 install Pillow scipy sharp-frames pycolmap --user || python3 -m pip install Pillow scipy sharp-frames pycolmap --user || true
	brew install ffmpeg xz pyenv || true
	mkdir -p ~/.local/bin
	curl -sL https://github.com/ArthurBrussee/brush/releases/download/v0.3.0/brush-app-aarch64-apple-darwin.tar.xz | tar xJf -
	mv brush-app-aarch64-apple-darwin/brush_app ~/.local/bin/brush
	rm -rf brush-app-aarch64-apple-darwin

extract:
	@echo "Running Extract.sh on 360.mp4..."
	PATH="$$(python3 -m site --user-base)/bin:$$PATH" ./Exctract.sh --scenedir ~/Desktop/Project --fps 3 ../360.mp4

colmap:
	@echo "Running A1PyColmap.py..."
	PATH="$$(python3 -m site --user-base)/bin:$$PATH" ./A1PyColmap.py --scenedir ~/Desktop/Project

brush:
	@echo "Running Brush.sh..."
	PATH="$$(python3 -m site --user-base)/bin:$${HOME}/.local/bin:$$PATH" ./Brush.sh --scenedir ~/Desktop/Project

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

# Run extract + colmap only (no GPU needed, works on Mac)
docker-test:
ifndef URL
	$(error URL is required. Usage: make docker-test URL=https://example.com/360.mp4)
endif
	mkdir -p $(OUTPUT_DIR)
	docker run --rm \
		-v $(OUTPUT_DIR):/workspace/output \
		$(IMAGE_NAME) \
		/opt/gaussian-splatting/entrypoint.sh --fps $(FPS) --stage colmap $(URL)
