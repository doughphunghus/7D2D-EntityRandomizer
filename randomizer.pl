use strict;
use warnings;

# TODO: Declare methods
use XML::LibXML; # Parsing 7D2D config files
use JSON::Parse qw(json_file_to_perl); # Parsing script config file
use POSIX; # For math functions TODO: look at POSIX docs for how to fix its exports: https://perldoc.perl.org/POSIX.html
use Getopt::Long; # For command line arguments
use FindBin qw($Bin); # For finding script dir. $Bin contains script dir
# use File::Basename qw(dirname); #

# TODO: MaxView angle + LookAt Angle = set the same?
=pod
DOCS:

 # loop through entityclasses, find Z's
 #  make new Z object from it
 #  change attributes, randomly, unique + numbered name
 #  (generate modlet XML)
 #  write modlet entityclasses xml for new Z
 #    loop through entitygroups, find Z modified from
 #    write modlet entitygroups xml
 #

Run:
perl ./randomizer.pl --config_file 'config_example.json'


=cut
# TODO: Attach to Randomize_MassAndWeightAndSizeScale better
# <property name="DeadBodyHitPoints" value="200"/>
# <property name="SwimSpeed" value="1.2"/>
# <property name="SwimStrokeRate" value="1.1,1.5"/>

# TODO: Special
# <property name="JumpDelay" value=".1"/>
# <property name="JumpMaxDistance" value="6, 7"/>

# Globals with hardcoded defaults/overides
my $UNIQUE_NUMBER = 1; # for generating unique entity names
my $POPULATE_ENTITY_TYPE_LOOKUP_MAX_LOOPS = 2; # Increase number if entitiy classed nest deeply
my $TMP_LOOP_COUNTER = 0;
my $LOG_LEVEL = 3; # Default to the most verbose if value set is invalid.
my $PROJECT_ROOT_DIR = $Bin;
my @COMPATIBLE_CONFIG_FILE_FORMATS = ('v0','v1');

# Global file handles
my $ENTITIES_FILE;
my $ENTITYGROUPS_FILE;

# Misc globals
my $ENTITY_CONFIG_KEY;
my $CONFIG_FILE_NAME; # File Name only
my $CONFIGS; # Hash of configs read from config file
my %ENTITY_TYPE_LOOKUP; # auto-popupates EntityName => Type e.g. $ENTITY_TYPE_LOOKUP{$entity_name} = $extends_type_name
my %TYPE_ENTITY_LOOKUP;  # auto-popupates Type => EntityName
my %ENTITY_GROUP_LOOKUP; # group => aray of zeds to add
my %NEW_ENTITIES; # name => xml_node
my $ENTITYCLASSES_DOM;
my $ENTITYGROUPS_DOM;
my $TOTAL_ZED_ENTITIES_FOUND = 0;
my $TOTAL_ZED_ENTITIES_GENERATED = 0;
my $TOTAL_HOSTILE_ANIMAL_ENTITIES_FOUND = 0;
my $TOTAL_HOSTILE_ANIMAL_ENTITIES_GENERATED = 0;
my $TOTAL_FRIENDLY_ANIMAL_ENTITIES_FOUND = 0;
my $TOTAL_FRIENDLY_ANIMAL_ENTITIES_GENERATED = 0;

# TODO: put this in configs
my %NEW_ENTITY_FILTER_LIST = ( # don't ever clone these nodes. Hardcode obvious here
  zombieTemplateMale => "Do not clone this as its a template entity",
  animalTemplateTimid => "Do not clone this as its a template entity",
  animalTemplateHostile => "Do not clone this as its a template entity",
);

sub LogIt {
  my($sev,$msg) = @_;
  print $sev.':'.$msg."\n";
  return;
}
sub LogError {
  my($msg) = @_;
  LogIt('ERROR',$msg) if($LOG_LEVEL >= 1);
  return;
}
sub LogInfo {
  my($msg) = @_;
  LogIt('INFO',$msg) if($LOG_LEVEL >= 2);
  return;
}
sub LogDebug {
  my($msg) = @_;
  LogIt('DEBUG',$msg) if($LOG_LEVEL >= 3);
  return;
}
sub CheckDirExistsOrExit {
  my($dir,$label) = @_;
  $label = 'This' if ! defined $label;
  if(! -d $dir) {
    LogError('Exiting because '.$label.' directory does not exist: '.$dir);
    exit;
  }
}
sub CheckFileExistsOrExit {
  my($file,$label) = @_;
  $label = 'This' if ! defined $label;
  if(! -f $file) {
    LogError('Exiting because '.$label.' file does not exist: '.$file);
    exit;
  }
}
sub CheckConfigExistsOrExit {
  my($config,$label) = @_;
  $label = 'This' if ! defined $label;
  if(! defined $config) {
    LogError('Exiting because '.$label.' required argument found:'.$label);
    exit;
  }
}

sub LoadConfigs {
  my($project_root_dir,$config_file_name) = @_;
  my $config_file = $project_root_dir.'/'.$config_file_name;
  my $configs;

  CheckFileExistsOrExit($config_file,'config_file');
  LogInfo('Parsing config file: '.$config_file);

  eval {
    $configs = json_file_to_perl($config_file);
  };
  if ($@) {
    LogError('JSON in malformed in config file');
    LogError($@);
    exit;
  }
  return $configs;
}

