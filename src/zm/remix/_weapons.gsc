#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_weap_claymore;
#include maps/mp/zombies/_zm_melee_weapon;
#include maps/mp/zombies/_zm_buildables;
#include maps/mp/zombies/_zm_magicbox;


buildable_increase_trigger_radius()
{
	for(i = 0; i < level.buildable_stubs.size; i++)
	{
		level.buildable_stubs[i].script_length = 120;
		level.buildable_stubs[i].require_look_at = 0;
		// level.buildable_stubs[i].prompt_and_visibility_func = ::buildabletrigger_update_prompt_custom;
	}
}

wallbuy_increase_trigger_radius()
{
	for(i = 0; i < level._unitriggers.trigger_stubs.size; i++)
	{
		if(IsDefined(level._unitriggers.trigger_stubs[i].zombie_weapon_upgrade))
		{
			level._unitriggers.trigger_stubs[i].script_length = 96;
		}
	}
}

wallbuy_dynamic_increase_trigger_radius()
{
	if(!(is_classic() && level.scr_zm_map_start_location == "processing"))
	{
		return;
	}

	while (!isDefined(level.built_wallbuys))
	{
		wait 0.5;
	}

	prev_built_wallbuys = 0;

	while (1)
	{
		if (level.built_wallbuys > prev_built_wallbuys)
		{
			prev_built_wallbuys = level.built_wallbuys;
			wallbuy_increase_trigger_radius();
		}

		if (level.built_wallbuys == -100)
		{
			wallbuy_increase_trigger_radius();
			return;
		}

		wait 0.5;
	}
}

spawn_wallbuy_weapon( weapon_angles, weapon_coordinates, chalk_fx, weapon_name, weapon_model, target, targetname )
{
	tempmodel = spawn( "script_model", ( 0, 0, 0 ) );
	precachemodel( weapon_model );
	unitrigger_stub = spawnstruct();
	unitrigger_stub.origin = weapon_coordinates;
	unitrigger_stub.angles = weapon_angles;
	tempmodel.origin = weapon_coordinates;
	tempmodel.angles = weapon_angles;
	mins = undefined;
	maxs = undefined;
	absmins = undefined;
	absmaxs = undefined;
	tempmodel setmodel( weapon_model );
	tempmodel useweaponhidetags( weapon_name );
	mins = tempmodel getmins();
	maxs = tempmodel getmaxs();
	absmins = tempmodel getabsmins();
	absmaxs = tempmodel getabsmaxs();
	bounds = absmaxs - absmins;
	unitrigger_stub.script_length = bounds[ 0 ] * 0.25;
	unitrigger_stub.script_width = bounds[ 1 ];
	unitrigger_stub.script_height = bounds[ 2 ];
	unitrigger_stub.origin -= anglesToRight( unitrigger_stub.angles ) * ( unitrigger_stub.script_length * 0.4 );
	unitrigger_stub.target = target;
	unitrigger_stub.targetname = targetname;
	unitrigger_stub.cursor_hint = "HINT_NOICON";
	if ( unitrigger_stub.targetname == "weapon_upgrade" )
	{
		unitrigger_stub.cost = get_weapon_cost( weapon_name );
		if ( !is_true( level.monolingustic_prompt_format ) )
		{
			unitrigger_stub.hint_string = get_weapon_hint( weapon_name );
			unitrigger_stub.hint_parm1 = unitrigger_stub.cost;
		}
		else
		{
			unitrigger_stub.hint_parm1 = get_weapon_display_name( weapon_name );
			if ( !isDefined( unitrigger_stub.hint_parm1 ) || unitrigger_stub.hint_parm1 == "" || unitrigger_stub.hint_parm1 == "none" )
			{
				unitrigger_stub.hint_parm1 = "missing weapon name " + weapon_name;
			}
			unitrigger_stub.hint_parm2 = unitrigger_stub.cost;
			unitrigger_stub.hint_string = &"ZOMBIE_WEAPONCOSTONLY";
		}
	}
	unitrigger_stub.weapon_upgrade = weapon_name;
	unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
	unitrigger_stub.require_look_at = 1;
	unitrigger_stub.require_look_from = 0;
	unitrigger_stub.zombie_weapon_upgrade = weapon_name;
	maps/mp/zombies/_zm_unitrigger::unitrigger_force_per_player_triggers( unitrigger_stub, 1 );
	if ( is_melee_weapon( weapon_name ) )
	{
		if ( weapon_name == "tazer_knuckles_zm" && isDefined( level.taser_trig_adjustment ) )
		{
			unitrigger_stub.origin += level.taser_trig_adjustment;
		}
		maps/mp/zombies/_zm_unitrigger::register_static_unitrigger( unitrigger_stub, ::melee_weapon_think );
	}
	else if ( weapon_name == "claymore_zm" )
	{
		unitrigger_stub.prompt_and_visibility_func = ::claymore_unitrigger_update_prompt;
		maps/mp/zombies/_zm_unitrigger::register_static_unitrigger( unitrigger_stub, ::buy_claymores );
	}
	else
	{
		unitrigger_stub.prompt_and_visibility_func = ::wall_weapon_update_prompt;
		maps/mp/zombies/_zm_unitrigger::register_static_unitrigger( unitrigger_stub, ::weapon_spawn_think );
	}
	tempmodel delete();
    thread playchalkfx( chalk_fx, weapon_coordinates, weapon_angles );
}

