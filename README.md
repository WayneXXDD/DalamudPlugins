# Wayne's Dalamud plugin repository

Add this URL in `/xlsettings` → **Experimental** → **Custom Plugin Repositories**, enable it, and save:

```text
https://raw.githubusercontent.com/WayneXXDD/DalamudPlugins/main/pluginmaster.json
```

Then use `/xlplugins` to install **XIV Combo Expandedest (Wayne)** or **Oracle (Wayne)**.

This repository holds the combined plugin index. Plugin ZIPs, icons, and their license notices are published by [Combo's build workflow](https://github.com/WayneXXDD/Combo/actions/workflows/build.yml). Source code remains in [Combo](https://github.com/WayneXXDD/Combo) and [Oracle](https://github.com/WayneXXDD/Oracle).

The index synchronizes hourly and can be refreshed immediately from **Actions → Sync plugin repository index → Run workflow**. GitHub may delay scheduled runs. For inactive public repositories, GitHub may disable scheduled workflows after 60 days of inactivity; use the manual workflow to resume updates.

After pushing a Combo update, its build workflow publishes both plugins. After an Oracle update, manually run the Combo build workflow first. Then run this repository's sync workflow or wait for its next scheduled run.

Increase numeric assembly versions when releasing plugin code changes so Dalamud can detect updates. The original internal names are retained for configuration compatibility.

The existing Combo repository URL continues to work.
