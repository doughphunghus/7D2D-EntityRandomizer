# 7D2D-EntityRandomizer
A 7 Days to Die modlet generator that makes copies of Entities and randomizes them.
The script currently can randomize Zombie and animal entities.

The randomizer script that generates the modlet *is still very experimental* BUT modlets generated from it are being put here for use/comments to help polish the script for release.

### I highly recommend using one of the pre-generated modlets below before attempting to use the script!  These pre-genrated modlets have been tested to prove they work in game.

### WARNING: You can trash/break your computer if you are not familiar with properly installing perl (some OS's have a built in perl and you DO NOT want to modify or remove it)
Do not attempt to use the script unless you are familiar with installing perl, possibly installing build tools ( compiler, etc, maybe needed to install perl depending on your OS), intalling the script dependencies, virtualizing the perl environment (probably desired), and the 7D2D entity XML you will need to build a config file.

### WARNING: The script is not well tested. Do not try to run it until you have read and understood the documentation.
### WARNING: The script may not generate 7 Days to Die modlets that work properly with the game.

Documentation for how to install perl + dependencies on Mac, Windows, and Unix:\
See [wiki](https://github.com/doughphunghus/7D2D-EntityRandomizer/wiki)

Documentation for how to setup the config file/run the script:\
See [wiki](https://github.com/doughphunghus/7D2D-EntityRandomizer/wiki)

If you are using a pre-generated modlet below, load ONE of the modlets in the table below that's specific to your game version!

| Current Pre-generated Modlets  | Notes |
| ------------- | ------------- |
| Doughs-RandomizedEntities-For-a19.2_b3_all-entities | 5x cloning. There are 410 randomized vanilla zombies in the modlet, 60 hostile animals, 20 friendly animals |
| Doughs-RandomizedEntities-For-a19.1_b8_all-entities | 5x cloning. There are 410 randomized vanilla zombies in the modlet, 60 hostile animals, 20 friendly animals |
| Doughs-RandomizedEntities-For-a19_1_all-entities | ARCHIVED: ISSUES WITH MODLET.  DO NOT USE |
| Doughs-RandomizedEntities-For-a19_0_all-entities | 5x cloning. There are 410 randomized vanilla zombies in the modlet, 60 hostile animals, 20 friendly animals |
| Doughs-RandomizedEntities-For-a19_0 | 4x cloning. There are 332 randomized vanilla zombies in the modlet |
| Doughs-RandomizedEntities-For-a19_b180_all-entities | 5x cloning. There are 410 randomized vanilla zombies in the modlet, 60 hostile animals, 20 friendly animals |
| Doughs-RandomizedEntities-For-a19-b180 | 4x cloning. There are 332 randomized vanilla zombies in the modlet |
| Doughs-RandomizedEntities-For-a19-b178 | 4x cloning. There are 332 randomized vanilla zombies in the modlet |
| Doughs-RandomizedEntities-For-a19-b177 | 4x cloning. There are 332 randomized vanilla zombies in the modlet |
| Doughs-RandomizedEntities-For-a19-b173 | 4x cloning. There are 332 randomized vanilla zombies in the modlet |

#### Notes:
- This is still in a *very experimental* stage of development.  
  If a zombie in a pre-generated modlet here is really bad, please submit an issue here with the modlet name and name of the zombie. Zombies names start with doughsR<number>. You'll have to be in debug mode in the script (or also if viewing teh zombie in the game) to see the name.
- The pre-generated modlet entities are "generally" tougher/faster than the vanilla zombies.
  The randomizer was tweaked to make slow/weak zeds more unlikely. They can still happen though.
- The vanilla zombies are not removed from the game.  This just adds more copies of them
- There is no cosmetic/skinning changes to the vanilla zombies. They all look the same, on purpose ;)
  Other than a non vanilla speed, size or walk type, you can't tell what properties are different from the vanilla zeds as they approach
- I will be generating modlets with the names of this pattern: Doughs-RandomizedEntities-For-<major version>-<build version>
  This is the "modlet" folder you put into the Mods folder.
  It is highly likely that if you don't use the modlet with the *exact* same version of your game, there may be issues (like no zombies spawning)

- At a high level, the randomizer script (currently) that generates the modlet attempts to do these things:
  1. Make a copy of the zombie entities in the game, giving them a new, unique name
  2. For each entity, randomizes characteristics as set in the config file.
  3. Based on the config file settings, loops and runs again, so more random copies can be made of each zed.  
  4. Writes out an XML modlet containing all the random entities, and adds them to all the entity groups they normally spawn in.

  Also note, for teh pre-generated modlets:
  The "randomness" is not completely random.  Each metric gets a different "randomness" varience, and some metrics are tweaked.
  For example:
  - If a zombie is a crawler type, the zomnie copy will not have a random walk type ( because a legless crawler can float in midair if its made to walk)

  - In some cases, where its not easy to get a metric, I have manually chosen a metric to center the randomness around.

  - Some zombies may be "too big" to fit through doors ;)  generally I tried to center size randomness so they will not be, but it may happen
