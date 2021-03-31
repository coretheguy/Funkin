package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.system.System;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
using StringTools;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var stageSuffix:String = "";
	var stagePathShit:String = null; //you love to see it

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.curStage;
		var p1 = PlayState.SONG.player1;
		var daBf:String = 'bf';
		trace(p1);
		if (p1 == "bf-pixel") {
			stageSuffix = '-pixel';
		}
		var characterList = Assets.getText('assets/data/characterList.txt');
		if (!StringTools.contains(characterList, p1)) {
			var parsedCharJson:Dynamic = CoolUtil.parseJson(Assets.getText('assets/custom/char/custom_chars.jsonc'));
			//another CTRL+C CTRL+V ritual
			var unparsedAnimJson = File.getContent("assets/custom/char/"+Reflect.field(parsedCharJson,p1).like+".json"); //it might keep throwing an error if i dont do this
			var parsedAnimJson = CoolUtil.parseJson(unparsedAnimJson);
			switch (parsedAnimJson.like) {
				case "bf":
					// bf has a death animation
					daBf = p1;
				case "bf-pixel":
					// gotta deal with this dude
					daBf = p1 + '-dead';
					stageSuffix = '-pixel';
					stagePathShit = 'week6';

				default:
					if (StringTools.contains(unparsedAnimJson, "firstDeath")){ //if i had to build this for any longer i would lose my mind
						daBf = p1; //this should be less shitty
						if (parsedAnimJson.isPixel)
						{
							stageSuffix = '-pixel'; //pixel check!
							stagePathShit = 'week6'; //lmao
						}
					}
					else{
						// just use bf, avoid pain
						daBf = 'bf';
					}
			}
		} else {
			switch (PlayState.SONG.player1) {
				case 'bf':
					daBf = 'bf';
				case 'bf-pixel':
					daBf = 'bf-pixel-dead';
				default:
					daBf = 'bf';
			}
		}
		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix, stagePathShit));
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new PlayState());
				});
			});
		}
	}
}