sub PopulateEntityTypeLookup {
  # Loop through Entities, and create the %ENTITY_TYPE_LOOKUP table
  LogInfo('########## Populating Entity -> Type Lookup table ##########');
  my $lookup_type_failures = 0;

  foreach my $entity ($ENTITYCLASSES_DOM->findnodes('//entity_classes/entity_class')) {

    my $entity_name = $entity->findnodes('@name');
    LogDebug('Found entity Name: '.$entity_name);

    # First, see what type it is
    my $found_type = 0;

    # See if the entity is an extended type, and we know about the extended type
    # Note: this is more common? so check it first

    my $entity_extends_name = $entity->findnodes('@extends');

    if($entity_extends_name) {
      LogDebug($entity_name.' EXTENDS: '.$entity_extends_name);
      if(exists $ENTITY_TYPE_LOOKUP{$entity_extends_name}) {
        $found_type = 1;
        my $extends_type_name = $ENTITY_TYPE_LOOKUP{$entity_extends_name};
        $ENTITY_TYPE_LOOKUP{$entity_name} = $extends_type_name;
      }
      else {
        LogError('Lookup for '.$entity_name.' failed');
      }
    }

    #if($found_type == 0) { # See if the entity is a specific type (could be)
    #  foreach my $type ($entity->findnodes('./property[@name=\'EntityType\']/@value')) {
    #    $found_type = 1;
    #    my $type_name = $type->to_literal();
    #    print "$entity_name = Entity Type:$type_name\n";
    #
    #    $ENTITY_TYPE_LOOKUP{$entity_name} = $type_name;
    #  }
    #}

    if($found_type == 0) { # See if the entity is a specific class (could be)
      foreach my $type ($entity->findnodes('./property[@name=\'Class\']/@value')) {
        $found_type = 1;
        my $type_name = $type->to_literal();
        LogDebug($entity_name.' = Class:'.$type_name);
        $ENTITY_TYPE_LOOKUP{$entity_name} = $type_name;
      }
    }

    if($found_type == 0) {
      $lookup_type_failures = 1;
      LogError('lookup_type_failure for entity: '.$entity_name);
    }
  }

  return $lookup_type_failures;

}

sub PopulateTypeEntityLookup {
  LogInfo('########## Populating Type -> Entity Lookup table ##########');
  # build the reverse lookup %TYPE_ENTITY_LOOKUP
  foreach my $entity_type_lookup_key (sort keys %ENTITY_TYPE_LOOKUP) {
    LogDebug($entity_type_lookup_key.' -> '.$ENTITY_TYPE_LOOKUP{$entity_type_lookup_key});
    # Shove them all in! Prepopulate the keys to empty arrays to make like easier below
    $TYPE_ENTITY_LOOKUP{$ENTITY_TYPE_LOOKUP{$entity_type_lookup_key}} = [];
  }

  my %entity_type_lookup_tmp = %ENTITY_TYPE_LOOKUP;

  while (my ($entity,$type) = each %entity_type_lookup_tmp) {
    LogDebug('Saving '.$entity.' -> '.$type);
    push @{$TYPE_ENTITY_LOOKUP{$type}},$entity;
  }
  return;
}

sub GenerateNewEntityNameString {
  my ($name) = @_;
  $UNIQUE_NUMBER++;
  return $CONFIGS->{'unique_entity_prefix'}.$UNIQUE_NUMBER.'_'.$name;
}

sub GenerateNewEntityFromExistingName {
  # Finds, copies, and extends the zed asked for
  my($name) = @_;
  LogDebug('########## GenerateNewEntityFromExistingName ##########');
  LogDebug('Looking for: '.$name);
  my $new_zed;
  my $new_name;
  foreach my $entity ($ENTITYCLASSES_DOM->findnodes('//entity_classes/entity_class[@name=\''.$name.'\']')) {
    my $entity_name = $entity->findnodes('@name');
    LogDebug('Found: '.$entity_name);

    # Filter some out we don't want!
    if(exists $NEW_ENTITY_FILTER_LIST{$entity_name}) {
      LogDebug('Zed filter list matched. Filtering out: '.$entity_name.' because: '.$NEW_ENTITY_FILTER_LIST{$entity_name});
      return;
    }

    $new_zed = $entity->cloneNode(1); # deep clone, all nodes below

    $new_name = GenerateNewEntityNameString($name);
    $new_zed->setAttribute(q|name|,$new_name);  # Not changing build.xml

    # Extend from parent
    my $entity_extends_name = $entity->findnodes('@extends');
    if(! $entity_extends_name) { # Not already extending. Have to add!
      $new_zed->setAttribute(q|extends|,$entity_name);
    }
    else {
      # Already extends. nothing to do
    }
  }

  return ($new_name,$new_zed);
}

sub ModletGen_Start { # Just use Globals :)
  LogDebug('########## ModletGen_Start ##########');
  # Required Folders
  my $modlet_config_dir = $CONFIGS->{'modlet_gen_dir'}.'/Config';

  if(! -d $modlet_config_dir) {
    LogDebug('Generating: '.$modlet_config_dir);
    unless(mkdir $modlet_config_dir) {
       LogError('Exiting. Unable to create folder: '.$modlet_config_dir);
       exit;
    }
  }

  # Misc required files
  my $modinfo_file = $CONFIGS->{'modlet_gen_dir'}.'/ModInfo.xml';
  LogDebug('Generating: '.$modinfo_file);
  #if(! -f $modinfo_file) {
    open(my $MODINFO,'>',$modinfo_file) or die "Unable to open $modinfo_file\n";
      print $MODINFO '<?xml version="1.0" encoding="UTF-8" ?>'."\n";
      print $MODINFO '<xml>'."\n";
      print $MODINFO '  <ModInfo>'."\n";
      print $MODINFO '    <Name value="'.$CONFIGS->{'modlet_name'}.'" />'."\n";
      print $MODINFO '    <Description value="Generated random entities from existing ones" />'."\n";
      print $MODINFO '    <Author value="Doughphunghus" />'."\n";
      print $MODINFO '    <Version value="1.0.0" />'."\n";
      print $MODINFO '    <Website value="https://github.com/doughphunghus" />'."\n";
      print $MODINFO '  </ModInfo>'."\n";
      print $MODINFO '</xml>'."\n";
    close($MODINFO);
  #}

  # Localization file
  #my $localization_xml_file = $modlet_config_dir.'/Localization.txt';
  #print "Generating: $localization_xml_file\n";
  #open($LOCALIZATION_FILE,'>',$localization_xml_file) or die "Unable to open $localization_xml_file\n";
  # TODO

  # Entities file
  my $entities_xml_file = $modlet_config_dir.'/entityclasses.xml';
  LogDebug('Starting Entities file: '.$entities_xml_file);
  open($ENTITIES_FILE,'>',$entities_xml_file) or die "Unable to open $entities_xml_file\n";
  print $ENTITIES_FILE '<Doughs>'."\n";
  print $ENTITIES_FILE '<append xpath="/entity_classes">'."\n";

  # EntityGroups file
  my $entitygroups_xml_file = $modlet_config_dir.'/entitygroups.xml';
  LogDebug('Starting EntityGroups file: '.$entitygroups_xml_file);
  open($ENTITYGROUPS_FILE,'>',$entitygroups_xml_file) or die "Unable to open $entitygroups_xml_file\n";
  print $ENTITYGROUPS_FILE '<Doughs>'."\n";

  return;
}

