# Swift on GitHub Codespaces

Ready-to-use Swift development environment using the official Swift Docker image.

## Quick Start

1. Click the green **Code** button on this repository
2. Open the **Codespaces** tab
3. Click **Create codespace on main**

The first launch takes about 1–2 minutes while it pulls the Swift image.

## Verify

```bash
swift --version
```

## Run the sample

```bash
swift run
```

You should see:

```
Hello from Swift on GitHub Codespaces! 🐋
```

## Create a new package

```bash
mkdir MyApp && cd MyApp
swift package init --type executable --name MyApp
swift run
```

## What's included

| Item | Details |
|------|---------|
| Base image | `swift:latest` (official) |
| VS Code extension | [swiftlang.swift-vscode](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode) |
| Debugging support | `SYS_PTRACE` enabled for LLDB |

## Notes

- GitHub Free accounts include 120 core-hours/month of Codespaces.
- Stop the Codespace when finished to save free hours.
- To pin a specific Swift version, change `"image": "swift:latest"` in `.devcontainer/devcontainer.json` to e.g. `"swift:6.0"` or `"swift:5.10"`.