playchalkfx( effect, origin, angles ) //custom function
{
	while ( 1 )
	{
		fx = SpawnFX( level._effect[ effect ], origin, AnglesToForward( angles ), AnglesToUp( angles ) );
		TriggerFX( fx );
		level waittill( "connected", player );
		fx Delete();
	}
}

buildabletrigger_update_prompt_custom( player ) //checked matches cerberus output
{
	can_use = self.stub buildablestub_update_prompt( player );
	self sethintstring( self.stub.hint_string );
	if ( isDefined( self.stub.cursor_hint ) )
	{
		self setcursorhint( self.stub.cursor_hint, self.stub.cursor_hint_weapon );
	}
	return can_use;
}

ammo_give_override( weapon ) //checked changed to match cerberus output
{
	give_ammo = 0;
	if ( !is_offhand_weapon( weapon ) )
	{
		weapon = get_weapon_with_attachments( weapon );
		if ( isDefined( weapon ) )
		{
			stockmax = 0;
			stockmax = weaponstartammo( weapon );
			clipcount = self getweaponammoclip( weapon );
			currstock = self getammocount( weapon );
			if ( ( currstock - clipcount ) >= stockmax )
			{
				give_ammo = 0;
			}
			else
			{
				give_ammo = 1;
			}
		}
	}
	else if ( self has_weapon_or_upgrade( weapon ) )
	{
		if ( self getammocount( weapon ) < weaponmaxammo( weapon ) )
		{
			give_ammo = 1;
		}
	}
	if ( give_ammo )
	{
		self play_sound_on_ent( "purchase" );
		self givemaxammo( weapon );
		alt_weap = weaponaltweaponname( weapon );
		if ( alt_weap != "none" )
		{
			self givemaxammo( alt_weap );
		}
		self setweaponammoclip( weapon, weaponclipsize( weapon ) );
	
		return 1;
	}
	if ( !give_ammo )
	{
		return 0;
	}
}