sub ModletGen_Finish { # Just use Globals :)
  # Localization file
  # TODO
  #close($LOCALIZATION_FILE);

  # Entities file
  LogDebug('Completing: Entities file.');
  print $ENTITIES_FILE '</append>'."\n";
  print $ENTITIES_FILE '</Doughs>'."\n";
  close($ENTITIES_FILE);

  # EntityGroups file
  LogDebug('Completing: EntityGroups file.');
  print $ENTITYGROUPS_FILE '</Doughs>'."\n";
  close($ENTITYGROUPS_FILE);
  return;
}

sub ModletGen_AddZedToEntitiesOverride {
  my ($zed_node) = @_;
  # TODO
  LogDebug('########## ModletGen_AddZedToEntitiesOverride ##########');
  print $ENTITIES_FILE $zed_node->toString();
  print $ENTITIES_FILE "\n";
  print $ENTITIES_FILE "\n"; # Nice seperation
  return;
}
sub ModletGen_AddZedToEntityGroupsLookup {
  my ($zed_name,$is_from_zed) = @_;
  LogDebug('########## ModletGen_AddZedToEntityGroupsLookup zed_name: '.$zed_name.' is_from_zed:'.$is_from_zed.'##########');
  # TODO
  # Find the groups its in
  foreach my $entity_group ($ENTITYGROUPS_DOM->findnodes('//entitygroups/entitygroup')) {
    my $entity_group_name = $entity_group->findnodes('@name');

    # now search the group for the zed
    foreach my $entity ($entity_group->findnodes('./entity[@name=\''.$is_from_zed.'\']')) {
      # ok, we found a node. ummm...clone it, update the name, make the override
      my $new_zed_entity = $entity->cloneNode(1); # deep clone, all nodes below
      $new_zed_entity->setAttribute(q|name|,$zed_name);  # Not changing build.xml

      my $xmlstring = $new_zed_entity->toString();

      if(exists $ENTITY_GROUP_LOOKUP{$entity_group_name}) {
        push @{ $ENTITY_GROUP_LOOKUP{$entity_group_name} }, $xmlstring;
      }
      else {
        push(@{ $ENTITY_GROUP_LOOKUP{$entity_group_name} }, $xmlstring);
      }

    }

  }

  return;
}

sub ModletGen_AddZedsToEntityGroupsFile {
  LogDebug('########## ModletGen_AddZedsToEntityGroupsFile ##########');
  my @entity_groups = sort keys %ENTITY_GROUP_LOOKUP;
  foreach my $entity_group (@entity_groups){
    #next if $entity_group =~ m/GroupGS/; # ignore game stages. Waaaaaaay too many. slows game load time significantly
    #next if $entity_group =~ m/StageGS/;
    LogDebug('ModletGen_AddZedsToEntityGroupsFile ENTITY GROUP: '.$entity_group);
    my $xml_strings_arayref = $ENTITY_GROUP_LOOKUP{$entity_group};

    print $ENTITYGROUPS_FILE '<append xpath="/entitygroups/entitygroup[@name=\''.$entity_group.'\']">'."\n";

    foreach my $xmlstring (@{$xml_strings_arayref}) {
      LogDebug('Adding: '.$xmlstring);
      print $ENTITYGROUPS_FILE "\t".$xmlstring."\n"; # Nice spacing
    }
    print $ENTITYGROUPS_FILE '</append>'."\n";
  }

  return;
}

sub Determine_NumDecimals {
  my($num) = @_;
  # returns count of decimal places
  my $dec_cnt = 0;
  my (undef,$num_dec) = split /\./, $num;
  if(defined $num_dec) {
    $dec_cnt = length($num_dec);
  }
  return $dec_cnt;
}
sub GenRandomNumberFromRange {
  my($low,$high) = @_;
  # Takes a high and low *positive or negative* numbers,
  # Returns a random number between them with x decimal places.
  # Decimal places are determined by the highest decimal places passed in
  # to either low or high

  my $num_decimals = 0;
  # TODO: handle error better
  if($high < $low) {
    LogError('GenRandomNumberFromRange: high: '.$high.' < low: '.$low);
    exit;
  }

  # Get how many decimals are passed
  my $low_dec_cnt = Determine_NumDecimals($low);
  my $high_dec_cnt = Determine_NumDecimals($high);

  if($low_dec_cnt > $high_dec_cnt) {
    $num_decimals = $low_dec_cnt;
  }
  else {
    if($high_dec_cnt > $num_decimals) {
       $num_decimals = $high_dec_cnt;
    }
    # else = and is 0
  }

  # Subtract low from high to get single float number; e.g. 1.955 = 2.000 - 0.050
  my $diff = $high - $low;

  my $rand = rand($diff); # returns a random integer 0-num; e.g. 34

  # # Divide and Add rand to low
  my $new_rand = $low + $rand;

  # Force to x decimal places; e.g. .346. 0 = no decimals
  $new_rand = sprintf("%.".$num_decimals."f", $new_rand);
  return $new_rand;

}

sub Randomize_PercentAroundGivenNumber { # well , no 0
  my($num,$pct,$num_decimals) = @_; # num, x (percent = whole number)
  # print "Randomize_PercentAroundGivenNumber: $num -> $round_type\n";
  # TODO: Sems like we have numbers that have spaces prededing them
  # AND numbers that are arrays? "0,0"
  my $rand_pct_whole = int(rand($pct)); # 0 -> pct
  $rand_pct_whole++; # 1 -> pct (don't allow 0)
  my $rand_pct_float = $rand_pct_whole/100; # decimal

  my $rand_pct_diff_float = $rand_pct_float * $num; # have +pct number

  my $new_num_float = $num + $rand_pct_diff_float;
  if(int(floor(rand(1)))) { # 1 or 0.....
    $new_num_float = $num - $rand_pct_diff_float;
  }

  # ok, we finally have the ran +/- percent.  How to round?
  $new_num_float = sprintf("%.".$num_decimals."f", $new_num_float);

  # print "Randomize_PercentAroundGivenNumber: $num -> $round_type = $new_num_float\n";
  return $new_num_float;

}

