/***********************************************************************/
/** 	New Game Plus Combat© 2018 DarkTar All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



exec function NGPCStandardInit()
{
	NewGamePlusCombat(true, false);
}

exec function NGPCCustomInit()
{
	NewGamePlusCombat(false, false);
}

exec function NGPCCustomInitResetDiagrams()
{
	NewGamePlusCombat(false, true);
}

exec function NGPCLockVanillaEquipmentLeveling()
{
	LockVanillaEquipmentLeveling(true);
}

exec function NGPCUnlockVanillaEquipmentLeveling()
{
	LockVanillaEquipmentLeveling(false);
}

exec function NGPCClearOriginalEquipmentLevel()
{
    ClearOriginalEquipmentLevel();
}

function NewGamePlusCombat(standardInit: bool, resetDiagrams: bool)
{
	var witcher: W3PlayerWitcher;
	var inventory, horseInventory: CInventoryComponent;

	FactsSet("NewGamePlus", 0);
	theGame.EnableNewGamePlus(true);

	if (standardInit)
	{
		thePlayer.NewGamePlusInitialize();
	}
	else
	{
		witcher = GetWitcherPlayer();

		inventory = witcher.GetInventory();
		horseInventory = witcher.GetHorseManager().GetInventoryComponent();

		RemoveQuestItemsByName(inventory, horseInventory);

		inventory.RemoveItemByTag('Quest', -1);
		horseInventory.RemoveItemByTag('Quest', -1);

		inventory.RemoveItemByTag('NoticeBoardNote', -1);
		horseInventory.RemoveItemByTag('NoticeBoardNote', -1);

		inventory.RemoveItemByTag('ReadableItem', -1);
		horseInventory.RemoveItemByTag('ReadableItem', -1);

		inventory.RemoveItemByTag('GwintCard', -1);
		horseInventory.RemoveItemByTag('GwintCard', -1);

		RemoveQuestAlchemyRecipes(witcher);

		if (resetDiagrams)
		{
			witcher.RemoveAllCraftingSchematics();
			witcher.AddStartingSchematicsW();
		}

		inventory.AddAnItem('Clearing Potion', 1, true, false, false);

		witcher.NewGamePlusMarkItemsToNotAdjustW(inventory);
		witcher.NewGamePlusMarkItemsToNotAdjustW(horseInventory);

		thePlayer.GetInputHandler().ClearLocksForNGP();

		witcher.ClearBuffImmunities();
	}

	theGame.GetGuiManager().ShowUserDialogAdv(0, "", "mod_newgamepluscombat_initdone", true, UDB_Ok);
}

function RemoveQuestItemsByName(inventory: CInventoryComponent, horseInventory: CInventoryComponent)
{
	var questItems: array<name>;
	var i: int;

	questItems = theGame.GetDefinitionsManager().GetItemsWithTag('Quest');
	for (i = 0; i < questItems.Size(); i += 1)
	{
		inventory.RemoveItemByName(questItems[i], -1);
		horseInventory.RemoveItemByName(questItems[i], -1);
	}
}

function RemoveQuestAlchemyRecipes(witcher: W3PlayerWitcher)
{
	var recipe: SAlchemyRecipe;
	var recipes: array<name>;
	var i: int;

	recipes = witcher.GetAlchemyRecipes();

	for (i = 0; i < recipes.Size(); i += 1)
	{
		recipe = getAlchemyRecipeFromName(recipes[i]);
		if (recipe.cookedItemType == EACIT_Quest)
			witcher.RemoveAlchemyRecipeW(recipes[i]);
	}
}

function LockVanillaEquipmentLeveling(lock: bool)
{
	var witcher: W3PlayerWitcher;
	var inventory, horseInventory: CInventoryComponent;

	witcher = GetWitcherPlayer();
	inventory = witcher.GetInventory();
	horseInventory = witcher.GetHorseManager().GetInventoryComponent();

	if (lock)
	{
		witcher.NewGamePlusMarkItemsToNotAdjustW(inventory);
		witcher.NewGamePlusMarkItemsToNotAdjustW(horseInventory);

		theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("mod_newgamepluscombat_inventorylocked"), 5000);
	}
	else
	{
		witcher.NewGamePlusMarkItemsToAdjust(inventory);
		witcher.NewGamePlusMarkItemsToAdjust(horseInventory);

		theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("mod_newgamepluscombat_inventoryunlocked"), 5000);
	}
}

function ClearOriginalEquipmentLevel()
{
    var witcher: W3PlayerWitcher;
    var inventory: CInventoryComponent;

    witcher = GetWitcherPlayer();
    inventory = witcher.GetInventory();

    inventory.ClearOriginalEquipmentLevel();

    theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("mod_newgamepluscombat_originalequipmentlevelcleared"), 5000);
}

class CNewGamePlusCombat extends IScriptable {

	private var enemyStrafingNoRun: string;
	private var enemyStrafingRun: string;
	private var enemyStrafingOff: string;
	private var jumpingOn: string;
	private var jumpingOff: string;
	private var lootingOn: string;
	private var lootingOff: string;
	private var gameSpeedFast: string;
	private var gameSpeedSlow: string;
	private var gameSpeedPaused: string;
	private var gameSpeedNormal: string;
	private var damageDealtMultiplier: string;
	private var damageTakenMultiplier: string;
	private const var duration: int;
	default duration = 3000;
	
	public function Init()
	{
		InitTexts();
		SetEquipmentDurability();
		RegisterListeners();
	}

	private function InitTexts()
	{
		var option: string;
		var on: string;
		var off: string;
		
		on = GetLocStringByKeyExt("mod_newgamepluscombat_on");
		off = GetLocStringByKeyExt("mod_newgamepluscombat_off");
		
		option = GetLocStringByKeyExt("mod_newgamepluscombat_enemystrafing");
		enemyStrafingNoRun = option + ": " + GetLocStringByKeyExt("mod_newgamepluscombat_enemystrafingnorun");
		enemyStrafingRun = option + ": " + GetLocStringByKeyExt("mod_newgamepluscombat_enemystrafingrun");
		enemyStrafingOff = option + ": " + off;

		option = GetLocStringByKeyExt("mod_newgamepluscombat_jumping");
		jumpingOn = option + ": " + on;
		jumpingOff = option + ": " + off;

		option = GetLocStringByKeyExt("mod_newgamepluscombat_looting");
		lootingOn = option + ": " + on;
		lootingOff = option + ": " + off;

		gameSpeedFast = GetLocStringByKeyExt("mod_newgamepluscombat_gamespeedfast");
		gameSpeedSlow = GetLocStringByKeyExt("mod_newgamepluscombat_gamespeedslow");
		gameSpeedPaused = GetLocStringByKeyExt("mod_newgamepluscombat_gamespeedpaused");
		gameSpeedNormal = GetLocStringByKeyExt("mod_newgamepluscombat_gamespeednormal");
		
		damageDealtMultiplier = GetLocStringByKeyExt("mod_newgamepluscombat_damagedealtmultiplier");
		damageTakenMultiplier = GetLocStringByKeyExt("mod_newgamepluscombat_damagetakenmultiplier");
	}
	
	private function SetEquipmentDurability()
	{
		var chance: int;

		chance = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'ChanceOfArmorDamage'), 100);
		theGame.params.SetDurabilityArmorLoseChance(chance);

		chance = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'ChanceOfWeaponDamage'), 100);
		theGame.params.SetDurabilityWeaponLoseChance(chance);
	}

	/*
	private function ResetEquipmentDurability()
	{
		theGame.params.SetDurabilityArmorLoseChance(100);
		theGame.params.SetDurabilityWeaponLoseChance(100);
	}
	*/
	
	private function RegisterListeners()
	{
		theInput.RegisterListener(this, 'OnToggleEnemyStrafing', 'ToggleEnemyStrafing');
		theInput.RegisterListener(this, 'OnToggleEnemyStrafingCombat', 'ToggleEnemyStrafingCombat');
		theInput.RegisterListener(this, 'OnToggleJumping', 'ToggleJumping');
		theInput.RegisterListener(this, 'OnToggleLooting', 'ToggleLooting');

		theInput.RegisterListener(this, 'OnCombatJump', 'CbtJump');
		theInput.RegisterListener(this, 'OnCombatTaunt', 'CbtTaunt');

		theInput.RegisterListener(this, 'OnSpeedup', 'Speedup');
		theInput.RegisterListener(this, 'OnSlowdown', 'Slowdown');
		theInput.RegisterListener(this, 'OnPause', 'Pause');
		
		theInput.RegisterListener(this, 'OnDecDamageDealtMultiplier', 'DecDamageDealtMultiplier');
		theInput.RegisterListener(this, 'OnIncDamageDealtMultiplier', 'IncDamageDealtMultiplier');
		theInput.RegisterListener(this, 'OnDecDamageTakenMultiplier', 'DecDamageTakenMultiplier');
		theInput.RegisterListener(this, 'OnIncDamageTakenMultiplier', 'IncDamageTakenMultiplier');
	}

	/*
	private function UnregisterListeners()
	{
		theInput.UnregisterListener(this, 'ToggleEnemyStrafing');
		theInput.UnregisterListener(this, 'ToggleEnemyStrafingCombat');
		theInput.UnregisterListener(this, 'ToggleJumping');
		theInput.UnregisterListener(this, 'ToggleLooting');

		theInput.UnregisterListener(this, 'CbtJump');
		theInput.UnregisterListener(this, 'CbtTaunt');

		theInput.UnregisterListener(this, 'Speedup');
		theInput.UnregisterListener(this, 'Slowdown');
		theInput.UnregisterListener(this, 'Pause');
		
		theInput.UnregisterListener(this, 'DecDamageDealtMultiplier');
		theInput.UnregisterListener(this, 'IncDamageDealtMultiplier');
		theInput.UnregisterListener(this, 'DecDamageTakenMultiplier');
		theInput.UnregisterListener(this, 'IncDamageTakenMultiplier');
	}
	*/
	
	private function SetTimeScale(action: SInputAction, scale: float, message: string)
	{
		if (IsPressed(action))
		{
			theGame.SetTimeScale(scale, theGame.GetTimescaleSource(ETS_None), theGame.GetTimescalePriority(ETS_None));
			theGame.GetGuiManager().ShowNotification(message, duration);
		}
		else if (IsReleased(action))
		{
			theGame.RemoveTimeScale(theGame.GetTimescaleSource(ETS_None));
			theGame.GetGuiManager().ShowNotification(gameSpeedNormal, duration);
		}
	}

	private function SetDamageMultiplier(action: SInputAction, type: name, message: string, increase: bool)
	{
		var damageMultiplier: float;
		
		if (IsPressed(action))
		{
			damageMultiplier = StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', type), 1);

			if (increase)
			{
				damageMultiplier += 0.1;
				if (damageMultiplier > 2)
					damageMultiplier = 2;
			}
			else
			{
				damageMultiplier -= 0.1;
				if (damageMultiplier < 0.5)
					damageMultiplier = 0.5;
			}

			theGame.GetGuiManager().ShowNotification(message + ": " + NoTrailZeros(damageMultiplier), duration);

			theGame.GetInGameConfigWrapper().SetVarValue('NewGamePlusCombat', type, damageMultiplier);
			theGame.SaveUserSettings();
		}
	}

	event OnSpeedup(action: SInputAction)
	{
		SetTimeScale(action, 4, gameSpeedFast);
	}
	
	event OnSlowdown(action: SInputAction)
	{
		SetTimeScale(action, 0.25, gameSpeedSlow);
	}

	event OnPause(action: SInputAction)
	{
		SetTimeScale(action, 0, gameSpeedPaused);
	}

	event OnDecDamageDealtMultiplier(action: SInputAction)
	{
		SetDamageMultiplier(action, 'DamageDealtMultiplier', damageDealtMultiplier, false);
	}
	
	event OnIncDamageDealtMultiplier(action: SInputAction)
	{
		SetDamageMultiplier(action, 'DamageDealtMultiplier', damageDealtMultiplier, true);
	}
	
	event OnDecDamageTakenMultiplier(action: SInputAction)
	{
		SetDamageMultiplier(action, 'DamageTakenMultiplier', damageTakenMultiplier, false);
	}
	
	event OnIncDamageTakenMultiplier(action: SInputAction)
	{
		SetDamageMultiplier(action, 'DamageTakenMultiplier', damageTakenMultiplier, true);
	}

	event OnToggleEnemyStrafing(action: SInputAction)
	{
		var enemyStrafing: string;
		
		if (IsPressed(action))
		{
			enemyStrafing = theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'EnemyStrafing');

			if (enemyStrafing == "0")
			{
				enemyStrafing = "1";
				theGame.GetGuiManager().ShowNotification(enemyStrafingRun, duration);
			}
			else if (enemyStrafing == "1")
			{
				enemyStrafing = "2";
				theGame.GetGuiManager().ShowNotification(enemyStrafingOff, duration);
			}
			else if (enemyStrafing == "2")
			{
				enemyStrafing = "0";
				theGame.GetGuiManager().ShowNotification(enemyStrafingNoRun, duration);
			}

			theGame.GetInGameConfigWrapper().SetVarValue('NewGamePlusCombat', 'EnemyStrafing', enemyStrafing);
			theGame.SaveUserSettings();
		}
	}

	event OnToggleEnemyStrafingCombat(action: SInputAction)
	{
		var enemyStrafing: string;
		
		if (IsPressed(action))
		{
			enemyStrafing = theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'EnemyStrafing');

			if (enemyStrafing == "0")
			{
				enemyStrafing = "1";
				theGame.GetGuiManager().ShowNotification(enemyStrafingRun, duration);
			}
			else
			{
				enemyStrafing = "0";
				theGame.GetGuiManager().ShowNotification(enemyStrafingNoRun, duration);
			}

			theGame.GetInGameConfigWrapper().SetVarValue('NewGamePlusCombat', 'EnemyStrafing', enemyStrafing);
			theGame.SaveUserSettings();
		}
	}

	event OnToggleJumping(action: SInputAction)
	{
		var jumping: bool;
		
		if (IsPressed(action))
		{
			jumping = theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'Jumping');
			
			jumping = !jumping;
			
			if (jumping)
				theGame.GetGuiManager().ShowNotification(jumpingOn, duration);
			else
				theGame.GetGuiManager().ShowNotification(jumpingOff, duration);

			theGame.GetInGameConfigWrapper().SetVarValue('NewGamePlusCombat', 'Jumping', jumping);
			theGame.SaveUserSettings();
		}
	}
	
	event OnToggleLooting(action: SInputAction)
	{
		var looting: bool;
		
		if (IsPressed(action))
		{
			looting = theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'Looting');
			
			looting = !looting;
			
			if (looting)
				theGame.GetGuiManager().ShowNotification(lootingOn, duration);
			else
				theGame.GetGuiManager().ShowNotification(lootingOff, duration);

			theGame.GetInGameConfigWrapper().SetVarValue('NewGamePlusCombat', 'Looting', looting);
			theGame.SaveUserSettings();
		}
	}

	event OnCombatJump(action: SInputAction)
	{
		var jumping: bool;
		
		jumping = theGame.GetInGameConfigWrapper().GetVarValue('NewGamePlusCombat', 'Jumping');
		
		if (jumping && IsPressed(action))
			thePlayer.substateManager.QueueStateExternal('Jump');
	}

	event OnCombatTaunt(action: SInputAction)
	{
		if (IsPressed(action))
		{
			if (thePlayer.RaiseEvent('CombatTaunt'))
				thePlayer.PlayVoiceset(90, 'BattleCryTaunt');
		}
	}
}
