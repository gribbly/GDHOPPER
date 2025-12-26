# PROCGEN.md

This document describes the procgen approaches used in ROCKHOPPER to generate levels. Right now, it is focused on "carving the rock" - i.e., generating the "terrain" for ROCKHOPPER levels. ROCKHOPPER are stylized asteroids, suitable for lunar lander-style gameplay (i.e., caverns and tunnels to fly through and land in).

# General implementation guidelines

The overall strategy and co-ordination of level generation is owned by `Level.tscn` and `level.gd`. When we want to create a new level, `App.gd` removes `Level.tscn` from the tree, then instantiates a new copy. This causes `level.gd` to regenerate a level "from scratch".

Level gen happens at runtime, so it is important that it remains performant on target hardware (Steam Deck). It is OK to drop frames (dip below 60FPS) during level generation (we must never drop frames during gameplay).

* Put each generation "step" (see below) in a separate file. The goal is to have each step cleanly separated as opposed to "one big file". Feel free to create new files if necessary.
* Put tuneables in `level.gd` so it's the "one stop shop" for tweaking level gen
* Get random numbers from `Globals.gd` (references as `RH.*`) - this is important as we will later implement seeded randomness for reproducible level gens, so randomness must be centralized.
* The necessary CSG mesh primitives are supplied in `LevelCSG.tscn`. Look for them there.
  * The base rock (that everything will be carved into) is already hand placed under `%LevelCsgCombiner`.
  * There are CSGShape3DNodes pre-placed in `LevelCSG.tscn`. These are the source for copies that are instantiated under `%LevelCsgCombiner`.
    * `%CavernCarve01` - this is the shape to use for caverns. At 1.0 scale, it is the right size for a "large" cavern. So medium and small caverns should be scaled down in X and Y (not Z) as needed. Pre-configured with Operation=Subtraction.
    * `%TunnelCarve01` - this is the shape to use for tunnels. The shapes need to be placed repeatedly along the tunnel path, close enough to overlap. Pre-configured with Operation=Subtraction.
    * In the future, there will be multiple alternatives shapes to choose from randomly for both Cavern and Tunnel. For now, we ar ejust using one to keep things simple.
  * Important: Don't scale down "carve" CSG meshes on the Z axis. If you do, they may no longer be "deep" enough to carve all the way through the base rock. Only scale on X and Y.

# Carving "The Rock"

## Overview

The basis of a ROCKHOPPER level is the "the rock" - this is the terrain that the ship lands on, flies over and through, and can crash into. It is also where various game entities (e.g., outposts and towns, etc.) will be placed, but that is beyond the scope of this section.

The rock starts as an "uncarved block" of CSG in `LevelCSG.tscn` called `%BaseRock01`. `%BaseRock01` is hand-placed in `LevelCSG.tscn`, and is parented to `%LevelCsgCombiner`. Most of the work of generating a level is placing additional CSGMesh3D nodes under `%LevelCsgCombiner` to subtractively "carve" caverns and tunnels into `%BaseRock01`.

We use a multipass strategy to carve first caverns and then tunnels into `%BaseRock01`:

1. Generate a 2D grid that is sized to the base rock mesh.
2. Place caverns (first large, then medium, then small) using rejection sampling and inflated footprints to ensure spacing. For each cavern, instantiate a copy of the supplied "CavernCarve" mesh as a substractive CSG shape, and scale for large/medium/small.
3. Build a connection graph between the caverns, using a Minimum Spanning Tree/Prim's algorithm. Add a few extra edges for loops for a natural layout - mostly tree-like with occasional cycles.
4. Carve the tunnels using an "L-path with random bend points" approach. Tunnels are allowed to "cross each other" to create T and X junctions. Carve the tunnels by repeatedly instantiating overlapping copies of the supplied "TunnelCarve" mesh as a substractive CSG shape along the path.
5. Finally, convert the resulting `%LevelCsgCombiner` into a "real" mesh and delete the CSG shapes. This step is for performance reasons, and can be disabled for debugging purposes (i.e., to inspect the generated shapes)