sub SetOrCreate_GenericPropertyAndVal {
  # OK.  This looks for a property.  If found, then sets it to the $val
  # BUT if it cannot find a property, creates it and sets to $val

  my($zed,$property_name,$val) = @_;
  my $found = 0;
  # print "SetOrCreate_GenericPropertyAndVal: $property_name -> $val\n";
  foreach my $node ($zed->findnodes('./property[@name=\''.$property_name.'\']')) {
    $found = 1;
    $node->setAttribute(q|value|,$val);
  }

  # ok, we did NOT find a $property_name attribute. gotta make a new one
  if(!$found) {
    my $property = XML::LibXML::Element->new( 'property' );
    $property->setAttribute(q|name|,$property_name);
    $property->setAttribute(q|value|,$val);
    $zed->addChild( $property );
  }

  return $zed;
}

sub Randomize_SetOrCreate_FromRangeGenericPropertyAndVal {
  my($zed,$property,$cfg) = @_;
  my $low = $cfg->{'low'};
  my $high = $cfg->{'high'};

  # <property name="DismemberMultiplierArms" value=".7"/> <!-- Feral --> 1 = standard
  #print "Randomize_SetOrCreate_FromRangeGenericPropertyAndVal: $property,$low,$high\n";
  my $new_val = GenRandomNumberFromRange($low,$high);
  $zed = SetOrCreate_GenericPropertyAndVal($zed,$property,$new_val);
  #print "Randomize_SetOrCreate_FromRangeGenericPropertyAndVal: $property,$new_val\n";
  return $zed;
}

sub Randomize_SetOrCreate_RangedGenericPropertyAndVal {
  my($zed,$property,$cfg) = @_;
  my $low1 = $cfg->{'low1'};
  my $low2 = $cfg->{'low2'};
  my $high1 = $cfg->{'high1'};
  my $high2 = $cfg->{'high2'};

  # All 1 decimal values
  # $low2 and $high1 shoudl probably not cross/touch, e.g. 3.4,3.5 and not 3.7,3.5
  # <property name="JumpMaxDistance" value="2.8, 3.9"/>
  # print "Randomize_SetOrCreate_RangedGenericPropertyAndVal: $property,$low1,$low2,$high1,$high2\n";
  my $new_low_val = GenRandomNumberFromRange($low1,$low2);
  my $new_high_val = GenRandomNumberFromRange($high1,$high2);
  my $new_val = $new_low_val.','.$new_high_val; # Its a range itself
  $zed = SetOrCreate_GenericPropertyAndVal($zed,$property,$new_val);
  return $zed;
}

sub Randomize_SetOrCreate_GenericPropertyAndVal {
  my($zed,$property_name,$cfg) = @_;
  my $pct_random = $cfg->{'pct_random_int'};
  my $val_if_empty = $cfg->{'default'};

  # OK.  This looks for a property.  If found, then randomizes the
  # value around that by +/- $pct_random
  # BUT if it cannot find a property, uses $val_if_empty
  # and inserts a new property.  Likely just easier for now than trying to
  # traverse up a class inheritance tree I don't control
  # Can also just start averaging up the vals to get a  decent $val_if_empty?
  # NOTE: Determines decimals to use for new property based on what it finds
  # if value exists, or what is used for the default
  my $found = 0;
  foreach my $node ($zed->findnodes('./property[@name=\''.$property_name.'\']')) {
    $found = 1;
    my $val = $node->getAttribute('value');

    my $new_val = Randomize_PercentAroundGivenNumber($val,$pct_random,Determine_NumDecimals($val));
    $node->setAttribute(q|value|,$new_val); # random this
  }

  # ok, we did NOT find a "size" attribute
  if(!$found) { # gotta make a new one
    my $property = XML::LibXML::Element->new( 'property' );
    $property->setAttribute(q|name|,$property_name);
    my $new_val = Randomize_PercentAroundGivenNumber($val_if_empty,$pct_random,Determine_NumDecimals($val_if_empty));
    $property->setAttribute(q|value|,$new_val);
    $zed->addChild( $property );
  }

  return $zed;
}

sub Randomize_RGB_ColorsAsString { # May need this later, for other properties/things
  my $r = floor(rand(255));
  my $g = floor(rand(255));
  my $b = floor(rand(255));
  return $r.','.$g.','.$b;
}

sub Randomize_SetOnly_NoCreate_TintMaterial {
  my($zed) = @_;
  # OK. TimtMaterial is an RGB property
  # Can be TintMaterial1, TintMaterial2, TintMaterial3
  # <property name="TintMaterial2" value="36,38,45"/>
  my $found = 0;

  foreach my $n (1..3) {
    foreach my $node ($zed->findnodes('./property[@name=\'TintMaterial'.$n.'\']')) {
      my $new_val = Randomize_RGB_ColorsAsString();
      $node->setAttribute(q|value|,$new_val); # random this
    }
  }

  return $zed;
}

sub Randomize_WalkType { # <property name="WalkType" value="3"/>
  # 4 = crawler -> don't make crawlers walk. The legless one floats at you like a ghost ;)
  # zombieSteveCrawlerFeral = WalkType not set, its inherited...sigh
  my($zed) = @_;

  # TODO: make variance configurable
  my $rand_walk_type = rand(9); # make 1 less, as returns 0-num # TODO: validate 9 is "real"
  $rand_walk_type = floor($rand_walk_type++);
  $rand_walk_type = 1 if $rand_walk_type == 0; # 0 not valid

  my $found = 0;
  foreach my $walk_type ($zed->findnodes('./property[@name=\'WalkType\']')) {
    #print "DEBUG: ".$walk_type->toString();
    my $val = $walk_type->getAttribute('value');
    if($val != 4) {
      $walk_type->setAttribute(q|value|,$rand_walk_type); # random this
    }
    $found++;
  }

  if(!$found) { # gotta make a new one
    my $property = XML::LibXML::Element->new( 'property' );
    $property->setAttribute(q|name|,'WalkType');
    $property->setAttribute(q|value|,$rand_walk_type);
    $zed->addChild( $property );
  }

  return $zed;
}

