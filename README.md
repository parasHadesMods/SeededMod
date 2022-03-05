Mod for the Modded Seeded category, to improve quality of life in routed
hades and reduce randomness without impacting the core gameplay.

Core features:
 - Ghosts use separate RNG from the main game, so that they don't affect routing.
 - Money drops use separate RNG from the main game. This means breaking pots won't affect routing, and how much money you get should be more consistent.
 - Spawn positions are deterministic (for the same seed) by sorting the spawn point ids when they come back from the engine.
 - The two RNG calls for Price of Midas happen in a deterministic order.

Possible future features:
 - Deterministic Enemy AI
 - Deterministic secondary spawns
 - Fully deterministic money drops
