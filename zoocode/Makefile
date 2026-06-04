SHELL := /bin/bash
DIR   := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
OUT     := $(DIR)zoo-code-settings.json
MCP_OUT := $(DIR)mcp_settings.json

.PHONY: all clean $(OUT) $(MCP_OUT)

# Build zoo-code-settings.json by merging provider configs into base.json.
# Providers are included only when their API key env var is set:
#   CBORG_API_KEY    -> providers/cborg.json  (CBorg / LBL)  [required]
#   AMSC_I2_API_KEY  -> providers/amsc.json   (AmSC / American Science Cloud)  [optional]
all: $(OUT) $(MCP_OUT)

$(OUT):
	@echo "Building $(OUT)..."
	@if [ -z "$$CBORG_API_KEY" ]; then \
		echo ""; \
		echo "ERROR: CBORG_API_KEY is not set. Export your CBorg API key and try again:"; \
		echo "  export CBORG_API_KEY=<your-key>"; \
		echo ""; \
		exit 1; \
	fi; \
	idx_enabled=false; \
	if command -v podman >/dev/null 2>&1; then \
		read -r -p "  ? Enable codebase indexing? [y/N] " idx_ans; \
		case "$$idx_ans" in \
			[Yy]*) idx_enabled=true;  echo "  + Codebase indexing enabled"  ;; \
			*)     idx_enabled=false; echo "  - Codebase indexing disabled" ;; \
		esac; \
	else \
		echo "  - Skipping indexing (podman not installed)"; \
	fi; \
	configs='{}'; \
	echo "  + Including CBorg providers"; \
	cborg=$$(CBORG_API_KEY="$$CBORG_API_KEY" envsubst '$$CBORG_API_KEY' < $(DIR)providers/cborg.json); \
	configs=$$(echo "$$configs" | jq --argjson p "$$cborg" '. * $$p'); \
	if [ -n "$$AMSC_I2_API_KEY" ]; then \
		echo "  + Including AmSC providers"; \
		amsc=$$(AMSC_I2_API_KEY="$$AMSC_I2_API_KEY" envsubst '$$AMSC_I2_API_KEY' < $(DIR)providers/amsc.json); \
		configs=$$(echo "$$configs" | jq --argjson p "$$amsc" '. * $$p'); \
	else \
		echo "  - Skipping AmSC providers (AMSC_I2_API_KEY not set)"; \
	fi; \
	gcp_json=""; \
	gcp_source=""; \
	gcp_default="y/N"; \
	gcp_path="$$GOOGLE_APPLICATION_CREDENTIALS"; \
	if [ -f "$$HOME/.zoo/application_default_credentials.json" ]; then \
		gcp_source="~/.zoo/application_default_credentials.json"; \
		gcp_default="Y/n"; \
		gcp_json=$$(cat "$$HOME/.zoo/application_default_credentials.json"); \
	elif [ -f "$$HOME/.roo/application_default_credentials.json" ]; then \
		gcp_source="~/.roo/application_default_credentials.json"; \
		gcp_default="Y/n"; \
		gcp_json=$$(cat "$$HOME/.roo/application_default_credentials.json"); \
	elif [ -n "$$gcp_path" ]; then \
		if [[ "$$gcp_path" != "{"* ]]; then \
			case "$$gcp_path" in \
				"~"*) gcp_path="$$HOME$${gcp_path:1}" ;; \
				/*) ;; \
				*) gcp_path="$$PWD/$$gcp_path" ;; \
			esac; \
		fi; \
		if [ -f "$$gcp_path" ]; then \
			gcp_source="$$gcp_path"; \
			gcp_json=$$(cat "$$gcp_path"); \
		else \
			gcp_source="env(GOOGLE_APPLICATION_CREDENTIALS)"; \
			gcp_json="$$gcp_path"; \
		fi; \
	elif [ -f "$$HOME/.gcloud/application_default_credentials.json" ]; then \
		gcp_source="~/.gcloud/application_default_credentials.json"; \
		gcp_json=$$(cat "$$HOME/.gcloud/application_default_credentials.json"); \
	fi; \
	if [ -n "$$gcp_json" ] && echo "$$gcp_json" | jq -e . >/dev/null 2>&1; then \
		project_id=$$(echo "$$gcp_json" | jq -r '.project_id // empty'); \
		if [ -n "$$project_id" ]; then \
			echo "  + Found GCP credentials in $$gcp_source"; \
			read -r -p "  ? Include GCP providers for project '$$project_id'? [$$gcp_default] " gcp_ans; \
			gcp_ans=$${gcp_ans:-$${gcp_default%%/*}}; \
			case "$$gcp_ans" in \
				[Yy]*) \
					read -r -p "    ? Vertex AI region? [global] " gcp_region; \
					gcp_region=$${gcp_region:-global}; \
					echo "  + Including GCP providers (project: $$project_id, region: $$gcp_region)"; \
					export GCP_PROJECT_ID="$$project_id"; \
					export GCP_REGION="$$gcp_region"; \
					export GCP_JSON_CREDENTIALS=$$(echo "$$gcp_json" | jq -c . | jq -R . | sed 's/^"//;s/"$$//'); \
					gcp=$$(envsubst '$$GCP_PROJECT_ID $$GCP_REGION $$GCP_JSON_CREDENTIALS' < $(DIR)providers/gcp.json); \
					configs=$$(echo "$$configs" | jq --argjson p "$$gcp" '. * $$p'); \
					;; \
				*) echo "  - Skipping GCP providers"; ;; \
			esac; \
		else \
			echo "  - Skipping GCP providers (no project_id in JSON)"; \
		fi; \
	else \
		echo "  - Skipping GCP providers (no credentials found or invalid JSON)"; \
	fi; \
	jq --argjson configs "$$configs" --argjson idx "$$idx_enabled" --arg home "$$HOME" \
		'.providerProfiles.apiConfigs = $$configs | .globalSettings.codebaseIndexConfig.codebaseIndexEnabled = $$idx | .globalSettings.lastSettingsExportPath |= sub("^~"; $$home)' \
		$(DIR)base.json > $(OUT)
	@echo "Done -> $(OUT)"

$(MCP_OUT):
	@echo "Building $(MCP_OUT)..."
	@if [ -z "$$CBORG_API_KEY" ]; then \
		echo ""; \
		echo "ERROR: CBORG_API_KEY is not set. Export your CBorg API key and try again:"; \
		echo "  export CBORG_API_KEY=<your-key>"; \
		echo ""; \
		exit 1; \
	fi; \
	CBORG_API_KEY="$$CBORG_API_KEY" envsubst '$$CBORG_API_KEY' < $(DIR)mcp.json > $(MCP_OUT)
	@echo "Done -> $(MCP_OUT)"
	@echo ""
	@echo "================================================================================"
	@echo " SUCCESS: Settings files have been built."
	@echo "================================================================================"
	@echo ""
	@echo " !! WARNING: These files contain your CBorg API key. Do not share or commit them."
	@echo ""
	@echo " Step 1 -- Import Zoo Code provider settings:"
	@echo ""
	@echo "   a. Open Zoo Code Settings (VS Code > Zoo Code > Settings)"
	@echo "   b. Scroll to 'About Zoo Code' and click 'Manage Settings'"
	@echo "   c. Click 'Reset' to clear existing profiles, then restart Zoo Code."
	@echo "   d. After restarting, return to 'Manage Settings', click 'Import',"
	@echo "      and select:"
	@echo "      $(OUT)"
	@echo ""
	@echo " Step 2 -- Install MCP server settings:"
	@echo ""
	@echo "   a. Open Zoo Code Settings (VS Code > Zoo Code > Settings)"
	@echo "   b. Under 'MCP Servers', click the icon to open the global MCP settings file"
	@echo "   c. Replace the file contents with the contents of:"
	@echo "      $(MCP_OUT)"
	@echo ""
	@echo "   Note: MCP servers are disabled by default. Enable individual servers"
	@echo "   in the Zoo Code MCP settings panel when you want to use them."
	@echo ""
	@echo " Codebase indexing (if enabled above):"
	@echo ""
	@echo "   Embeddings requests are routed through a local nginx proxy that injects"
	@echo "   your CBORG_API_KEY -- zoocode has no API key field for openai-compatible"
	@echo "   embedder mode, so the proxy handles auth transparently."
	@echo ""
	@echo "   Start Qdrant + the embeddings proxy before indexing:"
	@echo "      CBORG_API_KEY=<your-key> $(DIR)start-qdrant.sh"
	@echo ""
	@echo "================================================================================"

clean:
	@rm -f $(OUT) $(MCP_OUT)
	@echo "Removed $(OUT) $(MCP_OUT)"