sub Randomize_MassAndWeightAndSizeScale {
  # <property name="Mass" value="170"/>. Cheerleader = 110.  it seems to be in "lbs"
  # weight seems to be 1/2 mass (ish). huh
  my($zed,$cfg) = @_;
  my $low_pct = $cfg->{'low_pct_int'};
  my $high_pct = $cfg->{'high_pct_int'};
  my $mass_default = $cfg->{'mass_default_int'};
  my $sizescale_default = $cfg->{'sizescale_default_two_dec'};

  my $rand_change_pct = GenRandomNumberFromRange($low_pct,$high_pct);
  $zed = Randomize_SetOrCreate_GenericPropertyAndVal($zed,
    'Mass',
    { pct_random_int => $rand_change_pct, default => $mass_default}
  );

  my $weight_default = int($mass_default/2);
  $zed = Randomize_SetOrCreate_GenericPropertyAndVal($zed,
    'Weight',
    { pct_random_int => $rand_change_pct, default => $weight_default }
  ); # $pct_random,$val_if_empty

  # <property name="SizeScale" value="1.08"/>
  # Make them slightly smaller on avg because larger zeds cant go through doors ;). 1 = normal size
  $rand_change_pct = Randomize_PercentAroundGivenNumber($sizescale_default,$rand_change_pct,Determine_NumDecimals(0.01));
  $zed = Randomize_SetOrCreate_GenericPropertyAndVal($zed,
    'SizeScale',
    { pct_random_int => $rand_change_pct, default => $sizescale_default }
  );

  return $zed;
}

sub Randomize_HealthMaxBase {
  my($zed,$pct_rand) = @_;
  # <effect_group name="Base Effects">
  #    <passive_effect name="HealthMax" operation="base_set" value="300"/>

  my $found = 0;
  foreach my $size ($zed->findnodes('./effect_group[@name=\'Base Effects\']/passive_effect[@name=\'HealthMax\' and @operation=\'base_set\']')) {
    $found = 1;
    my $size_val = $size->getAttribute('value');
    my $new_val = Randomize_PercentAroundGivenNumber($size_val,$pct_rand,Determine_NumDecimals($size_val));
    $size->setAttribute(q|value|,$new_val); # random this
  }

  # ok, we did NOT find a "size" attribute. forget this for now

  return $zed;

}
sub Randomize_HealthAndExperienceGain {
  # The healthier the more damage/bullets the more exp
  my($zed,$cfg) = @_;
  my $pct_rand_int = $cfg->{'pct_random_int'};
  my $exp_gain_default_int = $cfg->{'experience_gain_default_int'};

  $zed = Randomize_HealthMaxBase($zed,$pct_rand_int); # percent to rand
  # TODO: divide rand by 2, 3? Too much exp?
  $zed = Randomize_SetOrCreate_GenericPropertyAndVal($zed,
    'ExperienceGain',
    { pct_random_int => $pct_rand_int, default => $exp_gain_default_int }
  ); # $pct_random,$val_if_empty

  return $zed;
}

sub IsEntityBlockedForProperty {
  my($cfg_entity_key,$cfg_property_key,$entity_name) = @_;
  my $result = 0; # Disable by default = allow all entities
  # ok, this val may not exist
  $entity_name = 'UNDEFINED' if !defined $entity_name;
  $entity_name = 'UNDEFINED' if $entity_name eq '';

  # BLocking ONLY allowed at deepest level
  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'only_allow_these_entities_list'}) {
    $result = 1; # We have a block list.
    if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'only_allow_these_entities_list'}{$entity_name}) {
      $result = 0; # This one is allowed
    }
  }

  #if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'ignore_entity_list'}) {
  #  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'ignore_entity_list'}{$entity_name}) {
  #    $result = 1; # This one is NOT allowed
  #  }
  #}

  return $result;
}
sub IsRandomizerEnabledForProperty {
  my($cfg_entity_key,$cfg_property_key,$entity_name) = @_;
  my $enabled = 0; # Disable by default.

  #print "IsRandomizerEnabledForProperty: $cfg_entity_key,$cfg_property_key,$entity_name\n";
  # ok, this val may not exist
  $entity_name = 'UNDEFINED' if !defined $entity_name;
  $entity_name = 'UNDEFINED' if $entity_name eq '';

  # Deepest first. If $cfg_property_key exists, then anable, else look for specific disable
  # This keeps the config file smaller
  # Literal setting for specific entity

  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{$entity_name}) {
    $enabled = 1;
    if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{$entity_name}{'disable_randomizer'}) {
      $enabled = 0 if $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{$entity_name}{'disable_randomizer'} == 1;
      # print "IsRandomizerEnabledForProperty: ".$enabled."\n";
      return $enabled;
    }
  }
  # Literal setting for all entities for specific property
  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}) {
    $enabled = 1;
    if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'disable_randomizer'}) {
      $enabled = 0 if $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{'disable_randomizer'} == 1;
      return $enabled;
    }
  }
  # Not needed here as etermine this earlier in code
  # Literal setting for all entities of that group
  #if(exists $CONFIGS->{$cfg_entity_key}) {
  #  $enabled = 1;
  #  $enabled = 0  if $CONFIGS->{$cfg_entity_key}{'disable_randomizer'} == 1;
  #  return $enabled;
  #}

  return $enabled;
}

