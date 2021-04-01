package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUIButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUITabMenu;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;

#end
import lime.ui.FileDialog;
import lime.app.Event;
import haxe.Json;
import tjson.TJSON;
import Song.SwagSong;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.ui.FileDialogType;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
using StringTools;
typedef TDifficulty = {
	var offset:Int;
	var anim:String;
	var name:String;
}
typedef TDifficulties = {
	var difficulties:Array<TDifficulty>;
	var defaultDiff:Int;
}
class NewSongState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var diffButtons:FlxTypedSpriteGroup<FlxUIButton>;
	var instButton:FlxUIButton;
	var voiceButton:FlxUIButton;
	var coolDiffFiles:Array<String> = [];
	var instPath:String;
	var voicePath:String;	
	var p1Text:FlxUIInputText;
	var p2Text:FlxUIInputText;
	var gfText:FlxUIInputText;
	var isSpooky:FlxUICheckBox;
	var stageText:FlxUIInputText;
	var cutsceneText:FlxUIInputText;
	var uiText:FlxUIInputText;
	var isMoody:FlxUICheckBox;
	var categoryText:FlxUIInputText;
	var finishButton:FlxButton;
	var cancelButton:FlxUIButton;
	var coolFile:FileReference;
	var coolData:ByteArray;
	var epicFiles:Dynamic;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		addCharUi = new FlxUI();
		FlxG.mouse.visible = true;
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		trace('booga ooga');
		trace("hmb");
		p1Text = new FlxUIInputText(100, 50, 70,"bf");
		p2Text = new FlxUIInputText(100,90,70,"dad");
		gfText = new FlxUIInputText(100,130,70,"gf");
		stageText = new FlxUIInputText(100,180,70,"stage");
		cutsceneText = new FlxUIInputText(100,220,70,"none");
		trace("fiodjsj");
		uiText = new FlxUIInputText(100,260,70,"normal");
		nameText = new FlxUIInputText(100,10,70,"bopeebo");
		trace("scloomb");
		isMoody = new FlxUICheckBox(100,290,null,null, "Girls Scared");
		isSpooky = new FlxUICheckBox(100,340,null,null,"Background Trail");
		add(isSpooky);
		trace("beemb");
		categoryText = new FlxUIInputText(100,260,70,"Base Game");
		trace("mood");
			var coolDiffButton1 = new FlxUIButton(10, 10 + (50), "EASY json", function():Void {
				var coolDialog = new FileDialog();
				coolDialog.browse(FileDialogType.OPEN);
				coolDialog.onSelect.add(function (path:String):Void {
					coolDiffFiles[0] = path;
				});
			});
		var coolDiffButton2 = new FlxUIButton(10, 10 + (100), "NORMAL json", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				coolDiffFiles[1] = path;
			});
		});
		var coolDiffButton3 = new FlxUIButton(10, 10 + (150), "HARD json", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				coolDiffFiles[2] = path;
			});
		});
			trace("before add");
			add(coolDiffButton1);
		add(coolDiffButton2);
		add(coolDiffButton3);
		trace("line 107");
		add(nameText);
		add(p1Text);
		add(p2Text);
		add(gfText);
		add(stageText);
		add(cutsceneText);
		add(uiText);
		add(isMoody);
		finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void {
			writeCharacters();
			FlxG.switchState(new OptionsMenu());
		});
		instButton = new FlxUIButton(190, 10, "Instruments", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				instPath = path;
			});
		});
		voiceButton = new FlxUIButton(190, 60, "Vocals", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				voicePath = path;
			});
		});
		cancelButton = new FlxUIButton(FlxG.width - 300, FlxG.height - 50, "Cancel", function():Void {
			// go back
			FlxG.switchState(new OptionsMenu());
		});
		add(instButton);
		add(voiceButton);
		add(finishButton);
		add(cancelButton);
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		// check to see if directory exists
		if (!FileSystem.exists('assets/data/'+nameText.text.toLowerCase())) {
			FileSystem.createDirectory('assets/data/'+nameText.text.toLowerCase());
		}
		for (i in 0...coolDiffFiles.length) {
			if (coolDiffFiles[i] != null) {
				var coolSong:Dynamic = CoolUtil.parseJson(File.getContent(coolDiffFiles[i]));
				var coolSongSong:Dynamic = coolSong.song;
				coolSongSong.song = nameText.text;
				coolSongSong.player1 = p1Text.text;
				coolSongSong.player2 = p2Text.text;
				coolSongSong.gf = gfText.text;
				coolSongSong.stage = stageText.text;
				coolSongSong.uiType = uiText.text;
				coolSongSong.cutsceneType = cutsceneText.text;
				coolSongSong.isMoody = isMoody.checked;
				coolSong.song = coolSongSong;

				var difficulty:String = null;

				switch i
				{
					case 0:
						difficulty = "-easy";
					case 1:
						difficulty = null;
					case 2:
						difficulty = '-hard';
				}

				File.saveContent('assets/data/'+nameText.text.toLowerCase()+'/'+nameText.text.toLowerCase()+difficulty+'.json',CoolUtil.stringifyJson(coolSong));
			}
		}
		// probably breaks on non oggs haha weeeeeeeeeee
		File.copy(instPath,'assets/songs/'+nameText.text+'/Inst.ogg');
		if (voicePath != null) {
			File.copy(voicePath,'assets/songs/'+nameText.text+'/Voices.ogg');
		}
		var coolSongListFile:Array<Dynamic> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
		var foundSomething:Bool = false;
		for (coolCategory in coolSongListFile) {
			if (coolCategory.name == categoryText.text) {
				foundSomething = true; 
				coolCategory.songs.push(nameText.text);
				break;
			}
		}
		if (!foundSomething) {
			// must be a new category
			coolSongListFile.push({"name": categoryText.text, "songs": [nameText.text]});
		}
		File.saveContent('assets/data/freeplaySongJson.jsonc',CoolUtil.stringifyJson(coolSongListFile));
	}
}
