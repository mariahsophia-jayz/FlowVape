FlowVape 💻📱

A customized, enhanced, and maintained fork of Vape V4 for Roblox. FlowVape features bunch of refined vapev4 modules and custommodules, dedicated PC/Mobile support, custom GUI themes, and a unique watermark to stand out from the standard build.

⚠️ Disclaimer

This project is for educational purposes only. Using exploits in Roblox violates their Terms of Service and can result in your account being banned. Use at your own risk. The maintainers of FlowVape are not responsible for any actions taken against your account.

🙏 Credits

Original Vape V4 development team.

The FlowVape maintainers for customizations, UI, and asset handling, (Complexware, Fanware)

Dev, Bug Fixer, (Jayz, Complex)

🚀 Installation

To use FlowVape, simply execute the loader script in your preferred Roblox executor.
loadstring(game:HttpGet('https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/NewMainScript.lua'))()

Discord Server For FlowVape: https://discord.gg/ayMU8GakVw

## 📝 Changelog

### 2026-10 — Game script reliability & NoFall refresh
- **NoFall:** integrated the GroundHit-based packet path into the existing four-mode module. It probes nearby placed blocks, sends once per fall at the requested velocity threshold, resets on landing/respawn, and disconnects cleanly when disabled.
- **BedWars utilities:** made armor, bow, sword, tool, wool, strength, and placed-block lookups more defensive; `getWool` now accepts an optional inventory instead of reading an undeclared global.
- **Module startup:** game-module initializers report errors without preventing unrelated modules from loading. The BedWars lobby bootstrap now has bounded waits and exits cleanly if Knit never becomes ready.
- **Game loaders:** the two BedWars alias loaders now preserve the native `loadstring`, validate cached/downloaded source, and report compile or startup errors.

### 2026-09 — Module fix & revamp pass
- **Root cause fix:** `safeGetProto` in `games/6872274481.lua` was calling itself recursively instead of `debug.getproto`, so ~20 remotes (EquipItem, ConsumeItem, DropItem, AfkStatus, kit remotes, …) resolved to empty strings and every module using them silently failed. Now resolves correctly, with nested-proto scanning and named fallbacks.
- **NoFall:** restored the working 4-mode module (Packet / Gravity / Teleport / Bounce). Packet mode cancels fall damage server-side via the GroundHit remote.
- **AutoShoot:** rewritten. `Nearest` mode auto-fires your best bow/crossbow at the closest enemy **without holding the bow**, swaps back to your previous item. `Crossbow Macro` keeps the old behaviour.
- **ProjectileAura:** no longer requires a bow in hand; picks best launcher by damage, supports Head/RootPart targeting, min delay, switch-back, sword-check, balloon gravity compensation.
- **ProjectileAimbot:** raycast filter now resolves the map at shoot time instead of load time; NPC targets no longer error.
- **Speed:** merged `ZephyrDisabler` into Speed as a `Mode` dropdown (Heatseeker = 23 cap, Zephyr = 50 cap). Slider max updates live.
- **HitFix:** removed the duplicate Legit copy; patches constants by value instead of hard-coded index so it survives game updates; properly restores on disable.
- **Killaura:** attack-remote lookup no longer hangs forever; upvalue save/restore no longer leaks between toggles.
- **AntiFall:** waits for the map to stream in instead of giving up on the first empty read; no longer crashes when `InfiniteFly` is absent.
- **AutoWin:** `TeleportService` was never defined — fixed.
- **BetterDavey:** no longer blocks forever in lobby (`WaitForChild(..., math.huge)`); referenced out-of-scope `Speed`/`Fly` locals fixed; leaked global fixed.
- **MouseTP:** "Closest Player" actually picks the closest (distance was never updated) and respects teams/friends.
- **TriggerBot Bow Check:** works on executors without `mouse1click`.
- **AutoHonor:** uses Bedwars team attributes instead of Roblox `Team`, correct honor count.
- **KitRender:** no longer depends on `isrbxactive`.
- **Lobby script:** `vape:Remove(i)` referenced an undefined variable; fixed and no longer mutates the table while iterating.
- **GUI:** `moduleapi:Clean` accepts threads; sliders gained `SetMax`.
- **Loader / NewMainScript:** commit lookup uses the GitHub API with HTML scrape as fallback; all URLs point at `mariahsophia-jayz/FlowVape`.