sub GetEntityConfigFileConfigs {
  my($cfg_entity_key,$cfg_property_key,$entity_name) = @_;
  # Defaults are always good
  #print "GetEntityConfigFileConfigs DEFAULT ConfigDefaults -> $cfg_property_key\n";
  my $args = $CONFIGS->{'ConfigDefaults'}{$cfg_property_key};

  # standard override: property overrides for a key
  # # Ugh, for now
  # Harder, because there's no yes/no to this. was checking for specific known key
  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}) {
    my $keys = keys %{$CONFIGS->{$cfg_entity_key}{$cfg_property_key}};
    if($keys > 1) {
      #print "GetEntityConfigFileConfigs ($keys) $cfg_entity_key -> $cfg_property_key\n";
      $args = $CONFIGS->{$cfg_entity_key}{$cfg_property_key};
    }
  }

  # Deepest nest: entity specific property overrides for a key
  if(exists $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{$entity_name}) {
    #print "GetEntityConfigFileConfigs DEEPEST $cfg_entity_key -> $cfg_property_key -> $entity_name\n";
    $args = $CONFIGS->{$cfg_entity_key}{$cfg_property_key}{$entity_name};
  }

  return $args;
}
sub RandomizeEntity {
  my($entity_config_key,$new_entity,$entity_name) = @_;

    # Loop through configs for this entity
    my @config_keys = keys %{$CONFIGS->{$entity_config_key}};
    foreach my $cfg_property_key (@config_keys){

      # ugh, for now
      next if $cfg_property_key eq 'disable_randomizer';
      next if $cfg_property_key eq 'num_generation_loops';
      next if $cfg_property_key eq 'ignore_entity_list';

      if(! IsRandomizerEnabledForProperty($entity_config_key,$cfg_property_key,$entity_name)) {
        LogInfo('Randomizing disabled in config file for property: '.$entity_config_key.'->'.$cfg_property_key.'->'.$entity_name);
        next;
      }

      # Check if should ONLY apply/randomize configs for this entity
      # Specifically for configs that are entity specific: demolishers, vultures, etc.
      if(IsEntityBlockedForProperty($entity_config_key,$cfg_property_key,$entity_name)) {
        LogDebug('Randomizing of this property is blocked in config file for entity: '.$entity_config_key.'->'.$cfg_property_key.'->'.$entity_name);
        next;
      }

      my $args = GetEntityConfigFileConfigs($entity_config_key,$cfg_property_key,$entity_name);

      # Get the randomizer function name to use from defaults
      my $rand_function_key = $CONFIGS->{'ConfigDefaults'}{$cfg_property_key}{'rand_function'};
      LogDebug('Randomizing: '.$entity_config_key.' - '.$cfg_property_key.' via:'.$rand_function_key);

      if($rand_function_key eq 'custom_WalkType') {
        $new_entity = Randomize_WalkType($new_entity);
      }
      elsif($rand_function_key eq 'custom_TintMaterial') {
        $new_entity = Randomize_SetOnly_NoCreate_TintMaterial($new_entity);
      }
      elsif($rand_function_key eq 'custom_MassAndWeightAndSizeScale') {
        $new_entity = Randomize_MassAndWeightAndSizeScale($new_entity,$args);
      }
      elsif($rand_function_key eq 'custom_HealthAndExperienceGain') {
        $new_entity = Randomize_HealthAndExperienceGain($new_entity,$args);
      }
      elsif($rand_function_key eq 'setcreate_one_range') {
        $new_entity = Randomize_SetOrCreate_FromRangeGenericPropertyAndVal($new_entity,$cfg_property_key,$args);
      }
      elsif($rand_function_key eq 'setcreate_two_range') {
        $new_entity = Randomize_SetOrCreate_RangedGenericPropertyAndVal($new_entity,$cfg_property_key,$args);
      }
      elsif($rand_function_key eq 'setcreate_rand_around_percent') {
        $new_entity = Randomize_SetOrCreate_GenericPropertyAndVal($new_entity,$cfg_property_key,$args);
      }
    }

  return $new_entity;
}
############################################################
############################################################
# MAIN
############################################################
############################################################

##########
# Handle command line args/config loading/init
##########
GetOptions (
  "config_file_name=s" => \$CONFIG_FILE_NAME
) or croak(LogError('Error in command line arguments'));
if(! defined $CONFIG_FILE_NAME) {
  LogError('Required argument not passed: config_file_name');
  exit;
}
$CONFIGS = LoadConfigs($PROJECT_ROOT_DIR,$CONFIG_FILE_NAME);

CheckConfigExistsOrExit($CONFIGS->{'config_file_format'},'config_file_format');
if (! grep(/$CONFIGS->{'config_file_format'}/, @COMPATIBLE_CONFIG_FILE_FORMATS)) {
  LogError('config_file_format of: '.$CONFIGS->{'config_file_format'}.' is not compatible with script supported versions. You may have an old script or config file.');
  exit;
}

##########
# Check/set/store required configs
##########
CheckConfigExistsOrExit($CONFIGS->{'log_level'},'log_level');
if(
    ($CONFIGS->{'log_level'} > 0) and
    ($CONFIGS->{'log_level'} < 4)
  ) {
   $LOG_LEVEL = $CONFIGS->{'log_level'};
}

CheckConfigExistsOrExit($CONFIGS->{'game_install_dir'},'game_install_dir');
CheckDirExistsOrExit($CONFIGS->{'game_install_dir'},'game_install_dir');

$CONFIGS->{'game_config_dir'} = $CONFIGS->{'game_install_dir'}.'/Data/Config';
CheckDirExistsOrExit($CONFIGS->{'game_config_dir'},'game_config_dir');
$CONFIGS->{'using_config_dir'} = $CONFIGS->{'game_config_dir'};

# OVERRIDE! Determine if we should use a saved game (with entities from other mods) for entity generation
CheckConfigExistsOrExit($CONFIGS->{'use_save_game'},'use_save_game'); # can be blank
CheckConfigExistsOrExit($CONFIGS->{'game_saves_dir'},'game_saves_dir'); # can be blank
if($CONFIGS->{'use_save_game'} ne ""){ # can be blank, but if something in it, use it!
  LogInfo('use_save_game set. Using save game for configs:'.$CONFIGS->{'use_save_game'});
  CheckDirExistsOrExit($CONFIGS->{'game_saves_dir'},'game_saves_dir');
  $CONFIGS->{'saved_game_dir'} = $CONFIGS->{'game_saves_dir'}.'/'.$CONFIGS->{'use_save_game'}.'/ConfigsDump';
  CheckDirExistsOrExit($CONFIGS->{'saved_game_dir'},'saved_game_dir');
  $CONFIGS->{'using_config_dir'} = $CONFIGS->{'saved_game_dir'};
}

