# ArmyMen's Revenge 2026

**Plastic soldiers. Modern warfare.**

![Desert](docs/screenshots/desert.png)

ArmyMen's Revenge 2026 is a third-person toy-soldier shooter built in **Godot 4.3**. You play a green plastic commando fighting the Tan Army across three operations, using modern weapons, kit and air support. Soldiers who die melt into puddles.

Everything is generated in code: the models, maps, effects, UI and sound effects. The project has no binary assets, so it's small and works well with git.

## Running it

1. Install **Godot 4.3** or newer (the standard build, not the .NET build): <https://godotengine.org/download>
2. Open Godot, click **Import**, and select `project.godot` in this folder.
3. Press **F5** (Run Project).

The project uses the Forward+ renderer. On older GPUs or integrated graphics, switch to the Compatibility renderer: **Project → Project Settings → Rendering → Renderer → Rendering Method = gl_compatibility**.

### Building a Windows .exe

**Editor → Manage Export Templates → Download**, then **Project → Export… → Add… → Windows Desktop → Export Project**.

## Controls

| Key | Action |
|---|---|
| W A S D | Move |
| Mouse | Look / aim |
| Left click | Fire |
| Right click | Aim down sights (the Mk 22 uses a scope) |
| Shift | Sprint |
| C / Ctrl | Crouch (makes you harder to spot) |
| Space | Jump |
| R | Reload |
| 1–5 / mouse wheel | Switch weapon |
| G | Throw frag grenade |
| F | Call a Reaper drone strike on the crosshair |
| Esc / P | Pause |

## Arsenal

| Slot | Weapon | Notes |
|---|---|---|
| 1 | M4A1 Carbine | Full-auto all-rounder |
| 2 | M249 SAW | 100-round belt; suppress them |
| 3 | M1014 Shotgun | Close quarters |
| 4 | Mk 22 Sniper Rifle | Scoped; headshots deal 2.2× damage |
| 5 | AT4 Launcher | Splash damage; deals full damage to objectives |
| G | M67 Frag | Cooks for 2.4 s |
| F | Reaper drone | Marks the target, then a Hellfire strike lands 2.7 s later |

Bullets deal only 30% damage to objective hardware (radar jammers, SAMs and boosters). Use the AT4, grenades or a drone strike on them.

## Campaign

1. **Operation Dust Lid**: desert FOB, a mud-brick village and a fortified Tan compound with watchtower snipers. Destroy 3 radar jammers, then extract.
2. **Operation Concrete Jungle**: a city grid with rooftop snipers and checkpoints. Eliminate Colonel Khaki, destroy 2 mobile SAMs, then extract.
3. **Operation Tabletop**: a giant kitchen table covered with a laptop, smartphone, energy drinks and a game controller. Destroy 3 Wi-Fi signal boosters, then clear the table.

Finishing an operation unlocks the next one. There are three difficulty levels (Recruit, Regular and Veteran), which change enemy damage, accuracy and reaction time.

## Project layout

```
project.godot            Engine config (autoload: Game)
scenes/main.tscn         Entry scene
scripts/
  game.gd                Autoload: input map, settings/save, difficulty, synthesized SFX
  main.gd                Title diorama, menus, briefing, debrief
  level.gd               Level runtime: builder API, objectives, pause, explosions
  level_data.gd          The three maps + briefing text  <- add new maps here
  player.gd              Third-person controller, weapons, grenades, drone
  enemy.gd               Tan Army AI (patrol / investigate / combat)
  toy_soldier.gd         Procedural plastic soldier model + melt animation
  weapons.gd             Weapon stats table          <- tune weapons here
  target.gd              Destructible objectives
  pickup.gd              Supply crates
  rocket.gd, grenade.gd, drone_strike.gd, fx.gd, hud.gd, ui_util.gd
tests/
  smoke_test.tscn        Headless playthrough of all operations
  screenshot.tscn        Renders menu/level screenshots
```

### Adding a map

Add an entry to `META` in `level_data.gd`, write a `static func _yourmap(L) -> Dictionary` that uses the helpers (`L.box`, `L.cyl`, `L.wall`, `L.add_enemy`, `L.add_target`, `L.add_pickup`, …), and route to it from `build()`. Objective types are `destroy`, `kill_hvt`, `kill_all` and `extract`.

### Tests

Run the smoke test from the project folder:

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

It plays through every operation (spawning, firing, grenades, drone strikes, AI engagement, objectives, extraction, pause/restart and death) and exits non-zero on failure.

## Ideas for next steps

- Vehicles: a drivable JLTV, a Tan APC and an attack helicopter
- Friendly AI squadmates
- Real audio and music in place of the synthesized SFX
- Navmesh pathfinding (the current AI uses steering and line of sight)
- Split-screen or online co-op
