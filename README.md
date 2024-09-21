# 2024-09-21: Deprecating project. No future updates.

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

If you are using a pre-generated modlet below, load the modlets in the table below that's specific to your game version!  Only load one "entity type" (e.g. don't load 2 zombie ones together, if more than 1 choice exists)

(Recommend loading an enemy health bar viewer modlet to see the names!)

| Current Pre-generated Modlets | Notes |
| ------------- | ------------- |
| Doughs-RandEnts_For_a20.5-b2_vanilla-enemy-animals-only-600-clones | 600 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a20.5-b2_vanilla-friendly-animals-only-400-clones | 400 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a20.5-b2_vanilla-zeds-only-3440-clones | 3440 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a20.5-b2_vanilla-enemy-animals-only-4300-clones | 4300 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a19.5-b50_vanilla-enemy-animals-only-600-clones | 600 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a19.5-b50_vanilla-friendly-animals-only-400-clones | 400 clones of vanilla friendly/wild animals, with localization |
| Doughs-RandEnts_For_a19.5-b50_vanilla-zeds-only-4920-clones | 4920 clones of vanilla zombies|
| Doughs-RandEnts_For_a19.4-b7_vanilla-enemy-animals-only-600-clones | 600 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a19.4-b7_vanilla-friendly-animals-only-400-clones | 400 clones of vanilla friendly/wild animals, with localization|
| Doughs-RandEnts_For_a19.4-b7_vanilla-zeds-only-4920-clones | 4920 clones of vanilla zombies |
| Doughs-RandEnts_For_a19.3-b6_vanilla-enemy-animals-only-600-clones | 600 clones of vanilla zombie animals, with localization  |
| Doughs-RandEnts_For_a19.3-b6_vanilla-friendly-animals-only-400-clones | 400 clones of vanilla friendly/wild animals, with localization |
| Doughs-RandEnts_For_a19.3-b6_vanilla-zeds-only-4920-clones | 4920 clones of vanilla zombies, with localization |
| Doughs-RandEnts_For_a19.2-b4_vanilla-enemy-animals-only-600-clones | 600 clones of vanilla zombie animals, with localization |
| Doughs-RandEnts_For_a19.2-b4_vanilla-friendly-animals-only-400-clones | 400 clones of vanilla friendly/wild animals, with localization|
| Doughs-RandEnts_For_a19.2-b4_vanilla-zeds-only-4920-clones | 4920 clones of vanilla zombies, with localization (may not be server side safe! Possible a file is too large and will not transfer. Looks like TFP fixed it after this version.) |
| Doughs-RandEnts_For_a19.2-b4_vanilla-zeds-only-492-clones | 492 clones of vanilla zombies |

| Archived Pre-generated Modlets  | Notes |
| ------------- | ------------- |
|See "Archived" Folder | |

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

  Also note, for the pre-generated modlets:
  The "randomness" is not completely random.  Each metric gets a different "randomness" varience, and some metrics are tweaked.
  For example:
  - If a zombie is a crawler type, the zomnie copy will not have a random walk type ( because a legless crawler can float in midair if its made to walk)

  - In some cases, where its not easy to get a metric, I have manually chosen a metric to center the randomness around.

  - Some zombies may be "too big" to fit through doors ;)  generally I tried to center size randomness so they will not be, but it may happen

# Config File Argument Documentation (VERY WIP, SUBJECT TO CHANGE)
Once perl and dependencies are installed, the script is run like so:
Open a shell, cd to the project directory, and run (example)
perl ./randomizer.pl --config-file ./config_example_TEST_all_entities.json

where:
- --config-file = REQUIRED. The JSON formatted config file to use.

See the example JSON config files included in the project root dir as examples.
The config file keys/values are:
#### Values in {}, the "Top level" config values.
- "game_install_dir":
  Directory where 7 Days To Die is installed.
  Example value: "<some path on your machine>/Steam/steamapps/common/7 Days To Die"

- "game_saves_dir":
  Directory where 7 Days To Die local save game files are installed.
  Example value: "<some path on your machine>/7DaysToDie/Saves"

- "use_save_game":""
  Advanced setting!. To parse the XML files in a save game folder instead of the game_install_dir
  Leave this empty unless you know how to use this.
  Example value: "" <- Do not use a save game for XML. Use installed game XML
  Example value: "Navezgane/<some_save_game_name>"

- "game_version":"a19.2-b4"
  The version of the game, as seen on the top right hand corner when it runs
  Note: Put a dash "-" between the version and the build. The dash is not required, but this info is used to build the This is used to build the name of the toplevel mod folder and the dash makes it look nice.
  Example value: "a19.2-b4"

- "author":
  This value get put into the ModInfo.xml file of the generated mod.
  Example value: "Doughphunghus"