# Note: Here is where we pull the XML configs from!
$CONFIGS->{'entityclasses_file'} = $CONFIGS->{'using_config_dir'}.'/entityclasses.xml';
CheckFileExistsOrExit($CONFIGS->{'entityclasses_file'},'entityclasses_file');

$CONFIGS->{'entitygroups_file'} = $CONFIGS->{'using_config_dir'}.'/entitygroups.xml';
CheckFileExistsOrExit($CONFIGS->{'entitygroups_file'},'entitygroups_file');

CheckConfigExistsOrExit($CONFIGS->{'game_version'},'game_version');
CheckConfigExistsOrExit($CONFIGS->{'modlet_tag'},'modlet_tag');
$CONFIGS->{'modlet_name'} = 'Doughs-RandomizedEntities-For-'.$CONFIGS->{'game_version'}.'_'.$CONFIGS->{'modlet_tag'};

$CONFIGS->{'modlet_gen_dir'} = $PROJECT_ROOT_DIR.'/'.$CONFIGS->{'modlet_name'};

CheckConfigExistsOrExit($CONFIGS->{'ConfigEntityZombie'}{'num_generation_loops'},'num_generation_loops');
CheckConfigExistsOrExit($CONFIGS->{'ConfigEntityFriendlyAnimal'}{'num_generation_loops'},'num_generation_loops');
CheckConfigExistsOrExit($CONFIGS->{'ConfigEntityEnemyAnimal'}{'num_generation_loops'},'num_generation_loops');

CheckConfigExistsOrExit($CONFIGS->{'unique_entity_prefix'},'unique_entity_prefix');

# Allow users to configure zeds to NEVER CLONE as modlets may do weird stuff if randomizing against a saved games files
CheckConfigExistsOrExit($CONFIGS->{'ignore_entity_list'},'ignore_entity_list'); # can be empty
foreach my $user_config_ignore_entity (keys %{$CONFIGS->{'ignore_entity_list'}}) {
  my $reason = $CONFIGS->{'ignore_entity_list'}{$user_config_ignore_entity};
  LogInfo('Globally Ignoring entity:'.$user_config_ignore_entity.' because: '.$reason);
  $NEW_ENTITY_FILTER_LIST{$user_config_ignore_entity} = $reason;
}

$ENTITYCLASSES_DOM = XML::LibXML->load_xml(location => $CONFIGS->{'entityclasses_file'});
$ENTITYGROUPS_DOM = XML::LibXML->load_xml(location => $CONFIGS->{'entitygroups_file'});

####################
# Generate Lookup Tables
####################
LogInfo('########## Generating Lookup Tables ##########');
# Loop all entity types until we have populated %ENTITY_TYPE_LOOKUP with all types
$TMP_LOOP_COUNTER = 1;
while($TMP_LOOP_COUNTER) {
  last if(PopulateEntityTypeLookup() == 0); # Returns a failure count if could not look all entities up

  if($TMP_LOOP_COUNTER > $POPULATE_ENTITY_TYPE_LOOKUP_MAX_LOOPS) {
    LogError('PopulateEntityTypeLookup loop_may_count reached. entityclasses nested to deep! Exiting.');
    exit;
  }
  $TMP_LOOP_COUNTER++;
}
$TMP_LOOP_COUNTER = 0;

PopulateTypeEntityLookup();

=pod
# Dump all the zeds by class
foreach my $k (keys %TYPE_ENTITY_LOOKUP){
  print $k.' => ';
  foreach my $v (@{$TYPE_ENTITY_LOOKUP{$k}}) {
    print $v.',';
  }
  print "\n";

}
=cut
################################################################################
################################################################################
# Zed Generation
################################################################################
################################################################################
LogInfo('########## Generating EntityZombie Entities ##########');
# Get all the entity_class-es we want to handle, by type
my $entity_class_zombies = $TYPE_ENTITY_LOOKUP{'EntityZombie'};
$TOTAL_ZED_ENTITIES_FOUND = @{$entity_class_zombies};
$ENTITY_CONFIG_KEY = 'ConfigEntityZombie';

while($CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}) {

  if($CONFIGS->{$ENTITY_CONFIG_KEY}{'disable_randomizer'} == 1) {
    LogInfo('Ignoring entity: '.$ENTITY_CONFIG_KEY.' Reason: Entire entity group disabled in config file');
    last;
  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}--;

  foreach my $entity_name (@{$entity_class_zombies}) {

    # Check to see if we should not randomise this entity
    if(exists $CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name}) {
      LogInfo('Ignoring entity: '.$entity_name.'. Reason: '.$CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name});
      next;
    }

    # Clone entity
    my ($new_entity_name,$new_entity) = GenerateNewEntityFromExistingName($entity_name);
    if(! defined $new_entity_name) { next;} # Some are to be skipped
    $TOTAL_ZED_ENTITIES_GENERATED++;

    LogDebug('Cloned entity_class EntityZombie: '.$entity_name.' as: '.$new_entity_name);
    #my $xmlstring = $new_animal->toString();
    #print $xmlstring;
    #print "\n";

    $new_entity = RandomizeEntity($ENTITY_CONFIG_KEY,$new_entity,$entity_name);

    # Save it!
    $NEW_ENTITIES{$new_entity_name}{'zed_node'} = $new_entity;
    $NEW_ENTITIES{$new_entity_name}{'zed_is_from'} = $entity_name;

  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} = 0 if $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} <= 0;

}

################################################################################
################################################################################
# Enemy Animal Generation
################################################################################
################################################################################
LogInfo('########## Generating EntityEnemyAnimal Entities ##########');
# Get all the entity_class-es we want to handle, by type

my $entity_class_hostile_animals = $TYPE_ENTITY_LOOKUP{'EntityEnemyAnimal'};
$TOTAL_HOSTILE_ANIMAL_ENTITIES_FOUND = @{$entity_class_hostile_animals};
$ENTITY_CONFIG_KEY = 'ConfigEntityEnemyAnimal';

