# VS Code "Continue" Plugin Installation

IMPORTANT: Read this Quickstart Guide: https://docs.continue.dev/quickstart

## Option #1 - Easy Setup

This will enable chat within VS code, but does not enable tab-autocomplete or code indexing.

1. Install VS Code "Continue" Plugin

2. Copy the file easy-setup-config.json to ~/.continue/config.json

```
cp ./easy-setup-config.json ~/.continue/config.json
```

3. Edit the config.json and replace ADD_YOUR_CBORG_API_KEY_HERE with your API key:

```
  "requestOptions": {
      "headers": {
          "X-CBorg-Continue-ConfigVersion": 0.1,
          "Authorization": "Bearer ADD_YOUR_CBORG_API_KEY_HERE"
      }
  },
```

4. Start VS Code.

   - Chat Models will be available in the side pane, and other editor functions

## Option #2 - Advanced Setup

1. Install VS Code "Continue" Plugin

2. Run ./install-vscode-continue.sh 
   This script will replace the default config.json with the managed version in this directory

3. Install and start the CBorg Client-side Proxy (see /proxy directory)

4. Start VS Code.

   - Chat Models will be available in the side pane, and other editor functions
   - Code generation/editing model will correspond to whatever model is selected in the chat side pane
   - Tab-style Autocompletion also works (may take around 1-2 seconds to generate)
   - Full codebase can be indexed and retrieved using embedding model to enhance autocompletion
   - To debug LLM prompting, open Console, select "Continue - LLM Prompt/Completion"