actor_damage_override_override( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex ) //checked changed to match cerberus output //checked against bo3 _zm.gsc partially changed to match
{
	if ( !isDefined( self ) || !isDefined( attacker ) )
	{
		return damage;
	}
	if ( weapon == "tazer_knuckles_zm" || weapon == "jetgun_zm" )
	{
		self.knuckles_extinguish_flames = 1;
	}
	else if ( weapon != "none" )
	{
		self.knuckles_extinguish_flames = undefined;
	}
	if ( isDefined( attacker.animname ) && attacker.animname == "quad_zombie" )
	{
		if ( isDefined( self.animname ) && self.animname == "quad_zombie" )
		{
			return 0;
		}
	}
	if ( !isplayer( attacker ) && isDefined( self.non_attacker_func ) )
	{
		if ( is_true( self.non_attack_func_takes_attacker ) )
		{
			return self [[ self.non_attacker_func ]]( damage, weapon, attacker );
		}
		else
		{
			return self [[ self.non_attacker_func ]]( damage, weapon );
		}
	}
	if ( !isplayer( attacker ) && !isplayer( self ) )
	{
		return damage;
	}
	if ( !isDefined( damage ) || !isDefined( meansofdeath ) )
	{
		return damage;
	}
	if ( meansofdeath == "" )
	{
		return damage;
	}
	old_damage = damage;
	final_damage = damage;
	if ( isDefined( self.actor_damage_func ) )
	{
		final_damage = [[ self.actor_damage_func ]]( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex );
	}
	if ( attacker.classname == "script_vehicle" && isDefined( attacker.owner ) )
	{
		attacker = attacker.owner;
	}
	if ( is_true( self.in_water ) )
	{
		if ( int( final_damage ) >= self.health )
		{
			self.water_damage = 1;
		}
	}
	attacker thread maps/mp/gametypes_zm/_weapons::checkhit( weapon );
	if ( attacker maps/mp/zombies/_zm_pers_upgrades_functions::pers_mulit_kill_headshot_active() && is_headshot( weapon, shitloc, meansofdeath ) )
	{
		final_damage *= 2;
	}
	if ( is_true( level.headshots_only ) && isDefined( attacker ) && isplayer( attacker ) )
	{
		//changed to match bo3 _zm.gsc behavior
		if ( meansofdeath == "MOD_MELEE" && shitloc == "head" || meansofdeath == "MOD_MELEE" && shitloc == "helmet" )
		{
			return int( final_damage );
		}
		if ( is_explosive_damage( meansofdeath ) )
		{
			return int( final_damage );
		}
		else if ( !is_headshot( weapon, shitloc, meansofdeath ) )
		{
			return 0;
		}
	}


	if ( ( weapon == "blundergat_zm" || weapon == "blundergat_upgraded_zm" ) && ( meansofdeath == "MOD_PISTOL_BULLET" || meansofdeath == "MOD_RIFLE_BULLET" ) )
	{
		final_damage = (self.maxhealth / 12) + 5;
		if(damage >= final_damage)
		{
			final_damage = damage;
		}
	}
	if( weapon == "claymore_zm" ) 
	{
		if( meansofdeath == "MOD_GRENADE" || meansofdeath == "MOD_GRENADE_SPLASH" )
		{
			if(flags == 5) // fix for grenades doing increased damage when holding claymores
			{
				final_damage = int(self.maxhealth / 2) + 55;
			}
			if(damage >= final_damage)
			{
				final_damage = damage;
			}
		}
	}
	if( attacker HasPerk("specialty_deadshot") && meansofdeath == "MOD_PISTOL_BULLET" || meansofdeath == "MOD_RIFLE_BULLET" && WeaponClass(weapon) != "spread" && sHitLoc == "head" || sHitLoc == "helmet" || sHitLoc == "neck" )
	{
		final_damage = int(final_damage * 2);
	}

	// damage scaling for explosive weapons
	// consistent damage and scales for zombies farther away from explosion better
	if(meansofdeath == "MOD_GRENADE" || meansofdeath == "MOD_GRENADE_SPLASH" || meansofdeath == "MOD_PROJECTILE" || meansofdeath == "MOD_PROJECTILE_SPLASH")
	{
		// no damage scaling for these wonder weps
		if(weapon != "claymore_zm")
		{
			// stop damage scaling past round 100
			scalar = level.round_number;
			if(scalar > 100)
			{
				scalar = 100;
			}

			final_damage += 30 * scalar;
		}
	}

	// if ( weapon == "quadrotorturret_zm" )
	// {
	// 	final_damage = int(self.maxhealth / 3) + 55;
	// }

	// if(weapon == "zombie_bullet_crouch_zm" && meansofdeath == "MOD_RIFLE_BULLET")
	// {
	// 	final_damage = int(self.maxhealth / 2) + 55;
	// }

	// print("damage: "  + damage);
	// print("final damage: "  + final_damage);

	// inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex
	return int( final_damage );
}