# 7D2D-EntityRandomizer
A 7 Days to Die modlet generator that makes copies of Entities and randomizes them.

Currently generated Modlets:
Doughs-RandomizedEntities-For-a19-b173 -> Note, there are 4 copies of each vanilla zed in this one.
  There are 83 vanilla zombies in this game version so there are 332 random ones in the modlet

Notes:
- This is still in a *very experimental* stage of development.  If a zombie in a modlet here is really bad, please submit an issue here with the name of the zombie
  Zombies names start with doughsR<number>
  You'll have to be in debug mode to see the name
- The randomizer script taht generates the modlet is not yet published here as it is not ready for general use.
- The generated entities are "generally" tougher/faster than the vanilla zombies. 
  The randomizer was tweaked to make slow/weak zeds more unlikely. They can still happen though.
- The vanilla zombies are not removed from the game.  This just adds more copies of them
- There is no cosmetic/skinning changes to the vanilla zombies.  
  Other than speed/size/walk type, you can't tell what properties are different from the vanilla zeds.
- I will be generating modlets with the names of this pattern: Doughs-RandomizedEntities-For-<major version>-<build version>
  This is the "modlet" folder you put into the Mods folder.
  It is highly likely that if you don't use the modlet with the *exact* same version of your game, there may be issues (like no zombies spawning)
  
- At a high level, the randomizer script (currently) that generates the modlet attempts to do these things:
  1. Make a copy of the zombie entities in the game, giving them a new, unique name
  2. For each entity, randomizes these characteristics:
    WalkType
    Mass
    Weight
    Size
    LegCrawlerThreshold
    MoveSpeed
    MoveSpeedAggro
    ExperienceGain
    HealthMaxBase
  3. Loops, so more random copies can be made
  4. Write out an XML modlet containing the random entities, and adds them to all the entity groups they normally spawn in
  
  Also note: 
  The "randomness" is not completely random.  Each metric gets a different "randomness" varience, and some metrics are tweaked.
  For example:
  - If a zombie is a crawler type, the zomnie copy will not have a random walk type ( because a legless crawler can float in midair if its made to walk)
  - I have chosen to make the "amount of randomness" usually center around the existing metric, e.g. if HealthMaxBase = 200, the "randomness" is centered around 200 usiong a "percentage. Like 200 +/- 30%.
  - In some cases, where its not easy to get a metric, I have manually chosen a metric to center the randomness around.
  - Some zombies may be "too big" to fit through doors ;)  generally i tried to center size randomness so they will not be.
