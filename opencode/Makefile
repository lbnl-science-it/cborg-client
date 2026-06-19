BUILD_DIR = ./build-opencode

.PHONY: all check-bun build install clean build-check

all: build

check-bun:
	@if ! command -v bun >/dev/null 2>&1; then \
		echo "bun tooling is not installed. Installing..."; \
		OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
		if [ "$$OS" = "darwin" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install oven-sh/bun/bun; \
			else \
				curl -fsSL https://bun.sh/install | bash; \
				export PATH="$$HOME/.bun/bin:$$PATH"; \
			fi; \
		elif [ "$$OS" = "linux" ] || echo "$$OS" | grep -q "mingw\|msys\|cygwin"; then \
			if command -v apt-get >/dev/null 2>&1; then \
				sudo apt-get update && sudo apt-get install -y unzip curl; \
			fi; \
			curl -fsSL https://bun.sh/install | bash; \
			export PATH="$$HOME/.bun/bin:$$PATH"; \
		else \
			echo "Unsupported OS for automatic bun installation: $$OS. Please install bun manually."; \
			exit 1; \
		fi; \
	fi
	@echo "Checking bun version (requires >= 1.3.14)..."
	@bun upgrade

FORK_URL = https://github.com/awschmeder/opencode.git

build: check-bun
	@echo "Cloning opencode..."
	@if [ ! -d $(BUILD_DIR) ]; then \
		git clone https://github.com/anomalyco/opencode.git $(BUILD_DIR); \
	fi
	@echo "Fetching upstream PR #14468 (balcsida LiteLLM provider)..."
	@cd $(BUILD_DIR) && git fetch origin pull/14468/head:_pr14468_head && git checkout --detach _pr14468_head
	@echo "Applying cborg patches from $(FORK_URL)..."
	@cd $(BUILD_DIR) && \
	BACKFILL_SHA=$$(git ls-remote $(FORK_URL) litellm-backfill-discovered-cost | cut -f1) && \
	CACHEWRITE_SHA=$$(git ls-remote $(FORK_URL) litellm-cache-write-tokens | cut -f1) && \
	if [ -z "$$BACKFILL_SHA" ] || [ -z "$$CACHEWRITE_SHA" ]; then \
		echo "ERROR: could not resolve patch branch SHAs from $(FORK_URL)" >&2; exit 1; \
	fi && \
	git fetch $(FORK_URL) litellm-backfill-discovered-cost litellm-cache-write-tokens && \
	echo "Cherry-picking cost/limit backfill: $$BACKFILL_SHA" && \
	git cherry-pick $$BACKFILL_SHA && \
	echo "Cherry-picking cache-write token extraction: $$CACHEWRITE_SHA" && \
	git cherry-pick $$CACHEWRITE_SHA
	@echo "Installing dependencies..."
	@export PATH="$$HOME/.bun/bin:$$PATH"; \
	cd $(BUILD_DIR) && bun install
	@echo "Auditing dependencies (advisory-only)..."
	@export PATH="$$HOME/.bun/bin:$$PATH"; \
	cd $(BUILD_DIR) && bun audit --level critical || true
	@echo "Building opencode (current platform)..."
	@export PATH="$$HOME/.bun/bin:$$PATH"; \
	cd $(BUILD_DIR)/packages/opencode && bun run build --single
	@echo "Detecting OS and Architecture..."
	@OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	case "$$OS" in \
		darwin) OPENCODE_OS="macos" ;; \
		linux) OPENCODE_OS="linux" ;; \
		*) echo "Unsupported OS: $$OS" && exit 1 ;; \
	esac; \
	case "$$ARCH" in \
		x86_64) OPENCODE_ARCH="x64" ;; \
		aarch64|arm64) OPENCODE_ARCH="arm64" ;; \
		*) echo "Unsupported architecture: $$ARCH" && exit 1 ;; \
	esac; \
	BINARY_PATH="$(BUILD_DIR)/packages/opencode/dist/opencode-$${OPENCODE_OS}-$${OPENCODE_ARCH}/bin/opencode"; \
	if [ -f "$$BINARY_PATH" ]; then \
		cp "$$BINARY_PATH" ./opencode; \
	else \
		echo "Expected binary not found at $$BINARY_PATH. Searching dist/ directory..."; \
		FOUND_PATH=$$(find $(BUILD_DIR)/packages/opencode/dist -type f -name opencode | head -n 1); \
		if [ -n "$$FOUND_PATH" ]; then \
			cp "$$FOUND_PATH" ./opencode; \
		else \
			echo "Error: opencode binary not found anywhere in dist/" && exit 1; \
		fi; \
	fi
	@chmod +x ./opencode
	@echo "Build successful! Binary is located at './opencode'."

build-check:
	@if [ ! -f opencode ]; then \
		echo "Binary 'opencode' not found. Please run 'make build' first."; \
		exit 1; \
	fi

install: build-check
	@echo "Installing binary to /usr/local/bin/opencode..."
	sudo install -m 755 opencode /usr/local/bin/opencode
	@echo "Checking configuration file..."
	@if [ -f "$$HOME/.config/opencode/opencode.json" ]; then \
		echo "File ~/.config/opencode/opencode.json already exists."; \
		echo -n "Do you want to overwrite it with the default cborg-compatible config? [y/N]: "; \
		read answer; \
		if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
			cp opencode.json "$$HOME/.config/opencode/opencode.json" && echo "Configuration overwritten."; \
		else \
			echo "Keeping existing configuration."; \
		fi; \
	else \
		echo -n "Do you want to install the default cborg-compatible config.json to ~/.config/opencode/opencode.json? [y/N]: "; \
		read answer; \
		if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
			mkdir -p "$$HOME/.config/opencode" && \
			cp opencode.json "$$HOME/.config/opencode/opencode.json" && \
			echo "Configuration installed."; \
		else \
			echo "Skipping configuration install."; \
		fi; \
	fi
	@echo "Installation complete!"

clean:
	rm -rf $(BUILD_DIR)
	rm -f ./opencode