- "modlet_name_prefix":
  This is used to build the beginning of the name of the toplevel mod folder. Keep it as short as possible. A good practice is to put your name (or an abbreviation of it) as the first word.
  Note: Put a dash "-" between any words instead of spaces/underlines. This info is used to build the name of the mod and it makes it look nice.
  Example value: "Doughs-RandEnts"

- "modlet_name_tag":
  This is used to build the end part of the the name of the toplevel mod folder.  A good practice would be to make this very descriptive as to what the generation is for or contains.
  Note: Put a dash "-" between any words instead of spaces/underlines. This info is used to build the name of the mod and it makes it look nice.
  Example value: "vanilla-enemy-animals-only-600-clones"

- "log_level":
  This controls the level of logging when the script runs, and can be useful for debugging.
  Allowed values:
  0 = Minimal logging (only STDOUT/STDERR messages which are not caught)
  1 = ERROR Messages only
  2 = ERROR and INFO Messages
  3 = ERROR and INFO and DEBUG Messages
  Example value: "2"

- "config_file_format":
  Advanced setting!. Do not change unless you know how to use this.
  This is the config file format "version". If the version of script you are running
  is older its possible it cannot parse a version of the config file you are using.
  This was put in place in case I make config file format breaking changes, and have older config files I try to use.  If I do this, the script will refuse to process the file based on the version mismatch.
  Example value: "v1"

- "unique_entity_prefix"
  This is used to prefix the internal names of the cloned entity names in the XML
  Note: Keep it as short as possible.
  This is because a unique key is needed so all cloned entities are unique, but so you can also (should you change this) run different generated cloned modlets either by yourself or others (using the same script, different config files) side by side.
  Note: A good practice would be to put your name or an abbreviation of it in this.
  Note: This is part of the name you can see when using the F6 entity spawner in the games debug mode.  This also makes your cloned entities searchable in that tool.
  Example value: "DoughsR"

- "ignore_entity_list":
  This is a dictionary/hash of values :) but is supposed to contain any entities you do not want to clone, globally (no matter what Type/Class they are or inherit from). This can be empty or contain key/values. Use the value to document the reason the ehtity is being ignored.
  Use the internal XML class name of the entity!
  Example value: {} <- Do not ignore any entities
  Example value:
  {
    "animalDoe":"I do not want any clones of this",
    "animalZombieVulture":"I do not want any clones of this"
  }

- "only_allow_these_entities_list":
  This is a dictionary/hash of values :) but is supposed to contain any entities you ONLY
  want clones of.  It is just like ignore_entity_list, but only the entities in the lise are cloned, everything else is ignored.  This is good when you want a lot of clones of a specific zombie/animal, or have a special config file to randomize just this entity, seperate from others. Another use woudl be to randomize entities from mods (this may or may not work well!, and you have to use the use_save_game config setting to point the script to a saved, modded game to read the modded entities from.
  Example value: {} <- Do not ignore any entities
  Example value:
  {
    "animalDoe":"I do not want any clones of this",
    "animalZombieVulture":"I do not want any clones of this"
  }

- "enable_localization":
  The script can generate a Localization.txt file for the mod it generates from special files (not documented yet or supplied with this code, but you can find the names/locations in the script if you want to supply your own. The Localization files are just text files with a single word on each line. If the files are supplied, the script generates randomized names for each cloned entity by choosing random words from each localization file).  If you do not have localization files, obviously set this to 0
  Allowed values:
  0 = Do not use Localization files/generate localization
  1 = Do use Localization files/generate localization
  Example value:"1"

- "ConfigDefaults":
  This section defines all of the "default master filters" used in the ConfigEntityEnemyAnimal,ConfigEntityFriendlyAnimal,ConfigEntityZombie sections below.
  { <Contents of Section Documented below> }

- "ConfigEntityEnemyAnimal":
  This section defines all of the default "filters" for Enemy Animal Entities
  { <Contents of Section Documented below> }

- "ConfigEntityFriendlyAnimal":
  This section defines all of the default "filters" for Friendly Animal Entities
  { <Contents of Section Documented below> }

- "ConfigEntityZombie":
  This section defines all of the default "filters" for Zombie Entities
  { <Contents of Section Documented below> }

#### Values in "ConfigDefaults"
TBD!  This is a complicated section and requires some thought to document


#### Values in "ConfigEntityEnemyAnimal","ConfigEntityFriendlyAnimal", and "ConfigEntityZombie"
All of these sections behave the same and can be configured using the same methods, so I will document only how to configure one of the sections. ConfigEntityZombie will be the example section used, so to do the others simply substitute the class/entity names of the appropriate entity/class instead of Zombies.

TBD!  This is a complicated section and requires some thought to document
