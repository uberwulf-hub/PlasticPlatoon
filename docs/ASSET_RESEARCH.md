# Asset research: models, buildings, weapons, music, SFX and ambience

**Rule used: CC0 (public domain) first.** CC0 assets need no attribution, can be modified, and can be used in a commercial release. CC-BY is acceptable if we add credits. **Avoid NC (non-commercial), ND (no-derivatives) and ripped game assets.** `CREDITS.md` lists exactly what ships in the game.

## 1. Soldier characters

| Option | License | Verdict |
|---|---|---|
| **Quaternius Toon Shooter Game Kit: Character_Soldier** ✅ *in game* | CC0 | **Best fit.** It's rigged, has 17 animations (Idle, Walk, Run, Run/Walk/Idle_Shoot, Duck, Death, HitReact, Jump…), and its 14 guns are already attached to the hand. Its materials are solid colors, so `plastic_soldier.gd` recolors the whole model to **green or tan plastic** at runtime. |
| Sketchfab: "Army Man Rigged Model" (GTA_Models, 974 tris), "Army Man with Gun and Backpack", "Low Poly Soldier Fully Rigged" (16 Mixamo anims) | CC-BY | Closer to classic army-man proportions, but downloading needs a Sketchfab login. These are good candidates for a "realistic toy" variant. Avoid models marked NC or ND, and the 42manako rips. |
| Meshy AI "Toy soldier, Plastic Green army man" | Listed CC0 | AI-generated and static (no rig). Fine for statues or set dressing, not for animated characters. |
| MyMiniFactory / MakerWorld army-men pose STLs | Varies by model | These are 3D-printing sculpts: high-poly, no rig, one static pose each. They'd only work as background props after decimation. |
| Quaternius Universal Animation Library | CC0 | 120+ extra animations (combat, guns, emotes) for humanoid rigs. Use it if we need crawling, throwing or reloading animations. |

**Note on licensing:** a 2026 guide says Quaternius now publishes a "Quaternius Asset Licence" for new releases. The Toon Shooter kit (Dec 2022) is still marked CC0 on its official page.

## 2. Buildings, structures and props (all ✅ CC0, in `assets/packs/`)

| Pack | What it's used for |
|---|---|
| Kenney **City Kit Commercial / Industrial** | City-map buildings and skyscrapers, auto-fitted to each lot |
| Kenney **Car Kit** | Street cars, traffic cones, giant toy cars on the tabletop |
| Kenney **Nature Kit** | Desert rocks, cacti, palms, park trees |
| Quaternius **Toon Shooter Environment** | Sandbag trenches, shipping containers, burnt-out car wrecks, explosive barrels (they chain-react), barriers, water tower, street lights |
| Kenney City Kit Suburban / Roads, Modular Buildings, Retro Urban | Imported and ready for future maps (roads, houses, modular walls) |
| Quaternius **Ultimate Gun Pack** (FBX) | 50+ modern guns and attachments (scopes, silencers, grips, bipod). Ready for a weapon-model upgrade |
| *Extras zip:* Majadroid **Apocalyptic Buildings**, eracoon **Vehicles** | Ruined high-rises for a "war-torn city" map, plus civilian cars (OBJ) |

The Kenney packs are colorful and toy-like, which suits plastic soldiers well.

## 3. Music (all ✅ CC0, from OpenGameArt)

| Where | Track |
|---|---|
| Main menu | *Some Militaristic Tune* by Spring Spring (brass, snare and balalaika march) |
| Op 1 Desert | *Battle Theme A* by cynicmusic |
| Op 2 City | *War Theme* by Spring Spring (orchestral, timpani, brass, choir) |
| Op 3 Tabletop | *Determined Pursuit* by Emma_MA (epic orchestral loop) |
| Spare / alternatives | *QaziJamJam* (Emma_MA, 4-minute orchestral battle), *Call to War* (Umplix), *Fast fight* (XCVG, looped), *Level & Battle Theme loops* (Trex0n). All are CC0. |

**Other good sources to check by hand:** Kevin MacLeod / incompetech (CC-BY, huge military and action catalog, credit required), Pixabay Music (Pixabay license, commercial OK), and FreePD (public domain). Paid options if you want blockbuster quality: "Total War Game Music Loops" (Construct, $39) and "Flames of War" (GameDev Market).

## 4. Sound effects

✅ In game: real gunshot recordings by Tabasco (CC0; SKS, CZ, Mosin and shotgun, cut into single shots), plus yd's *War on Water* pack (machine gun, rocket, grenade throw, radio chatter, helicopter), qubodup's explosion, SpringySpringo's reloads and Kenney's Interface Sounds.

**Biggest upgrade available, which you have to download yourself:**
- **Sonniss GDC Game Audio Bundle** (sonniss.com/gameaudiogdc). It's tens of GB of *professional* SFX from commercial vendors, including real weapon fire, explosions and ambiences. It's royalty-free, needs no attribution, and allows commercial use. It may not be used for AI training. Read the license file in the download. **This is the best free source for AAA-grade gunfire.** Look for files tagged M4, M249, AT4, Barrett, frag, and "distant battle".
- **Freesound.org.** Filter by **License: Creative Commons 0** and search "m4", "rifle", "explosion", "room tone", "desert wind", "kitchen". Clean gunshot recordings are rare there, and licenses are per file. The site blocks automated downloads, so it's manual only.
- **Kenney audio packs** (kenney.nl: Impact Sounds, Sci-Fi Sounds, RPG Audio). All CC0. Kenney's site also blocks automated downloads, but many packs are mirrored on OpenGameArt.

## 5. Ambience (all ✅ CC0)

| Map | Bed | Extras |
|---|---|---|
| Desert | Luke.RUSTLTD *wind1* | Random distant explosions (NenadSimic) |
| City | IgnasD *high traffic road* | Random distant explosions |
| Tabletop | bart *ticking clock* (a giant house clock) | Idea: add a fridge hum from Freesound (CC0) by hand |
| Extraction zones | Looping helicopter rotor (yd) | |

## 6. What couldn't be downloaded from the cloud session

kenney.nl and freesound.org refuse automated downloads, and Sketchfab needs a login. Everything above marked ✅ came from OpenGameArt or a GitHub mirror of the CC0 Quaternius kit. If you download Sonniss or Freesound files yourself, drop them into `assets/audio/sfx/` using the names in `scripts/game.gd` → `SFX_FILES`. They'll be used automatically, and you can list several variants per sound.
