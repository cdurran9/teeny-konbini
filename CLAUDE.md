# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Project

```bash
godot --path .
# or
godot4 --path .
```

This is a **Godot 4.6** project using Forward Plus rendering and Jolt Physics. There is no separate build step — open/run directly in the Godot editor or via CLI.

## Architecture Overview

**Teeny Konbini** is an incremental idle game about running a convenience store. Income is earned passively each game tick based on owned products and upgrades.

### Autoloads (Singletons)

All core systems are autoloads registered in `project.godot`:

| Autoload | Role |
|---|---|
| `GameLoop` | Drives tick timer (1s interval); emits `EventBus.tick_processed` |
| `GameState` | Owns mutable state: `current_money`, `owned_upgrades`, `owned_products` |
| `EventBus` | Central signal hub — all cross-system communication goes through here |
| `UpgradeRegistry` | Loads all `.tres` from `resources/upgrades/concrete/` and `resources/products/concrete/` at startup; builds prerequisite index |
| `TickCalculator` | Computes per-tick income from current state |
| `TickContext` | Value object passed through `TickCalculator`; accumulates margin multipliers and purchase rates |

### Tick Flow

1. `GameLoop` timer fires → `EventBus.tick_processed(tick_data)` emitted
2. `GameState` receives signal → adds income to `current_money` → emits `EventBus.money_changed`
3. UI updates money display

### Income Formula

```
income_per_tick = Σ over all shops × Σ over owned products:
    product.base_margin × product_tag_margin_multipliers
```

Effects modify `TickContext` (margin multipliers, purchase rates) keyed by product tag strings.

### Resource System

Game content is defined as Godot `Resource` subclasses stored as `.tres` files:

- **`ProductDefinition`** (`resources/products/product_definition.gd`) — `id`, `display_name`, `margin`, `tags: Array[String]`
- **`UpgradeDef`** (`resources/upgrades/upgrade_def.gd`) — `id`, `display_name`, `base_cost`, `effects: Array[Effect]`, `prerequisites: Array[String]`
- **`Effect`** (base class, `resources/upgrades/effect.gd`) — abstract; subclasses implement `apply(context)` and `on_purchase(state)`

Concrete resources live in `resources/upgrades/concrete/` and `resources/products/concrete/`.

### Product Importer Plugin

An editor plugin at `addons/product_importer/` reads `resources/products/product_data.json` and auto-generates `ProductDefinition` `.tres` files. Run it via **Tools → Import Products** in the Godot editor when updating product data.

### Adding New Content

- **New product**: Add entry to `product_data.json`, run the importer plugin
- **New upgrade**: Create a `.tres` of type `UpgradeDef` in `resources/upgrades/concrete/`; set `effects` array to instances of existing or new `Effect` subclasses
- **New effect type**: Subclass `Effect`, implement `apply(context: TickContext)` and `on_purchase(state: GameState)`

### UI

`scenes/ui/ui.tscn` + `scripts/ui/ui.gd` dynamically instantiates `UpgradeButton` nodes for all registered upgrades. `upgrade_button.gd` subscribes to `EventBus.upgrade_purchased` to disable itself after purchase.
