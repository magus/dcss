# Codex Notes

Repo-specific notes for future Codex runs.

## Workflow

- Primary source files are under `compile-rc/parts/`; generated rc output is `output/magus.rc`.
- Do not regenerate or edit `output/magus.rc` unless the user explicitly asks. The user has said not to worry about that file during slot-option edits.
- `yarn compile` copies the generated rc to the clipboard. Avoid running it casually; ask or only run when the user clearly wants generation/verification.
- Prefer read-only searches with `rg` before editing. The local Crawl source is usually available under:
  - `~/github/dcsseeds/crawl-dir/<version>/crawl-ref/source`
  - For 0.34: `~/github/dcsseeds/crawl-dir/0.34/crawl-ref/source`

## User Preferences

- The user is playing DCSS 0.34 but wants rc compatibility with older versions where practical.
- When a Crawl rc option changed names, keep adjacent duplicate entries for compatibility, for example:
  - `item_slot += ...`
  - `gear_slot += ...`
- The user prefers source permalinks in comments when slot lists are based on Crawl source data.
- The user prefers using Crawl defaults when the game already provides good defaults. Do not override those unless there is a clear intentional preference.

## Slot Rules

- `gear_slot` is the 0.34 replacement path for gear inventory slot assignment. Keep old `item_slot` entries paired beside it for older Crawl versions.
- `gear_slot`, `item_slot`, `spell_slot`, and `ability_slot` accept multiple candidate letters. Crawl iterates the string in order and uses the first suitable letter.
- The preferred heuristic for multi-letter lists is:
  - first letters from meaningful words,
  - then ending letters,
  - then remaining letters from the name,
  - include uppercase variants as fallbacks.
- Use this style for talismans and jewellery rather than only one fixed letter.

## Consumable Shortcuts

- DCSS 0.34 already ships consumable defaults in:
  - `https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/dat/defaults/consumable_shortcuts.txt`
- Example: `scroll of identify` defaults to `i`; do not override it with a custom rc shortcut.
- Keep consumable defaults documented as comments if useful, but leave them inactive unless the user explicitly wants to override the game defaults.

## Jewellery Notes

- Validate 0.34 jewellery names against:
  - `https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/item-name.cc`
  - `https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/dat/descript/items.txt`
- 0.34 uses `amulet of magic regeneration`, not `amulet of mana regeneration`; use a compatibility regex such as `(mana|magic) regeneration` when preserving old versions.
- 0.34 uses `ring of willpower`, not `ring of protection from magic`; use a compatibility regex such as `(protection from magic|willpower)`.
- Some older jewellery entries are obsolete in 0.34 but may be kept as holdbacks for older versions, e.g. `amulet of rage`, `ring of stealth`, `ring of teleportation`.
