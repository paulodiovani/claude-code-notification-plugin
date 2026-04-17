# claude-code-notification-plugin

Claude Code plugin to enable desktop notifications.

## Features

- Display Desktop notifications for the following events:
  - ✅ Claude has finished the current task (`Stop`)
  - ❌ Claude failed to complete the task (`StopFailure`)
  - ❓ Claude has a question for you (`PermissionRequest`)
  - 🤖 An MCP tool requested your input (`Elicitation`)
- Notifications are delayed 30 seconds and cancelled automatically if Claude resumes work before they fire, so you're only notified when Claude is actually idle.

## Dependencies

- [`jq`](https://stedolan.github.io/jq/) — used to parse hook input.

### macOS

No extra dependencies. Uses `display notification` via AppleScript.

## Installation

Install the plugin via `/plugins` -> Marketplaces -> Add Marketplace, then add:

```
paulodiovani/claude-code-notification-plugin
```

And install the `notification` plugin from the marketplace.
