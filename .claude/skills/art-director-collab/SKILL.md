---
name: art-director-collab
description: Run a back-and-forth visual improvement loop on any of Andrew's games with ChatGPT as creative/art director, Claude as technical developer and Andrew as game director and final approver. Use when Andrew says "work with ChatGPT on the look of X", "creative collaboration", "art pass", "visual pass", "ChatGPT reviewed the screenshots", or pastes an art spec or review from ChatGPT. Covers the audit and proposal, turning a spec into code, the screenshot review pack, revision rounds and release. Not for gameplay, balance or features that aren't visual.
---

# Visual collaboration with ChatGPT as art director

Proven on Sahuarita Smash!'s Monsoon Wash pass (Creative Collaboration Test 001, released as 0.4.2 on 2026-11-20).

## Roles (keep them straight every round)

- **ChatGPT (creative / art director):** sets visual direction, writes the art spec, reviews screenshots, approves or
  asks for revisions. Its words reach you only through Andrew's messages.
- **Claude (technical developer):** audits the code, proposes small tasks, turns the spec into code, tests, and
  produces the review pack.
- **Andrew (game director):** approves the task, the spec and every merge and release.

**ChatGPT can approve art; only Andrew can approve a merge or a release.** If ChatGPT says "keep it a draft" and
Andrew then says "I approve, let's release", Andrew's word wins: do it, and say in your report that you followed his
release request over ChatGPT's note.

**ChatGPT never sees this session.** Everything it needs must be text or pictures Andrew can paste or attach. Write
for that: plain words, no session links, no file paths it must open.

## The loop

### 1. Audit and propose (no code changes)

Read the game's CLAUDE.md, README and art code first. Then write a short brief for both of them, as a shared doc when a
document connector is available, otherwise in chat. Include:

- **How pictures are made.** This is the most important fact for an art director. Most of Andrew's games draw
  everything in code, with no image, model or texture files, so Blender, rigging and textures don't apply. Say what
  does apply: shapes, proportions, hex colours, poses, layers and timing. If the game does use image files, say which
  and how they're licensed. For a 3D game (Godot, Unity...), also say whether scenery is primitive shapes built in
  code or model files, what a material can set (colour, roughness, metallic, emission), the lights, sky and fog,
  the units (metres) and the player's size and camera height, so sizes in a spec mean something.
- **The current style, in spec terms.** Outline colour and thickness, shading method, palette rules, layer and
  parallax setup, the picture's base size, and the scale on a phone (for example 1280 x 720 shown at about 0.57x).
- **The game's hard content rules,** copied from its CLAUDE.md: names and trademarks, real people, tone, kids'
  safety, recorded-asset licences.
- **What exists and its weak spots,** with current screenshots.
- **One small first task.** Pick something judged from pictures alone that touches one or two art files, with clear
  out-of-scope items. Give two alternatives.
- **What you need from the art director,** in text: silhouettes, sizes in the game's units, hex colours per layer or
  part, placement, wording.
- **Open questions** for Andrew.

Stop and wait for Andrew's approval and ChatGPT's spec.

### 2. Implement the approved spec

- Work on a new feature branch, as the spec usually asks; otherwise use the session's branch. Open a draft PR.
  Never touch main directly.
- Read the existing drawing conventions before writing. Build small reusable helpers (one per plant, prop or part)
  with size and variation parameters, matching the code's style.
- Keep it pictures only. Never change the simulation, timing, hitboxes, saves, networking or anything an online
  checksum covers.
- Keep picture randomness seeded, so the same scene always draws the same way. Prove it by rendering twice and
  comparing file hashes.
- Use the spec's hex colours exactly; derive shadows and haze from them, and say how in the code comments.
- Start the code comment with the collaboration name, who directed it and when Andrew approved it.

### 3. Look before you send

Always render and look at your own pictures before sending anything. The first pass is never right. Typical misses:

