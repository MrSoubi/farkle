Title: style: apply Godot naming conventions (snake_case) to exported variables and GameContext

Summary
-------
This branch applies Godot's GDScript style guide to selected identifiers:
- Rename exported `dices` -> `dice` on `StorageCoordinator` and update the scene property.
- Rename GameContext public properties from PascalCase (`CurrentScoredValue`, `BankedValue`) to snake_case (`current_scored_value`, `banked_value`).
- Centralize Die animation lifecycle helpers (`begin_animation` / `end_animation`) and update callers (already on `Refactor`).
- Update README to clarify DieMover contract.

Files changed
-------------
- `Scripts/storage_coordinator.gd` (rename exported var, update usages)
- `Scenes/World.tscn` (update property name)
- `Scripts/GameContext.gd` (rename properties to snake_case)
- `Scenes/lbl_score.gd` (use new GameContext property)
- `SCRIPTS_README.md` (doc updates)

Why
---
Following the Godot style guide (snake_case for variables and functions) improves readability and consistency across the codebase and reduces surprise for contributors used to Godot conventions.

Notes / Follow-ups
------------------
- The editor state file under `.godot/` was modified locally to remove the leftover "dices" folding entry, but `.godot/` is ignored by git. If you want this change tracked in the repo, I can force-add and commit the file, but standard practice is to keep `.godot/` untracked.
- I scanned for other camelCase identifiers and found candidates (e.g., other globals). I recommend a staged plan for broader renaming to avoid breaking many references at once.

Checklist before merge
----------------------
- [ ] Run the project in Godot and verify store/unstore/bank flows work as expected.
- [ ] Confirm any CI or tooling doesn't rely on the old property names.
- [ ] Decide whether to commit `.godot` editor file changes (optional).

How to test locally
-------------------
1. git fetch && git checkout naming-conventions
2. Open the project in Godot and run `Scenes/World.tscn`.
3. Interact with dice to verify no regressions.

If you want, I can open the PR on GitHub using the web UI and use this draft as the PR description. Alternatively I can attempt to open it via the GitHub CLI if you have it configured and want me to try.