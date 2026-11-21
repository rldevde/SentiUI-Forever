# SentiUI Training — Changelog

## 0.2.6

- Interface-dispatch audit: the profession scan on CRAFT_UPDATE runs a frame outside the craft-window dispatch - the same dispatch family whose secret cooldown compare broke before.

## 0.2.5

- Dispatcher rollback: the pet-craft scan listens to CRAFT_UPDATE again - the craft-frame state polling is removed.


## 0.2.4

- CRAFT_UPDATE replaced by craft-frame state polling - the event fires inside the craft window's protected update dispatch.


## 0.2.3

- Escape-forbidden-call fix: the search box `OnEscapePressed` ran inside the Escape dispatch - Escape drops focus natively and the window joined `UISpecialFrames` so Escape closes it.


## 0.2.2

- Fixed `attempt to index global 'holder'` on window open: the
  scroll-child frame was declared below the thumb/layout functions that
  capture it, so it resolved as a nil global - forward-declared now.

## 0.2.1

- Trainers and the dungeon Journal are mutually exclusive - opening one closes the other.

## 0.2.0

- Window rework: book icon header with accent divider, gold rules on
  section headers, zebra row striping, the list now sits in an inset
  card with a slim gold scroll thumb, slightly larger window.

## 0.1.0

- Initial release: the trainer compendium as its own SentiUI module.
  Three tabs — **Spells**, **Weapon skills**, **Professions** — group
  everything your class and weapon masters still teach plus every
  unlearned profession recipe into *learnable now / missing
  requirements / coming soon / later / ignored / known*. Search box,
  profession filter chips, right-click to ignore entries (warlock
  tomes get marked learned), waypoint button on weapon-skill rows,
  spell and recipe tooltips with sources. Opens from the **Trainers**
  plugin on the SentiUI Panel bottom bar or `/suitr`. Ignores and
  tome marks are saved per character.