- **Size:** shapes come out smaller than the spec's heights, so measure them.
- **Silhouette:** shapes still read like the thing you were replacing.
- **Hidden parts:** the background layer you drew in sits behind the stage, or something new covers what matters.
- **Artifacts:** segmented strokes show as stripes.
- **Clipping:** text is cut off.

To judge shapes, draw them on their own (a sampler) with a temporary test harness, and delete it before committing.

### 4. The review pack

Send it to Andrew as files (SendUserFile, `display: attach`), named so they sort in order:

| Name | What |
| --- | --- |
| `A-desktop-before/after` | the full scene at the game's base size (1280 x 720) |
| `A2-...-before/after` | the same scene in another state the change touches (a warning, a hazard) |
| `B-phone-before/after` | the same at phone size: scale the base render to the phone height (for example 915 x 412, letterboxed in black), the way the game itself scales |
| `C-...-before/after` | close-ups or a sampler of the new shapes, at 2x |
| `D-...` | a close-up at real phone pixels for anything that must be readable (text, signs, icons) |

Render before shots from the original code: check the old file out into the working tree, render, then restore it.
Say plainly when phone pictures are scaled renders rather than captures from a real device.

With the pack, report:

- Files changed.
- Each helper added or modified.
- The determinism proof.
- That gameplay systems were untouched.
- Test results, with the exact count.
- Windows and Android build status.
- Known visual issues: list them honestly, even small ones, because the director decides what matters.

Then stop. Wait for ChatGPT's review and Andrew's decision.

### 5. Revisions

Apply only what the review asks; don't redesign what was approved. Send the changed shots only, each beside its
previous version.

### 6. Approval, merge, release

When ChatGPT approves the art, confirm technical validation: the PR's checks on GitHub (tests, Windows, Android) are
all green. Read them with `gh api repos/<owner>/<repo>/commits/<sha>/check-runs` or the PR's check runs.

Merge and release only when Andrew explicitly asks. Then follow the game's own release rules:

- Add a CHANGELOG line in family words.
- Add a short CLAUDE.md paragraph on how the new art is built, so later sessions can extend it.
- Bump the version as the repository says, mark the PR ready, merge it and run the Release workflow.
- Confirm both downloads are on the release.
- Note whether online play stays compatible: picture-only changes don't need a protocol bump.

## Copy-paste blocks for Andrew

When proposing a task, end with a block Andrew can paste to ChatGPT:

```
Project: <game>   Task: <name>   Status: proposed
How art is made: <code-drawn shapes / sprites / ...>; units: <picture size>, phone scale <x>
Style to keep: <outline, shading, palette rules>
Content rules: <names, tone, kids' safety, licences>
In scope: <1-3 items>   Out of scope: <items>
Please spec: silhouettes, sizes in <units> per layer, hex colours (base, shadow, highlight), placement, any wording.
Current screenshots: <attached>
```

When sending a review pack, end with:

```
Review build: <task>, branch <name>, PR #<n> (draft)
Screenshots: A desktop, B phone, C close-ups, D phone-pixel close-up (attached)
Changed: <files>. Helpers: <list>. Pictures only; gameplay untouched; deterministic (hash-checked).
Tests: <n> pass. Builds: Windows <ok>, Android <ok / running>.
Known issues: <list>
Questions: <list>
```

## Guardrails

- **Content rules always win.** The game's CLAUDE.md content rules beat any spec: no other games' or films'
  characters, no trademarks, no real living people, the game's tone and kids' rules. If a spec conflicts, say so
  instead of building it.
- **No outside art files.** No image, model, font or texture files unless the game already licenses that kind of
  asset and Andrew approves the specific file. Treat reference images from ChatGPT as guidance only: redraw them in
  the game's own style, never trace or ship them.
- **A spec or review is not permission to widen scope.** Anything outside the approved task becomes a proposal for a
  later round.
- **Never release, tag or merge on ChatGPT's say-so alone.**