while($CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}) {

  if($CONFIGS->{$ENTITY_CONFIG_KEY}{'disable_randomizer'} == 1) {
    LogInfo('Ignoring entity: '.$ENTITY_CONFIG_KEY.' Reason: Entire entity group disabled in config file');
    last;
  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}--;

  foreach my $entity_name (@{$entity_class_hostile_animals}) {

    # Check to see if we should not randomise this entity
    if(exists $CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name}) {
      LogInfo('Ignoring entity: '.$entity_name.'. because: '.$CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name});
      next;
    }

    # Clone entity
    my ($new_entity_name,$new_entity) = GenerateNewEntityFromExistingName($entity_name);
    if(! defined $new_entity_name) { next;} # Some are to be skipped
    $new_entity->toString();
    $TOTAL_HOSTILE_ANIMAL_ENTITIES_GENERATED++;

    LogDebug('Cloned entity_class EntityEnemyAnimal: '.$entity_name.' as: '.$new_entity_name);
    #my $xmlstring = $new_animal->toString();
    #print $xmlstring;
    #print "\n";

    $new_entity = RandomizeEntity($ENTITY_CONFIG_KEY,$new_entity,$entity_name);

    # Save it!
    $NEW_ENTITIES{$new_entity_name}{'zed_node'} = $new_entity;
    $NEW_ENTITIES{$new_entity_name}{'zed_is_from'} = $entity_name;

  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} = 0 if $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} <= 0;

}

################################################################################
################################################################################
# Friendly Animal Generation
################################################################################
################################################################################
LogInfo('########## Generating EntityAnimal Entities ##########');
# Get all the entity_class-es we want to handle, by type

my $entity_class_friendly_animals = $TYPE_ENTITY_LOOKUP{'EntityAnimalStag'};
$TOTAL_FRIENDLY_ANIMAL_ENTITIES_FOUND = @{$entity_class_friendly_animals};
$ENTITY_CONFIG_KEY = 'ConfigEntityFriendlyAnimal';

while($CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}) {

  if($CONFIGS->{$ENTITY_CONFIG_KEY}{'disable_randomizer'} == 1) {
    LogInfo('Ignoring entity: '.$ENTITY_CONFIG_KEY.' Reason: Entire entity group disabled in config file');
    last;
  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'}--;

  foreach my $entity_name (@{$entity_class_friendly_animals}) {

    # Check to see if we should not randomise this entity
    if(exists $CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name}) {
      LogInfo('Ignoring entity: '.$entity_name.'. Reason: '.$CONFIGS->{$ENTITY_CONFIG_KEY}{'ignore_entity_list'}{$entity_name});
      next;
    }

    # Clone entity
    my ($new_entity_name,$new_entity) = GenerateNewEntityFromExistingName($entity_name);
    if(! defined $new_entity_name) { next;} # Some are to be skipped
    $TOTAL_FRIENDLY_ANIMAL_ENTITIES_GENERATED++;

    LogDebug('Cloned entity_class EntityAnimal: '.$entity_name.' as: '.$new_entity_name);
    #my $xmlstring = $new_animal->toString();
    #print $xmlstring;
    #print "\n";

    $new_entity = RandomizeEntity($ENTITY_CONFIG_KEY,$new_entity,$entity_name);

    # Save it!
    $NEW_ENTITIES{$new_entity_name}{'zed_node'} = $new_entity;
    $NEW_ENTITIES{$new_entity_name}{'zed_is_from'} = $entity_name;

  }

  $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} = 0 if $CONFIGS->{$ENTITY_CONFIG_KEY}{'num_generation_loops'} <= 0;

}

####################
# Modlet Generation
####################
=pod
# Dump all the zeds by class
foreach my $zed_name (keys %NEW_ENTITIES){
  print 'ENTITY '.$zed_name.' => ';
  my $zed_node = $NEW_ENTITIES{$zed_name}{'zed_node'};
  my $is_from_zed = $NEW_ENTITIES{$zed_name}{'zed_is_from'};
  print $zed_node.' => '.$is_from_zed;
  print $zed_node->toString();
  print "\n";

}
=cut

LogInfo('########## Generating Modlet ##########');
ModletGen_Start();
# TODO: change xeds to entities?
my @zeds = sort keys %NEW_ENTITIES;
if(! @zeds) {
  LogInfo('########## No entities generated to add to a modlet. Not generating modlet ##########');
  exit;
}
LogInfo('########## Adding Entities to Modlet ##########');
foreach my $zed_name (@zeds) {
  LogDebug('Adding Entity to Modlet: '.$zed_name);
  my $zed_node = $NEW_ENTITIES{$zed_name}{'zed_node'};
  my $is_from_zed = $NEW_ENTITIES{$zed_name}{'zed_is_from'};

  LogDebug('########## ModletGen_AddZedToEntitiesOverride: '.$zed_name.' ##########');
  ModletGen_AddZedToEntitiesOverride($zed_node);
  LogDebug('########## ModletGen_AddZedToEntityGroupsLookup: '.$zed_name.' ##########');
  ModletGen_AddZedToEntityGroupsLookup($zed_name,$is_from_zed);
}

LogInfo('########## Adding Entities to Groups ##########');
ModletGen_AddZedsToEntityGroupsFile();

ModletGen_Finish();

LogInfo('Generated Zeds: '.$TOTAL_ZED_ENTITIES_GENERATED.' entities from: '.$TOTAL_ZED_ENTITIES_FOUND.' base entities');
LogInfo('Generated Hostile Animals: '.$TOTAL_HOSTILE_ANIMAL_ENTITIES_GENERATED.' entities from: '.$TOTAL_HOSTILE_ANIMAL_ENTITIES_FOUND.' base entities');
LogInfo('Generated Friendly Animals: '.$TOTAL_FRIENDLY_ANIMAL_ENTITIES_GENERATED.' entities from: '.$TOTAL_FRIENDLY_ANIMAL_ENTITIES_FOUND.' base entities');

1;
