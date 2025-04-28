# VS Code "Continue" Plugin Installation

Integration of CBorg with VS Code "Continue" will enable chat within VS code, in addithion to autocomplete and code indexing.

## Instructions: 

1. Install VS Code "Continue" Plugin

Quickstart Documentation: https://docs.continue.dev/quickstart

2. Clone this repo and change into the 'continue' subdirectory

3. Run ./install-vscode-continue.sh

The install script will prompt you for the preferred installation method:

- Simple: Easy to setup, but if your API key changes you'll need to run it again
- Standard: Will configure Continue to get the API key from your CBORG_API_KEY environment variable. Recommended for most users.
- Proxy: Will configure Continue to use the CBorg Client Proxy (proxy/cborgclient.py) for reduced latency in autocompletion while connected to LBL-net

After selecting your method and confirming the prompts, you should be able to use the "Continue" plugin in VS Code.

4. Start VS Code.

## Using Chat

Open the side panel and select "Continue" from the dropdown. You should see a chat window. You can type a prompt and press enter to send it to the server. You can also use the slash commands to generate code, comments, etc. You can also change the model by selecting the drop down next to the chat window.

## Using Autocomplete

To verify functionality, create a new Python file and type "# Write a hello world program" and press enter. You should see suggested autocompletions (hit 'tab' to accept them)

## Note about the CBorg Client Proxy

The "Client Proxy" (proxy/cborgclient.py) is no longer recommended, but is still available. Using the proxy can reduce latency in autocompletion while connected to LBL-net.

## How to Debug VS Code "Continue" Plugin

Open the VS Code Console, select "Continue - LLM Prompt/Completion". It will show you the actual contents of prompts being transmitted to the server.

## Note about config.yaml

Continue is moving to a new config format, `config.yaml`. Currently this is not supported with the CBorg setup, but the config.json is still supported by Continue.

Make sure that your setup does not also include a `config.yaml` file as the two methods will conflict and defer to the YAML source. The installation script will remove the YAML file if necessary.


