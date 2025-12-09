# ROCKHOPPER

## Project status

* Early! We are still setting up the basic framework. Most of the game is not implemented.
* Project author (Cam) is still learning Godot. So we're going slow and steady.
  * Cam is experienced with Unity, so explaining things by comparing to Unity concepts can be useful (but don't overdo it)
* When helping, don't "race ahead". Go step-by-step and be patient.

## Technical details

* Built with Godot 4.5.1
  * Godot project name: GDHOPPER
* Using GDScript
* Default resolution is 1280x800 (primary target = Steam Deck)

### Technical goals

* Never drop below 60FPS during gameplay, on Steam Deck
* Minimal dependencies
* Clean, maintainable code, separated into focused units
* Prefer readable and simple over "clever"
* Only optimize when profiler says its necessary

### Details and gotchas

* When using SignalBus.connect in '_ready', you probably need to do SignalBus.disconnect in '_exit_tree'. See /scenes/game/level_csg.gd for an example.

## Game design

The "one liner" is "Balatro meets Lunar Lander".

Which means:

* This is a rogue-like - high stakes decisions, permadeath, and exposure to randomness.
* The moment-to-moment mechanic is "lunar lander", with a focus on newtonian physics and fun landing mechanics.
* The meta is a simple trading economy which motivates your movement through a level and creates "interesting decisions"
* Over a run, you'll upgrade your ship build with mods that give you cool and interesting capabilities.
* Difficulty steadily increases over the course of the run - your build better keep up!

### Design goals

1. Steam deck is primary platform
2. ~30 minute runs (over multiple levels)
3. Rogue-like stakes (i.e., permadeath)
4. Synergies and “builds”
5. Spaceship nomad fantasy (world building and story)

### World

The asteroid belt, far future. The belt is colonized and heavily engineered to support the operation of ADONAI, the system-spanning AI that governs humanity. The inner edge (close to the sun) is under tight ADONAI control - including his human army, the "Imperium". The Imperium is a quasi-religious authoritarian cult that have devoted themselves to protecting STEVE and carrying out its wishes.

The outer edge is more wild and free, and you'll increasingly encounter the weird, alien Kalgoor species. ADONAI hates the Kalgoor.

Asteroids are called "rocks", and the brave pilots who fly from rock-to-rock and form the backbone of the economy are called "rockhoppers".

Rocks are heavily modified from their natural state. Some rocks are icy, with compute modules embedded for cooling. Some are almost molten, with fission reactors embedded for power generation. Some are both.

### Story



You are the daughter of legendary rockhopper Eve. At the start of the game, she and you stop at a nondescript depot rock to refuel. But suddenly Imperium forces swarm in, destroy her ship, and adbduct her, accusing her of treason. Just before she is dragged away, she entrusts you with a data cube that she mysteriously calls "Agent X". She tells you to get the cube to the outer edge of teh belt, and that it's can't into Imperium hands no matter what. She tells you to seek out "Mr Mystery" - he'll know what to do. Then she's gone.

Suddenly you are alone on the ship depot rock. The manager, who understands what happened and is sympathetic to you, gives you a crappy starter ship. You take it and start hopping rocks to the edge, to find Mr Mystery. With "Agent X", and (at first, unbeknownst to you) a stowaway who is a very cute cat.

The world gets wilder and more dangerous as you approach the edge. You'll need to build you skills - and your ship - to cope with a wide range of unpredictable challenges.

### Game loop

Each run consists of visiting multiple ROCKS (levels). While on a ROCK you essentially function as a nomadic TRADER.

The basic flow is:

* You visit a OUTPOST and buy GOODS at a wholesale price
* You return to TOWN and sell the GOODS at a retail price
* Rinse and repeat!

There are wrinkles and variations, but that's the core of it. You are looking for high margin trading opportunities. This will largely depend on the type of GOODS you are transporting.  Risk/reward tradeoffs abound.

Your goal on each ROCK is to earn as much $ as possible before the Imperium figure out you're there, and dispatch a SQUAD to capture you. This creates tension - you want to stay on rock to earn $, but the longer you stay the more you risk the Imperium SQUAD arriving (which makes survival much less likely, as they will actively pursue and attack you). And the next rock will more challenging, so you better be ready.

### Levels

Each rock has:

* A single TOWN - this functions as the primary MARKET where you BUY and SELL GOODS
* Multiple OUTPOSTS - visit these to buy GOODS to sell in TOWN

Some OUTPOSTS are easy to get to, but tend to offer lower value GOODS. Some OUTPOSTS are much harder to get to (e.g., you must fly through dangerous, narrow, twisty corridors) but tend to offer much higher value GOODS.

### Ship

You ship has properties for:

* Fuel - flying consumes fuel. Don't run out! You can buy more in TOWN or at any OUTPOST. Unit = liters
* Cargo volume - determines how much GOODS you can fit. Unit = "cargo units" (an abstraction for storage volume)
* Weight - a heavier ship is harder to fly (newtonian physics) and consumes more fuel. Unit = kg
* Damage - when your ship reaches 100% damage, it explodes and your run is over. Unit = %

## Ship mods

Over the course of a run, you can find, purchase, and equip ship mods. They do things like:

* Reduce fuel consumption/increase fuel efficiency
* Increase cargo capacity
* Change the flight characteristics of your ship (e.g., more thrust, faster rotation)
* Reduce damage from collisions
* Add "autopilot" style safety enhancements (e.g., collision avoidance)
* Add defensive and offensive countermeasures, to fight off enemies and hazards (e.g., EMP devices, drones, etc.)
* Modify chance of detection of contraband (e.g., fake credentials)
* Unlock the ability to carry some types of "mission" goods (e.g., cryogenic storage bay)
* And so on...

Some mods add entirely new capabilities (e.g., "tractor beam", which adds a winch-like capability).

Mods are intended to make runs feel very different by meaningfully changing the nature of your ship and how it interacts with the levels.

### Goods

There are several categories of GOODS:

* Common - regular supplies that need to be transported. Bulky, and low margin.
* Premium - higher value supplies. Less bulky, and higher margin.
* Rare - precious stuff. Light, and very high margin. This is the good stuff!
* Contraband - Very light, and very high margin. But there's a chance it'll get confiscated when you attempt to sell it (and you'll get $0)
* Mission - can be light or heavy. Always extremely high margin. Must be delivered to a specific OUTPOST.
* Time critical - this is the same as a mission good, but must be delivered within a deadline (or value goes to $0)

### Services

* Fuel - you can buy fuel
* Repairs - you can repair your ship

TOWN is generally the cheapest place to buy SERVICES. But there may be special discounts at various OUTPOSTS (especially in response to MODS)