Here is more information on each step.

## 1. Generate 2D grid

The programmer specifies the number of rows and columns in level.gd.

The size of `%BaseRock01` is given by placement of `%BaseRockTopRightCorner` relative to scene origin.

## 2. Place caverns

For each requested cavern (place large first, then medium, then small):

1. Build a list of candidate cells you’re willing to consider:

* inside bounds
* not blocked
* optional taste filters (see below)

2. Pick a random candidate, test if its inflated footprint fits:

* if fits: place it, then mark all cells in inflated footprint as blocked
* if not: try again up to N attempts

3. If you fail to place after N, either:

* reduce breathing room for that cavern
* reduce that cavern count
* or restart the whole generation with a new seed

4. Instantiate the supplied cavern mesh, and scale it appropriately. `%CavernCarve01` is supplied in `LevelCSG.tscn`. Instantiate copies of this shape to use for caverns. At 1.0 scale, it is the right size for a "large" cavern. So medium and small caverns should be scaled down in X and Y (not Z) as needed.

Generation goals:

* Avoid clustering: when picking candidates, score by distance to nearest placed cavern (prefer farther for large caverns).

Proposed scoring approach:

* Sample K random candidates, compute score, choose best (“best-of-K”).
  * Score example: +distance_to_nearest_cavern - penalty_near_edge + noise_bias

Tuneable parameters:

* Target number of large, medium and small coverns (int). Starting point = two large, two medium, two small.
* Avoid borders? (bool) If true, disallow centers within margin_cells of edges. Default = true.
* Size of medium and small caverns (as a percentage relative to large) (float)

## 3. Connection graph

* Build a complete graph where nodes = caverns, edge weight = Manhattan distance (or world distance).
* Compute a Minimum Spanning Tree. Suggest ugins Prim’s algorithm as it is easy to implement and understand.
* Special case: Find the top-most cavern and create a tunnel straight up to the "surface" (the top edge of "The Rock")

Tuneable parameters:

* Extra connection probability. For each cavern, add 0-1 extra connection to it's nearest non-connected neighbor with probability p. (float). Default = 0.0 (no extra connections)

Generation goals:

* Tunnels are forbidden from entering/existing the bottom edge of a cavern. Tunnels must always connect at the top, left or right. To "go down" a tunnel should exit from the left/right, then "turn down" once clear of the cavern.
* Everything is connected with minimal total tunnel length.
* Natural layouts: mostly tree-like with occasional cycles.


## 4. Carve the tunnels

For cavern A at (ax, ay) and cavern B at (bx, by):

1. Compute dx = bx - ax, dy = by - ay.
2. Choose an order: horizontal-then-vertical or vertical-then-horizontal (random).
3. Add optional jitter bends:

* Instead of one corner, pick 1–3 intermediate waypoints.
* Example:
  * Pick a random x between min(ax,bx) and max(ax,bx) (or random y)
  * Path: A → (rand_x, ay) → (rand_x, by) → B
  * For multiple bends: alternate axis changes with random intermediate coords, but ensure you still monotonically approach target overall (to prevent huge detours).

4. Instantiate copies of the supplied tunnel carve mesh along the tunnel path (as many as needed to "carve" the tunnel)

* Apply random rotation to the Z axis

Tuneables:

* Number of extra "bends"
* Spacing of the tunnel carve shapes. (float) Programmer can choose to pack them more tighly or sparsely, to achieve a balance between visual and functional outcomes and the number of CSG shapes instantiated during generation.
* Amount of size variation. (float). Default = zero. Can add noise to instantiated tunnel shapes to add more "organic" feel to the tunnels.

Generation goals:

* Tunnels should be generally "horizontal" or "vertical", with deliberate L-shaped bends.
* Tunnels should be "flyable" (i.e., shapes overlap enough to create an actual tunnel).
* Tunnels should look "hewn out of rock" (the random rotation helps with this)

## 5. Convert to mesh

This is already implemented. See convert_to_mesh() in level_csg.gd.

It is called from level.gd (current commented out for debugging reasons).
