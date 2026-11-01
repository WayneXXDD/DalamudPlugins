# Wayne's Dalamud plugin repository

Add this URL in `/xlsettings` → **Experimental** → **Custom Plugin Repositories**, enable it, and save:

```text
https://raw.githubusercontent.com/WayneXXDD/DalamudPlugins/main/pluginmaster.json
```

Then use `/xlplugins` to install **XIV Combo Expandedest (Wayne)** or **Oracle (Wayne)**.

**Guildhest Queue (Wayne, Testing)** automatically queues for a selected guildhest or Guildhests roulette, confirms entry, and optionally leaves after completion before repeating. Combat remains manual. Enable **Get plugin testing builds**, refresh the installer, and search **Guildhest Queue**. Use `/ghq` to select content and start or stop. It has no dependency on CBT, Yes Already, AutoDuty, or other plugins; the game loop still requires in-game testing.

**Native Chat Tabs (Wayne, Testing)** is an experimental testing-only plugin. Enable **Get plugin testing builds** in `/xlsettings` → **Experimental**, then refresh `/xlplugins` and search **Native Chat Tabs**. After installation, use `/nct` to configure and enable it. Its native UI behavior still requires in-game testing.

This repository holds the combined plugin index. Plugin ZIPs, icons, and their license notices are published by [Combo's build workflow](https://github.com/WayneXXDD/Combo/actions/workflows/build.yml). Native Chat Tabs ZIPs are published by [its own build workflow](https://github.com/WayneXXDD/NativeChatTabs/actions/workflows/build.yml). Guildhest Queue ZIPs are published by [its build workflow](https://github.com/WayneXXDD/GuildhestQueue/actions/workflows/build.yml). Source code remains in [Combo](https://github.com/WayneXXDD/Combo), [Oracle](https://github.com/WayneXXDD/Oracle), [NativeChatTabs](https://github.com/WayneXXDD/NativeChatTabs), and [GuildhestQueue](https://github.com/WayneXXDD/GuildhestQueue).

The index synchronizes hourly and can be refreshed immediately from **Actions → Sync plugin repository index → Run workflow**. GitHub may delay scheduled runs. For inactive public repositories, GitHub may disable scheduled workflows after 60 days of inactivity; use the manual workflow to resume updates.

After pushing a Combo update, its build workflow publishes both plugins. After an Oracle update, manually run the Combo build workflow first. Then run this repository's sync workflow or wait for its next scheduled run.

After a NativeChatTabs or GuildhestQueue main push, wait for its build and publication to succeed, then run this repository's sync workflow or wait for the next hourly sync.

Increase numeric assembly versions when releasing plugin code changes so Dalamud can detect updates. The original internal names are retained for configuration compatibility.

Use the DalamudPlugins index URL above. The legacy Combo pluginmaster.json URL has been removed.
