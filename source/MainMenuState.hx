package;

import openfl.sensors.Accelerometer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.util.FlxTimer;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState {
	public static var AyedVersion:String = '1.5.0';
	public static var AyedEngineVersion:String = '1.5.0'; // This is also used for Discord RPC
	// public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static inline var BG_COLOR:FlxColor = 0xDDF700FF;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'Discord',
		// 'Gallery',
		'credits',
		'options',
		'Quit'
	];

	// var logo:FlxSprite;
	var magenta:FlxSprite;
	var velocityBG:FlxBackdrop;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var timer:FlxTimer;

	override function create() {
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In MainMenu Ayed Engine", null);
		#end

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		FlxG.mouse.visible = true;

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		// logo = new FlxSprite(500, 0);
		// logo.frames = Paths.getSparrowAtlas('logoBumpin');

		// logo.antialiasing = ClientPrefs.globalAntialiasing;
		// logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		// logo.animation.play('bump');
		// logo.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;
		// add(logo);

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG' + FlxG.random.int(1, 5)));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuBG' + FlxG.random.int(1, 5)));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		velocityBG = new FlxBackdrop(Paths.image('velocityBG'));
		velocityBG.velocity.set(50, 50);
		add(velocityBG);

		if(ClientPrefs.highGPU)
		{
			remove(velocityBG);
			// cancelTween();
			FlxG.camera.follow(camFollowPos, null, 0);
		}

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length) {
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.x = 100;
			// menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			// menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();

			switch (i) {
				case 0:
					menuItem.setPosition(130, 50);
				case 1:
					menuItem.setPosition(270, 185);
				case 2:
					menuItem.setPosition(350, 315);
				case 3:
					menuItem.setPosition(490, 460);
				case 4:
					menuItem.setPosition(600, 600);
				case 5:
					menuItem.setPosition(-100, 700);
			}
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShitA:FlxText = new FlxText(12, FlxG.height - 64, 0, "Vs Ayed EDITION V" + AyedVersion, 15);
		versionShitA.color = 0x4677FF;
		versionShitA.scrollFactor.set();
		versionShitA.setFormat("VCR OSD Mono", 16, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShitA);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Ayed Engine V" + AyedEngineVersion, 12);
		versionShit.color = 0x1900FF;
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.PINK, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { // It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievementA() {
		add(new AchievementObject('Secret_Song', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "Secret_Song"');
	}
	#end

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievementUi() {
		add(new AchievementObject('MainMenuUi', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "MainMenuUi"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin) {
			FlxG.mouse.wheel;

			if (controls.UI_UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
			if (FlxG.keys.justPressed.F7) {		
				PlatformUtil.sendWindowsNotification("Secret Song Complete", "Your Open The Secret Song 0w0 \n
don't cheating -w-''", 0);
				camGame.shake(0.005, 0.1);
				#if ACHIEVEMENTS_ALLOWED
				// Achievements.loadAchievement();
				var achieveIDsong:Int = Achievements.getAchievementIndex('Secret_Song');
				if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveIDsong][2])) { 
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveIDsong][2], true);
				giveAchievementA();
				ClientPrefs.saveSettings();
				}
				#end
				FlxG.camera.flash(FlxColor.CYAN, 1);
				FlxG.mouse.visible = true;
				PlayState.SONG = Song.loadFromJson('HELL-ON', 'HELL-ON');
				PlayState.isStoryMode = false;
				LoadingState.loadAndSwitchState(new PlayState());
			}
			if (FlxG.keys.justPressed.F10) {
				#if ACHIEVEMENTS_ALLOWED
					var mainMenuUiID:Int = Achievements.getAchievementIndex('MainMenuUi');
					if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[mainMenuUiID][2])) { // It's a mainmenuui weeeeeeeeeeeeeeeeee again
					Achievements.achievementsMap.set(Achievements.achievementsStuff[mainMenuUiID][2], true);
					giveAchievementUi();
					ClientPrefs.saveSettings();
				}
				#end
				FlxG.sound.play(Paths.sound('confirmMenu'));
				MusicBeatState.switchState(new MainMenuUi());
			}

			if (controls.ACCEPT) {
				if (optionShit[curSelected] == 'Discord') {
					CoolUtil.browserLoad('https://discord.gg/H3pfRB6x');
					MusicBeatState.switchState(new MainMenuState());
				} else if (optionShit[curSelected] == 'Quit') {
					FlxG.sound.music.stop();
					MusicBeatState.switchState(new QuitState());
					// Sys.exit(1); // i made new state like next page aaaah nvm but fuck you
				} else {
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if (ClientPrefs.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite) {
						if (curSelected != spr.ID) {
							FlxTween.tween(spr, {x: 900, y: 300}, 1);
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween) {
									spr.kill();
								}
							});
						} else {
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							// FlxTween.tween(FlxG.camera, {zoom: 1.1}, 0.1,{ease:FlxEase.expoInOut});
							FlxFlicker.flicker(spr, 1, 1, false, false, function(flick:FlxFlicker) {
								var daChoice:String = optionShit[curSelected];

								switch (daChoice) {
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										FlxG.sound.music.stop();
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										FlxG.sound.music.stop();
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			// #if desktop
			// else if (FlxG.keys.anyJustPressed(debugKeys))
			// {
			//	selectedSomethin = true;
			//	MusicBeatState.switchState(new MasterEditorMenu());
			// }
			// #end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite) {
			// spr.screenCenter(X);
		});
	}


	function changeItem(huh:Int = 0) {
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});

	
	}
}
