package;

import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flash.display.BitmapData;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import lime.system.System;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;

#if windows
import llua.Lua;
import llua.LuaL;
import llua.Convert;
import llua.State;
#end

import tjson.TJSON;
using StringTools;

#if desktop
import Discord.DiscordClient;
#end

using StringTools;

typedef LuaAnim = {
var prefix : String;
    @:optional var indices: Array<Int>;
var name : String;
    @:optional var fps : Int;
    @:optional var loop : Bool;
}

enum abstract DisplayLayer(Int) from Int to Int {
	var BEHIND_GF = 1;
	var BEHIND_BF = 1 << 1;
	var BEHIND_DAD = 1 << 2;
	var BEHIND_ALL = BEHIND_GF | BEHIND_BF | BEHIND_DAD;
}

class PlayState extends MusicBeatState
{
    inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
    public static var curStage:String = '';
    public static var SONG:SwagSong;
    public static var isStoryMode:Bool = false;
    public static var storyWeek:Int = 0;
    public static var storyPlaylist:Array<String> = [];
    public static var storyDifficulty:Int = 1;
    public static var weekSong:Int = 0;
    public static var shits:Int = 0;
    public static var bads:Int = 0;
    public static var goods:Int = 0;
    public static var sicks:Int = 0;

    public static var songPosBG:FlxSprite;
    public static var songPosBar:FlxBar;

    public static var rep:Replay;
    public static var loadRep:Bool = false;

    var halloweenLevel:Bool = false;

    #if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

    private var vocals:FlxSound;

    private var dad:Character;
    private var gf:Character;
    private var boyfriend:Boyfriend;

    private var notes:FlxTypedGroup<Note>;
    private var unspawnNotes:Array<Note> = [];

    private var strumLine:FlxSprite;
    private var curSection:Int = 0;

    private var camFollow:FlxObject;

    private static var prevCamFollow:FlxObject;

    private var strumLineNotes:FlxTypedGroup<FlxSprite>;
    private var playerStrums:FlxTypedGroup<FlxSprite>;
    private var enemyStrums:FlxTypedGroup<FlxSprite>;

    private var camZooming:Bool = false;
    private var curSong:String = "";

    private var strumming2:Array<Bool> = [false, false, false, false];

    private var gfSpeed:Int = 1;
    private var health:Float = 1;
    private var combo:Int = 0;
    public static var misses:Int = 0;
    private var accuracy:Float = 0.00;
    private var totalNotesHit:Float = 0;
    private var totalPlayed:Int = 0;
    private var ss:Bool = false;


    private var healthBarBG:FlxSprite;
    private var healthBar:FlxBar;
    private var songPositionBar:Float = 0;

    private var generatedMusic:Bool = false;
    private var startingSong:Bool = false;

    private var iconP1:HealthIcon;
    private var iconP2:HealthIcon;
    private var camHUD:FlxCamera;
    private var camGame:FlxCamera;

    var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

    var halloweenBG:FlxSprite;
    var isHalloween:Bool = false;

    var phillyCityLights:FlxTypedGroup<FlxSprite>;
    var phillyTrain:FlxSprite;
    var trainSound:FlxSound;

    // this'll work... right?
    var backgroundgroup:FlxTypedGroup<BeatSprite>;
    var foregroundgroup:FlxTypedGroup<BeatSprite>;
    var gffggroup:FlxTypedGroup<BeatSprite>;

    var limo:FlxSprite;
    var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
    var fastCar:FlxSprite;
    var songName:FlxText;
    var upperBoppers:FlxSprite;
    var bottomBoppers:FlxSprite;
    var santa:FlxSprite;

    var fc:Bool = true;

    var bgGirls:BackgroundGirls;
    var wiggleShit:WiggleEffect = new WiggleEffect();

    var talking:Bool = true;
    var songScore:Int = 0;
    var scoreTxt:FlxText;
    var replayTxt:FlxText;


    public static var campaignScore:Int = 0;

    var defaultCamZoom:Float = 1.05;


	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

    var BFstageFollowcamX:Int = 0;
    var BFstageFollowcamY:Int = 0;

    var DADstageFollowcamX:Int = 0;
    var DADstageFollowcamY:Int = 0;

    public static var daPixelZoom:Float = 6;

    var bfoffset = [0.0, 0.0];
    var gfoffset = [0.0, 0.0];
    var dadoffset = [0.0, 0.0];

    public static var theFunne:Bool = true;
    var funneEffect:FlxSprite;
    var inCutscene:Bool = false;
    public static var repPresses:Int = 0;
    public static var repReleases:Int = 0;

    public static var timeCurrently:Float = 0;
    public static var timeCurrentlyR:Float = 0;

    //VARS FOR TRUE CUSTOM STAGE SHIT
    var gfBehind = false;
    var dadBehind = false;
    var BGaboveGF:FlxSprite;
    var BGaboveDAD:FlxSprite;


    /*
    ------------------------------------
    THIS IS WHERE THE LUA STARTS
    ------------------------------------
     */

    //we're not compiling for mac fuck u
	public var luaStates:Map<String, State> = [];
	function callLua(func_name:String, args:Array<Dynamic>, type:String, uselua:String):Dynamic
	{
		var result:Any = null;
		Lua.getglobal(luaStates.get(uselua), func_name);

		for (arg in args)
		{
			Convert.toLua(luaStates.get(uselua), arg);
		}
		Lua.call(luaStates.get(uselua), args.length, 1);

		if (result == null)
		{
			return null;
		}
		else
		{
			return convert(result, type);
		}
	}
	function callAllLua(func_name:String, args:Array<Dynamic>, type:String) {
		for (key in luaStates.keys()) {
			callLua(func_name, args,type,key);
		}
	}
	function setAllVar(var_name:String, object:Dynamic) {
		for (keys in luaStates.keys()) {
			setVar(var_name, object, keys);
		}
	}

	function getType(l, type):Any
	{
		return switch Lua.type(l, type)
		{
			case t if (t == Lua.LUA_TNIL): null;
			case t if (t == Lua.LUA_TNUMBER): Lua.tonumber(l, type);
			case t if (t == Lua.LUA_TSTRING): (Lua.tostring(l, type) : String);
			case t if (t == Lua.LUA_TBOOLEAN): Lua.toboolean(l, type);
			case t: throw 'you don goofed up. lua type error ($t)';
		}
	}
	function makeLuaState(uselua:String, path:String, filename:String) {
		trace('opening a lua state (because we are cool :))');
		luaStates.set(uselua, LuaL.newstate());
		LuaL.openlibs(luaStates.get(uselua));
		trace("Lua version: " + Lua.version());
		trace("LuaJIT version: " + Lua.versionJIT());
		Lua.init_callbacks(luaStates.get(uselua));

		var result = LuaL.dofile(luaStates.get(uselua), path + filename); // execute le file

		if (result != 0)
		{
			luaStates.remove(uselua);
			FlxG.switchState(new MainMenuState());
		}

		// get some fukin globals up in here bois
		setVar("BEHIND_GF", BEHIND_GF, uselua);
		setVar("BEHIND_BF", BEHIND_BF, uselua);
		setVar("BEHIND_DAD", BEHIND_DAD, uselua);
		setVar("BEHIND_ALL", BEHIND_ALL, uselua);
		setVar("BEHIND_NONE", 0, uselua);
		setVar("STATIC_IMAGE", 0, uselua);
		setVar("SPARROW_SHEET", 1, uselua);
		setVar("PACKER_SHEET", 2, uselua);
		trace(PlayState.SONG.isMoody);
		setVar("isMoody", PlayState.SONG.isMoody, uselua);
		setVar("difficulty", storyDifficulty, uselua);
		setVar("bpm", Conductor.bpm, uselua);
		setVar("scrollspeed", PlayState.SONG.speed, uselua);
		//setVar("fpsCap", FlxG.save.data.fpsCap, uselua);
		//setVar("downscroll", FlxG.save.data.downscroll, uselua);

		setVar("curStep", 0, uselua);
		setVar("curBeat", 0, uselua);
		setVar("crochet", Conductor.stepCrochet, uselua);
		setVar("safeZoneOffset", Conductor.safeZoneOffset, uselua);

		setVar("hudZoom", camHUD.zoom, uselua);
		setVar("cameraZoom", FlxG.camera.zoom, uselua);

		setVar("cameraAngle", FlxG.camera.angle, uselua);
		setVar("camHudAngle", camHUD.angle, uselua);

		setVar("followXOffset", 0, uselua);
		setVar("followYOffset", 0, uselua);

		setVar("showOnlyStrums", false, uselua);
		setVar("strumLine1Visible", true, uselua);
		setVar("strumLine2Visible", true, uselua);

		setVar("screenWidth", FlxG.width, uselua);
		setVar("screenHeight", FlxG.height, uselua);
		setVar("hudWidth", camHUD.width, uselua);
		setVar("hudHeight", camHUD.height, uselua);

		setVar("mustHit", false, uselua);

		setVar("strumLineY", strumLine.y, uselua);

		// callbacks

		// sprites

		trace(Lua_helper.add_callback(luaStates.get(uselua), "makeSprite", function(spritePath:String, toBeCalled:String, drawBehind:DisplayLayer, doAnim:Int)
		{
			trace("making sprite");
			var sprite:FlxSprite = new FlxSprite(0, 0);
			if (doAnim == 0)
			{
				sprite.loadGraphic(BitmapData.fromFile(path + spritePath + ".png"));
			}
			else if (doAnim == 1)
			{
				var rawPng = BitmapData.fromFile(path + spritePath + ".png");
				var rawXml = File.getContent(path + spritePath + ".xml");

				sprite.frames = FlxAtlasFrames.fromSparrow(rawPng, rawXml);
			}
			else
			{ //ill do this later, i think they can handle it on their own
				sprite.frames = FlxAtlasFrames.fromSpriteSheetPacker(
					path
					+ spritePath
					+ ".png",
					path
					+ spritePath
					+ ".txt");
			}
			// you usually want this on, make it default.
			sprite.antialiasing = true;
			luaSprites.set(toBeCalled, sprite);
			// and I quote:
			// shitty layering but it works!
			if (drawBehind & BEHIND_GF != 0)
			{
				remove(gf);
			}
			if (drawBehind & BEHIND_DAD != 0)
				remove(dad);
			if (drawBehind & BEHIND_BF != 0)
				remove(boyfriend);

			trace(":)");
			add(sprite);
			if (drawBehind & BEHIND_GF != 0)
			{
				add(gf);
			}
			if (drawBehind & BEHIND_DAD != 0)
				add(dad);
			if (drawBehind & BEHIND_BF != 0)
				add(boyfriend);

			return toBeCalled;
		}));

		Lua_helper.add_callback(luaStates.get(uselua), "destroySprite", function(id:String)
		{
			var sprite = luaSprites.get(id);
			if (sprite == null)
				return false;
			remove(sprite);
			return true;
		});
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addTimer", function(func:String, time:Float)
		{
			new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				callLua(func, [], null, uselua);
			});
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "bitwiseor", function(a:Int, b:Int)
		{
			return a | b;
		}));

		// hud/camera
		trace(Lua_helper.add_callback(luaStates.get(uselua), "trace", function(value:Dynamic)
		{
			trace(value);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "elapsed", function()
		{
			return FlxG.elapsed;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setHudPosition", function(x:Int, y:Int)
		{
			camHUD.x = x;
			camHUD.y = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "newArray", function(id:String)
		{
			luaArray.set(id, []);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "pushArray", function(value:Any, id:String)
		{
			luaArray.get(id).push(value);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "popArray", function(id:String)
		{
			return luaArray.get(id).pop();
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "newRangeArray", function(min:Int, max:Int, id:String)
		{
			var coolarray:Array<Any> = [];
			// keep lua inclusive
			for (i in min...(max + 1))
			{
				coolarray.push(i);
			}
			luaArray.set(id, coolarray);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorFollowCam", function(x:Int, y:Int, id:String)
		{
			getActorByName(id).followCamX = x;
			getActorByName(id).followCamY = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorFollowCamX", function(id:String)
		{
			return getActorByName(id).followCamX;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getCurChar", function(id:String)
		{
			return getActorByName(id).curCharacter;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "isCharLike", function(char:String, id:String)
		{
			return getActorByName(id).like == char;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "makeActorPixel", function(id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * 6));
			getActorByName(id).updateHitbox();
			getActorByName(id).antialiasing = false;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorFollowCamY", function(id:String)
		{
			return getActorByName(id).followCamY;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimationPrefix", function(prefix:String, name:String, fps:Int, loop:Bool, id:String)
		{
			getActorByName(id).animation.addByPrefix(name, prefix, fps, loop);
			trace(getActorByName(id).animation);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimationIndices", function(prefix:String, name:String, indices:String, fps:Int, id:String)
		{
			trace(luaArray.get(indices));
			getActorByName(id).animation.addByIndices(name, prefix, luaArray.get(indices), "", fps, false);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addActorAnimation",
			function(name:String, indices:String, fps:Int, loop:Bool, id:String)
			{
				trace(luaArray.get(indices));
			getActorByName(id).animation.add(name, luaArray.get(indices), fps, loop);
			}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "playActorAnimation", function(animation:String, force:Bool, id:String)
		{
			//trace(animation); //STOP TRACING!!!
			getActorByName(id).animation.play(animation, force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playCharacterAnimation", function(animation:String, force:Bool, id:String)
		{
			getActorByName(id).playAnim(animation, force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getHudX", function()
		{
			return camHUD.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getHudY", function()
		{
			return camHUD.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setCamPosition", function(x:Int, y:Int)
		{
			FlxG.camera.x = x;
			FlxG.camera.y = y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playSound", function(filename1:String)
		{
			FlxG.sound.play(path + filename1 + '.ogg');
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "playStoredSound", function(force:Bool, id:String)
		{
			luaSound.get(id).play(force);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getSoundPlaying", function(id:String)
		{
			return luaSound.get(id).playing;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getCameraX", function()
		{
			return FlxG.camera.x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "addSoundToList", function(filename1:String, tobecalled:String)
		{
			luaSound.set(tobecalled, new FlxSound().loadEmbedded(path + filename1 + '.ogg'));
			FlxG.sound.list.add(luaSound.get(tobecalled));
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getSoundTime", function(id:String)
		{
			return luaSound.get(id).time;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getCameraY", function()
		{
			return FlxG.camera.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setCamZoom", function(zoomAmount:Float)
		{
			FlxG.camera.zoom = zoomAmount;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setDefaultZoom", function(zoomAmount:Float)
		{
			FlxG.camera.zoom = zoomAmount;
			defaultCamZoom = zoomAmount;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setHudZoom", function(zoomAmount:Float)
		{
			camHUD.zoom = zoomAmount;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorX", function(x:Int, id:String)
		{
			getActorByName(id).x = x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorVelocityX", function(x:Int, id:String)
		{
			getActorByName(id).velocity.x = x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAlpha", function(alpha:Int, id:String)
		{
			getActorByName(id).alpha = alpha;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNotes", function()
		{
			return notes.length;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteX", function(id:Int)
		{
			return notes.members[id].x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteY", function(id:Int)
		{
			return notes.members[id].y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteType", function(id:Int)
		{
			return notes.members[id].noteData;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "isSustain", function(id:Int)
		{
			return notes.members[id].isSustainNote;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "isParentSustain", function(id:Int)
		{
			return notes.members[id].prevNote.isSustainNote;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteParentX", function(id:Int)
		{
			return notes.members[id].prevNote.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteParentY", function(id:Int)
		{
			return notes.members[id].prevNote.y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteHit", function(id:Int)
		{
			return notes.members[id].mustPress;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteCalcX", function(id:Int)
		{
			if (notes.members[id].mustPress)
				return playerStrums.members[Math.floor(Math.abs(notes.members[id].noteData))].x;
			return strumLineNotes.members[Math.floor(Math.abs(notes.members[id].noteData))].x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "anyNotes", function()
		{
			return notes.members.length != 0;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteStrumtime", function(id:Int)
		{
			return notes.members[id].strumTime;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteScaleX", function(id:Int)
		{
			return notes.members[id].scale.x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNotePos", function(x:Float, y:Float, id:Int)
		{
			if (notes.members[id] == null)
				throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
			else
			{
				notes.members[id].modifiedByLua = true;
				notes.members[id].x = x;
				notes.members[id].y = y;
			}
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteAlpha", function(alpha:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].alpha = alpha;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteScale", function(scale:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].setGraphicSize(Std.int(notes.members[id].width * scale));
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].setGraphicSize(scaleX, scaleY);
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getRenderedNoteWidth", function(id:Int)
		{
			return notes.members[id].width;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setRenderedNoteAngle", function(angle:Float, id:Int)
		{
			notes.members[id].modifiedByLua = true;
			notes.members[id].angle = angle;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorY", function(y:Int, id:String)
		{
			getActorByName(id).y = y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorVelocityY", function(y:Int, id:String)
		{
			getActorByName(id).velocity.y = y;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAngle", function(angle:Int, id:String)
		{
			getActorByName(id).angle = angle;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScale", function(scale:Float, id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
			getActorByName(id).updateHitbox();
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScaleMember", function(scale:Float, id:String)
		{
			trace(getActorByName(id).scale.x);
			getActorByName(id).scale.set(scale, scale);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getScaleX", function(id:String)
		{
			return getActorByName(id).scale.x;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getScaleY", function(id:String)
		{
			return getActorByName(id).scale.y;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorAntialias", function(antialias:Bool, id:String)
		{
			getActorByName(id).antialiasing = antialias;
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "setActorScrollFactor", function(factorx:Float, factory:Float, id:String)
		{
			getActorByName(id).scrollFactor.set(factorx, factory);
		}));
		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorWidth", function(id:String)
		{
			return getActorByName(id).width;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorHeight", function(id:String)
		{
			return getActorByName(id).height;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorAlpha", function(id:String)
		{
			return getActorByName(id).alpha;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorAngle", function(id:String)
		{
			return getActorByName(id).angle;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorX", function(id:String)
		{
			return getActorByName(id).x;
		}));

		trace(Lua_helper.add_callback(luaStates.get(uselua), "getActorY", function(id:String)
		{
			return getActorByName(id).y;
		}));

		// tweens

		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});
		Lua_helper.add_callback(luaStates.get(uselua), "shakeCamera", function(intensity:Float,time:Float, onComplete:String)
		{
			FlxG.camera.shake(intensity,time,function() {
				if (onComplete != '' && onComplete != null)
				{
					callLua(onComplete, ["camera"], null, uselua);
				}
			});
		});
		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(FlxG.camera, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(camHUD, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, ["camera"], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenFadeIn", function(id:String, toAlpha:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circIn,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});

		Lua_helper.add_callback(luaStates.get(uselua), "tweenFadeOut", function(id:String, toAlpha:Int, time:Float, onComplete:String)
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circOut,
				onComplete: function(flxTween:FlxTween)
				{
					if (onComplete != '' && onComplete != null)
					{
						callLua(onComplete, [id], null, uselua);
					}
				}
			});
		});


		for (i in 0...strumLineNotes.length)
		{
			var member = strumLineNotes.members[i];
			trace(strumLineNotes.members[i].x + " " + strumLineNotes.members[i].y + " " + strumLineNotes.members[i].angle + " | strum" + i);
			// setVar("strum" + i + "X", Math.floor(member.x));
			setVar("defaultStrum" + i + "X", Math.floor(member.x), uselua);
			// setVar("strum" + i + "Y", Math.floor(member.y));
			setVar("defaultStrum" + i + "Y", Math.floor(member.y), uselua);
			// setVar("strum" + i + "Angle", Math.floor(member.angle));
			setVar("defaultStrum" + i + "Angle", Math.floor(member.angle), uselua);
			trace("Adding strum" + i);
		}

		trace('calling start function');

		trace('return: ' + Lua.tostring(luaStates.get(uselua), callLua('start', [PlayState.SONG.song], null, uselua)));
	}
	function getReturnValues(l)
	{
		var lua_v:Int;
		var v:Any = null;
		while ((lua_v = Lua.gettop(l)) != 0)
		{
			var type:String = getType(l, lua_v);
			v = convert(lua_v, type);
			Lua.pop(l, 1);
		}
		return v;
	}

	private function convert(v:Any, type:String):Dynamic
	{ // I didn't write this lol
		if (Std.is(v, String) && type != null)
		{
			var v:String = v;
			if (type.substr(0, 4) == 'array')
			{
				trace("array");
				if (type.substr(4) == 'float')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseFloat(vars));
					}

					return array2;
				}
				else if (type.substr(4) == 'int')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseInt(vars));
					}

					return array2;
				}
				else
				{
					var array:Array<String> = v.split(',');
					return array;
				}
			}
			else if (type == 'float')
			{
				return Std.parseFloat(v);
			}
			else if (type == 'int')
			{
				return Std.parseInt(v);
			}
			else if (type == 'bool')
			{
				if (v == 'true')
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return v;
			}
		}
		else
		{
			return v;
		}
	}

	function getLuaErrorMessage(l)
	{
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function setVar(var_name:String, object:Dynamic, uselua:String)
	{
		// trace('setting variable ' + var_name + ' to ' + object);
		Lua.pushnumber(luaStates.get(uselua), object);
		Lua.setglobal(luaStates.get(uselua), var_name);
	}

	public function getVar(var_name:String, type:String, uselua:String):Dynamic
	{
		var result:Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(luaStates.get(uselua), var_name);
		result = Convert.fromLua(luaStates.get(uselua), -1);
		Lua.pop(luaStates.get(uselua), 1);

		if (result == null)
		{
			return null;
		}
		else
		{
			var result = convert(result, type);
			// trace(var_name + ' result: ' + result);
			return result;
		}
	}

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch (id)
		{
			case 'boyfriend':
				return boyfriend;
			case 'girlfriend' | 'gf':
				return gf;
			case 'dad':
				return dad;
		}
		// lua objects or what ever
		if (luaSprites.get(id) == null)
			return strumLineNotes.members[Std.parseInt(id)];
		return luaSprites.get(id);
	}

	public static var luaSprites:Map<String, FlxSprite> = [];
	var luaSound:Map<String, FlxSound> = [];
	var luaArray:Map<String, Array<Any>> = [];

    /*
    ------------------------------------
    THIS IS WHERE THE LUA ENDS
    ------------------------------------
     */


    override public function create()
    {

        if (FlxG.save.data.etternaMode)
            Conductor.safeFrames = 5; // 116ms hit window (j3-4)
        else
            Conductor.safeFrames = 10; // 166ms hit window (j1)


        theFunne = FlxG.save.data.newInput;
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        sicks = 0;
        bads = 0;
        shits = 0;
        goods = 0;

        misses = 0;

        repPresses = 0;
        repReleases = 0;

        #if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "\nAcc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end


        // var gameCam:FlxCamera = FlxG.camera;
        camGame = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;

        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camHUD);

        FlxCamera.defaultCameras = [camGame];

        persistentUpdate = true;
        persistentDraw = true;

        if (SONG == null)
            SONG = Song.loadFromJson('tutorial');

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		var sploosh = new NoteSplash(100, 100, 0);
		sploosh.alpha = 0.1;
		grpNoteSplashes.add(sploosh);

        Conductor.mapBPMChanges(SONG);
        Conductor.changeBPM(SONG.bpm);

        switch (SONG.song.toLowerCase())
        {
            case 'tutorial':
                dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
            case 'bopeebo':
                dialogue = [
                    'HEY!',
                    "You think you can just sing\nwith my daughter like that?",
                    "If you want to date her...",
                    "You're going to have to go \nthrough ME first!"
                ];
            case 'fresh':
                dialogue = ["Not too shabby boy.", ""];
            case 'dadbattle':
                dialogue = [
                    "gah you think you're hot stuff?",
                    "If you can beat me here...",
                    "Only then I will even CONSIDER letting you\ndate my daughter!"
                ];
            case 'senpai':
                dialogue = CoolUtil.coolTextFile(Paths.txt('senpai/senpaiDialogue'));
            case 'roses':
                dialogue = CoolUtil.coolTextFile(Paths.txt('roses/rosesDialogue'));
            case 'thorns':
                dialogue = CoolUtil.coolTextFile(Paths.txt('thorns/thornsDialogue'));
            /*default: // this WILL break because kade engine so work on it later
                // prefer player 1
                if (FileSystem.exists('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
                    dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt');
                    // if no player 1 unique dialog, use player 2
                } else if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
                    dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt');
                    // if no player dialog, use default
                }	else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt')) {
                    dialogue = CoolUtil.coolDynamicTextFile('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt');
                } else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/dialogue.txt')){
                    // nerds spell dialogue properly gotta make em happy
                    dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialogue.txt');
                    // otherwise, make the dialog an error message
                } else {
                    dialogue = [':dad: The game tried to get a dialog file but couldn\'t find it. Please make sure there is a dialog file named "dialog.txt".'];
                }*/
        }



        var gfVersion:String = 'gf';

        gfVersion = SONG.gf;

        if (curStage == 'limo')
            gfVersion = 'gf-car';

        gf = new Character(400, 130, gfVersion);
        gf.scrollFactor.set(0.95, 0.95);

        dad = new Character(100, 100, SONG.player2);

        var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

        switch (SONG.player2)
        {
            case 'gf':
                dad.setPosition(gf.x, gf.y);
                gf.visible = false;
                if (isStoryMode)
                {
                    camPos.x += 600;
                    tweenCamIn();
                }

            case "spooky":
                dad.y += 200;
            case "monster":
                dad.y += 100;
            case 'monster-christmas':
                dad.y += 130;
            case 'dad':
                camPos.x += 400;
            case 'pico':
                camPos.x += 600;
                dad.y += 300;
            case 'parents-christmas':
                dad.x -= 500;
            case 'senpai':
                dad.x += 150;
                dad.y += 360;
                camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
            case 'senpai-angry':
                dad.x += 150;
                dad.y += 360;
                camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
            case 'spirit':
                dad.x -= 150;
                dad.y += 100;
                camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
            default:
                /*if(curStage == 'custom'){
                    var customStageJson:FunkinUtility.Stage = new json2object.JsonParser<FunkinUtility.Stage>().fromJson(File.getContent("assets/custom/stage/" + SONG.stage + ".json"));
                    dad.x += customStageJson.enemyoffsetX;
                    dad.y += customStageJson.enemyoffsetY;
                }*/
                dad.x += dad.enemyOffsetX;
                dad.y += dad.enemyOffsetY;
                camPos.x += dad.camOffsetX;
                camPos.y += dad.camOffsetY;
                if (dad.likeGf) {
                    dad.setPosition(gf.x, gf.y);
                    gf.visible = false;
                    if (isStoryMode)
                    {
                        camPos.x += 600;
                        tweenCamIn();
                    }
                }
        }



        boyfriend = new Boyfriend(770, 450, SONG.player1);
        switch (SONG.player1) // no clue why i didnt think of this before lol
        {
            default:
                /*if(curStage == 'custom'){
                var customStageJson:FunkinUtility.Stage = new json2object.JsonParser<FunkinUtility.Stage>().fromJson(File.getContent("assets/custom/stage/" + SONG.stage + ".json"));
                boyfriend.x += customStageJson.bfoffsetX; //just use sprite offsets
                boyfriend.y += customStageJson.bfoffsetY;
                }*/
                boyfriend.x += boyfriend.enemyOffsetX; //just use sprite offsets
                boyfriend.y += boyfriend.enemyOffsetY;
                camPos.x += boyfriend.camOffsetX;
                camPos.y += boyfriend.camOffsetY;
                if (boyfriend.likeGf) {
                    boyfriend.setPosition(gf.x, gf.y);
                    boyfriend.flipX = false;
                    gf.visible = false;
                    if (isStoryMode)
                    {
                        camPos.x += 600;
                        tweenCamIn();
                    }
                }
        }

        // REPOSITIONING PER STAGE
        switch (curStage)
        {
            case 'limo':
                boyfriend.y -= 220;
                boyfriend.x += 260;

                resetFastCar();
                add(fastCar);

            case 'mall':
                boyfriend.x += 200;

            case 'mallEvil':
                boyfriend.x += 320;
                dad.y -= 80;
            case 'school':
                boyfriend.x += 200;
                boyfriend.y += 220;
                gf.x += 180;
                gf.y += 300;
            case 'schoolEvil':
                // trailArea.scrollFactor.set();

                var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
                // evilTrail.changeValuesEnabled(false, false, false, false);
                // evilTrail.changeGraphic()
                add(evilTrail);
                // evilTrail.scrollFactor.set(1.1, 1.1);

                boyfriend.x += 200;
                boyfriend.y += 220;
                gf.x += 180;
                gf.y += 300;
            default:
                boyfriend.x += bfoffset[0];
                boyfriend.y += bfoffset[1];
                gf.x += gfoffset[0];
                gf.y += gfoffset[1];
                dad.x += dadoffset[0];
                dad.y += dadoffset[1];
        }

        add(gf);


        /*if(curStage == 'custom'){

            var parsedStageJson = CoolUtil.parseJson(File.getContent("assets/custom/stage/custom_stages.json"));
            var parsedFuckeeJson:FunkinUtility.Stage = new json2object.JsonParser<FunkinUtility.Stage>().fromJson(File.getContent("assets/custom/stage/"
            + SONG.stage + ".json"));

        foregroundgroup = new FlxTypedGroup<BeatSprite>();
        add(foregroundgroup);

            for (stage in parsedFuckeeJson.stages) {
            if (stage.name == "front") {
                for (sprite in stage.sprites)
                {
                    sprite.graphicpath = "assets/custom/stage/" + SONG.stage+"/";
                    var coolsprite:BeatSprite = sprite.convertToBeatSprite();
                    foregroundgroup.add(coolsprite);
                    trace(backgroundgroup.members);
                }
            }}

        }*/



        // Shitty layering but whatev it works LOL
        if (curStage == 'limo')
            add(limo);

        add(dad);

        add(boyfriend);

        /*if(boyfriend.zoom  == 1.0) //default catch
            boyfriend.zoom = defaultCamZoom;

        if(dad.zoom  == 1.0) //default catch 2
            dad.zoom = defaultCamZoom;*/

        var doof:DialogueBox = new DialogueBox(false, dialogue);
        // doof.x += 70;
        // doof.y = FlxG.height * 0.5;
        doof.scrollFactor.set();
        doof.finishThing = startCountdown;

        Conductor.songPosition = -5000;


        strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
        strumLine.scrollFactor.set();

        if (FlxG.save.data.downscroll)
            strumLine.y = FlxG.height - 165;

        strumLineNotes = new FlxTypedGroup<FlxSprite>();
        add(strumLineNotes);

		add(grpNoteSplashes);

        playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();

        // startCountdown();

        generateSong(SONG.song);

        // add(strumLine);

        camFollow = new FlxObject(0, 0, 1, 1);

        camFollow.setPosition(camPos.x, camPos.y);

        if (prevCamFollow != null)
        {
            camFollow = prevCamFollow;
            prevCamFollow = null;
        }

        add(camFollow);

        FlxG.camera.follow(camFollow, LOCKON, 0.01);
        // FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
        FlxG.camera.zoom = defaultCamZoom;
        FlxG.camera.focusOn(camFollow.getPosition());

        FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

        FlxG.fixedTimestep = false;

        if (FlxG.save.data.songPosition) // I dont wanna talk about this code :(
        {
            songPosBG = new FlxSprite(0, strumLine.y - 15).loadGraphic(Paths.image('healthBar'));
            if (FlxG.save.data.downscroll)
                songPosBG.y = FlxG.height * 0.9 + 45;
            songPosBG.screenCenter(X);
            songPosBG.scrollFactor.set();
            add(songPosBG);

            if (curStage.contains("school") && FlxG.save.data.downscroll)
                songPosBG.y -= 45;
            if (!curStage.contains("school") && !FlxG.save.data.downscroll)
                songPosBG.y -= 45;

            songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
            'songPositionBar', 0, 90000);
            songPosBar.scrollFactor.set();
            songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
            add(songPosBar);

            var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
            if (FlxG.save.data.downscroll)
                songName.y -= 3;
            if (!curStage.contains("school"))
                songName.x -= 15;
            songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
            songName.scrollFactor.set();
            add(songName);
        }

        healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
        if (FlxG.save.data.downscroll)
            healthBarBG.y = 50;
        healthBarBG.screenCenter(X);
        healthBarBG.scrollFactor.set();
        add(healthBarBG);

        healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
        'health', 0, 2);
        healthBar.scrollFactor.set();
        healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
        // healthBar
        add(healthBar);

        // Add Kade Engine watermark
        var kadeEngineWatermark = new FlxText(FlxG.width * 0.03,FlxG.height * 0.94,0,SONG.song + " " + (storyDifficulty == 2 ? "Hard" : storyDifficulty == 1 ? "Normal" : "Easy") + " - KE " + MainMenuState.kadeEngineVer, 16);
        kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        kadeEngineWatermark.scrollFactor.set();
        add(kadeEngineWatermark);

        scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 180, healthBarBG.y + 50, 0, "", 20);
        if (!FlxG.save.data.accuracyDisplay)
            scoreTxt.x = healthBarBG.x + healthBarBG.width / 2;
        scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        scoreTxt.scrollFactor.set();
        add(scoreTxt);

        replayTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "REPLAY", 20);
        replayTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        replayTxt.scrollFactor.set();
        if (loadRep)
        {
            add(replayTxt);
        }

        iconP1 = new HealthIcon(SONG.player1, true);
        iconP1.y = healthBar.y - (iconP1.height / 2);
        add(iconP1);

        iconP2 = new HealthIcon(SONG.player2, false);
        iconP2.y = healthBar.y - (iconP2.height / 2);
        add(iconP2);

		grpNoteSplashes.cameras = [camHUD];
        strumLineNotes.cameras = [camHUD];
        notes.cameras = [camHUD];
        healthBar.cameras = [camHUD];
        healthBarBG.cameras = [camHUD];
        iconP1.cameras = [camHUD];
        iconP2.cameras = [camHUD];
        scoreTxt.cameras = [camHUD];
        doof.cameras = [camHUD];

        // if (SONG.song == 'South')
        // FlxG.camera.alpha = 0.7;
        // UI_camera.zoom = 1;

        // cameras = [FlxG.cameras.list[1]];
        startingSong = true;

		if (FileSystem.exists("assets/custom/stage/" + SONG.stage + "/process.lua")) // dude I hate lua (jkjkjkjk)
		{
			makeLuaState("stages", "assets/custom/stage/"+SONG.stage+"/", "process.lua");
		}

        if (isStoryMode)
        {
            switch (curSong.toLowerCase())
            {
                case "winter-horrorland":
                    var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
                    add(blackScreen);
                    blackScreen.scrollFactor.set();
                    camHUD.visible = false;

                    new FlxTimer().start(0.1, function(tmr:FlxTimer)
                    {
                        remove(blackScreen);
                        FlxG.sound.play(Paths.sound('Lights_Turn_On'));
                        camFollow.y = -2050;
                        camFollow.x += 200;
                        FlxG.camera.focusOn(camFollow.getPosition());
                        FlxG.camera.zoom = 1.5;

                        new FlxTimer().start(0.8, function(tmr:FlxTimer)
                        {
                            camHUD.visible = true;
                            remove(blackScreen);
                            FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
                                ease: FlxEase.quadInOut,
                                onComplete: function(twn:FlxTween)
                                {
                                    startCountdown();
                                }
                            });
                        });
                    });
                case 'senpai':
                    schoolIntro(doof);
                case 'roses':
                    FlxG.sound.play(Paths.sound('ANGRY'));
                    schoolIntro(doof);
                case 'thorns':
                    schoolIntro(doof);
                default:
                    startCountdown();
            }
        }
        else
        {
            switch (curSong.toLowerCase())
            {
                default:
                    startCountdown();
            }
        }

        if (!loadRep)
            rep = new Replay("na");

        super.create();
    }

    function schoolIntro(?dialogueBox:DialogueBox):Void
    {
        var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
        black.scrollFactor.set();
        add(black);

        var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
        red.scrollFactor.set();

        var senpaiEvil:FlxSprite = new FlxSprite();
        senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy', 'week6');
        senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
        senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
        senpaiEvil.scrollFactor.set();
        senpaiEvil.updateHitbox();
        senpaiEvil.screenCenter();

        if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
        {
            remove(black);

            if (SONG.song.toLowerCase() == 'thorns')
            {
                add(red);
            }
        }

        new FlxTimer().start(0.3, function(tmr:FlxTimer)
        {
            black.alpha -= 0.15;

            if (black.alpha > 0)
            {
                tmr.reset(0.3);
            }
            else
            {
                if (dialogueBox != null)
                {
                    inCutscene = true;

                    if (SONG.song.toLowerCase() == 'thorns')
                    {
                        add(senpaiEvil);
                        senpaiEvil.alpha = 0;
                        new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
                        {
                            senpaiEvil.alpha += 0.15;
                            if (senpaiEvil.alpha < 1)
                            {
                                swagTimer.reset();
                            }
                            else
                            {
                                senpaiEvil.animation.play('idle');
                                FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
                                {
                                    remove(senpaiEvil);
                                    remove(red);
                                    FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
                                    {
                                        add(dialogueBox);
                                    }, true);
                                });
                                new FlxTimer().start(3.2, function(deadTime:FlxTimer)
                                {
                                    FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
                                });
                            }
                        });
                    }
                    else
                    {
                        add(dialogueBox);
                    }
                }
                else
                    startCountdown();

                remove(black);
            }
        });
    }

    var startTimer:FlxTimer;
    var perfectMode:Bool = false;

    function startCountdown():Void
    {
        inCutscene = false;

        generateStaticArrows(0);
        generateStaticArrows(1);


        if (FileSystem.exists("assets/data/" + SONG.song.toLowerCase() + "/modchart.lua")) // dude I hate lua (jkjkjkjk)
        {
            makeLuaState("modchart", "assets/data/" + SONG.song.toLowerCase() + "/", "/modchart.lua");
        }

        talking = false;
        startedCountdown = true;
        Conductor.songPosition = 0;
        Conductor.songPosition -= Conductor.crochet * 5;

        var swagCounter:Int = 0;

        startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
        {
            dad.dance();
            gf.dance();
            boyfriend.playAnim('idle');

            var introPixelPartShit:String = null;

            var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
            introAssets.set('default', ['ready', "set", "go"]);
            introAssets.set('school', [
                'weeb/pixelUI/ready-pixel',
                'weeb/pixelUI/set-pixel',
                'weeb/pixelUI/date-pixel'
            ]);
            introAssets.set('schoolEvil', [
                'weeb/pixelUI/ready-pixel',
                'weeb/pixelUI/set-pixel',
                'weeb/pixelUI/date-pixel'
            ]);

            if (curStage == 'school' || curStage == 'schoolEvil')
            {
                introPixelPartShit = 'week6';
            }

            var introAlts:Array<String> = introAssets.get('default');
            var altSuffix:String = "";

            for (value in introAssets.keys())
            {
                if (value == curStage)
                {
                    introAlts = introAssets.get(value);
                    altSuffix = '-pixel';
                }
            }

            switch (swagCounter)

            {
                case 0:
                    FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
                case 1:
                    var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]), introPixelPartShit);
                    ready.scrollFactor.set();
                    ready.updateHitbox();

                    if (curStage.startsWith('school'))
                        ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

                    ready.screenCenter();
                    add(ready);
                    FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
                        ease: FlxEase.cubeInOut,
                        onComplete: function(twn:FlxTween)
                        {
                            ready.destroy();
                        }
                    });
                    FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
                case 2:
                    var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]), introPixelPartShit);
                    set.scrollFactor.set();

                    if (curStage.startsWith('school'))
                        set.setGraphicSize(Std.int(set.width * daPixelZoom));

                    set.screenCenter();
                    add(set);
                    FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
                        ease: FlxEase.cubeInOut,
                        onComplete: function(twn:FlxTween)
                        {
                            set.destroy();
                        }
                    });
                    FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
                case 3:
                    var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]), introPixelPartShit);
                    go.scrollFactor.set();

                    if (curStage.startsWith('school'))
                        go.setGraphicSize(Std.int(go.width * daPixelZoom));

                    go.updateHitbox();

                    go.screenCenter();
                    add(go);
                    FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
                        ease: FlxEase.cubeInOut,
                        onComplete: function(twn:FlxTween)
                        {
                            go.destroy();
                        }
                    });
                    FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
                case 4:
            }

            swagCounter += 1;
            // generateSong('fresh');
        }, 5);
    }

    var previousFrameTime:Int = 0;
    var lastReportedPlayheadPosition:Int = 0;
    var songTime:Float = 0;

    function startSong():Void
    {
        startingSong = false;

        previousFrameTime = FlxG.game.ticks;
        lastReportedPlayheadPosition = 0;

        if (!paused)
            FlxG.sound.playMusic(Sound.fromFile("assets/songs/"+SONG.song+"/Inst."+SOUND_EXT));

        FlxG.sound.music.onComplete = endSong;
        vocals.play();

        if (FlxG.save.data.songPosition)
        {
            remove(songPosBG);
            remove(songPosBar);
            remove(songName);

            songPosBG = new FlxSprite(0, strumLine.y - 15).loadGraphic(Paths.image('healthBar'));
            if (FlxG.save.data.downscroll)
                songPosBG.y = FlxG.height * 0.9 + 45;
            if (!curStage.contains("school") && !FlxG.save.data.downscroll)
                songPosBG.y -= 45;
            songPosBG.screenCenter(X);
            songPosBG.scrollFactor.set();
            add(songPosBG);

            if (curStage.contains("school") && FlxG.save.data.downscroll)
                songPosBG.y -= 45;

            songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
            'songPositionBar', 0, 90000);
            songPosBar.scrollFactor.set();
            songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
            add(songPosBar);

            var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
            if (FlxG.save.data.downscroll)
                songName.y -= 3;
            if (!curStage.contains("school"))
                songName.x -= 15;
            songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
            songName.scrollFactor.set();
            add(songName);
        }

        #if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)



		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "\nAcc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end
    }

    var debugNum:Int = 0;

    private function generateSong(dataPath:String):Void
    {
        // FlxG.log.add(ChartParser.parse());

        var songData = SONG;
        Conductor.changeBPM(songData.bpm);

        curSong = songData.song;

        if (SONG.needsVoices)
        {
            var vocalSound = Sound.fromFile("assets/songs/"+SONG.song+"/Voices."+SOUND_EXT);
            vocals = new FlxSound().loadEmbedded(vocalSound);
        }
        else
            vocals = new FlxSound();

        FlxG.sound.list.add(vocals);

        notes = new FlxTypedGroup<Note>();
        add(notes);

        var noteData:Array<SwagSection>;

        // NEW SHIT
        noteData = songData.notes;

        var playerCounter:Int = 0;

        var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
        for (section in noteData)
        {
            var coolSection:Int = Std.int(section.lengthInSteps / 4);

            for (songNotes in section.sectionNotes)
            {
                var daStrumTime:Float = songNotes[0];
                var daNoteData:Int = Std.int(songNotes[1] % 4);

                var gottaHitNote:Bool = section.mustHitSection;

                if (songNotes[1] > 3)
                {
                    gottaHitNote = !section.mustHitSection;
                }

                var oldNote:Note;
                if (unspawnNotes.length > 0)
                    oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
                else
                    oldNote = null;

                var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
                swagNote.sustainLength = songNotes[2];
                swagNote.scrollFactor.set(0, 0);

                var susLength:Float = swagNote.sustainLength;

                susLength = susLength / Conductor.stepCrochet;
                unspawnNotes.push(swagNote);

                for (susNote in 0...Math.floor(susLength))
                {
                    oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

                    var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
                    sustainNote.scrollFactor.set();
                    unspawnNotes.push(sustainNote);

                    sustainNote.mustPress = gottaHitNote;

                    if (sustainNote.mustPress)
                    {
                        sustainNote.x += FlxG.width / 2; // general offset
                    }
                }

                swagNote.mustPress = gottaHitNote;

                if (swagNote.mustPress)
                {
                    swagNote.x += FlxG.width / 2; // general offset
                }
                else
                {
                }
            }
            daBeats += 1;
        }

        // trace(unspawnNotes.length);
        // playerCounter += 1;

        unspawnNotes.sort(sortByShit);

        generatedMusic = true;
    }

    function sortByShit(Obj1:Note, Obj2:Note):Int
    {
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
    }

    private function generateStaticArrows(player:Int):Void
    {
        for (i in 0...4)
        {
            // FlxG.log.add(i);
            var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);

            switch (curStage)
            {
                case 'school' | 'schoolEvil':
                    babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
                    babyArrow.animation.add('green', [6]);
                    babyArrow.animation.add('red', [7]);
                    babyArrow.animation.add('blue', [5]);
                    babyArrow.animation.add('purplel', [4]);

                    babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
                    babyArrow.updateHitbox();
                    babyArrow.antialiasing = false;

                    switch (Math.abs(i))
                    {
                        case 0:
                            babyArrow.x += Note.swagWidth * 0;
                            babyArrow.animation.add('static', [0]);
                            babyArrow.animation.add('pressed', [4, 8], 12, false);
                            babyArrow.animation.add('confirm', [12, 16], 24, false);
                        case 1:
                            babyArrow.x += Note.swagWidth * 1;
                            babyArrow.animation.add('static', [1]);
                            babyArrow.animation.add('pressed', [5, 9], 12, false);
                            babyArrow.animation.add('confirm', [13, 17], 24, false);
                        case 2:
                            babyArrow.x += Note.swagWidth * 2;
                            babyArrow.animation.add('static', [2]);
                            babyArrow.animation.add('pressed', [6, 10], 12, false);
                            babyArrow.animation.add('confirm', [14, 18], 12, false);
                        case 3:
                            babyArrow.x += Note.swagWidth * 3;
                            babyArrow.animation.add('static', [3]);
                            babyArrow.animation.add('pressed', [7, 11], 12, false);
                            babyArrow.animation.add('confirm', [15, 19], 24, false);
                    }

                default:
                    babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
                    babyArrow.animation.addByPrefix('green', 'arrowUP');
                    babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
                    babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
                    babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

                    babyArrow.antialiasing = true;
                    babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

                    switch (Math.abs(i))
                    {
                        case 0:
                            babyArrow.x += Note.swagWidth * 0;
                            babyArrow.animation.addByPrefix('static', 'arrowLEFT');
                            babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
                            babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
                        case 1:
                            babyArrow.x += Note.swagWidth * 1;
                            babyArrow.animation.addByPrefix('static', 'arrowDOWN');
                            babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
                            babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
                        case 2:
                            babyArrow.x += Note.swagWidth * 2;
                            babyArrow.animation.addByPrefix('static', 'arrowUP');
                            babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
                            babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
                        case 3:
                            babyArrow.x += Note.swagWidth * 3;
                            babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
                            babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
                            babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
                    }
            }

            babyArrow.updateHitbox();
            babyArrow.scrollFactor.set();

            if (!isStoryMode)
            {
                babyArrow.y -= 10;
                babyArrow.alpha = 0;
                FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
            }

            babyArrow.ID = i;

            if (player == 1)
            {
                playerStrums.add(babyArrow);
            }

            babyArrow.animation.play('static');
            babyArrow.x += 50;
            babyArrow.x += ((FlxG.width / 2) * player);

            strumLineNotes.add(babyArrow);
        }
    }

    function tweenCamIn():Void
    {
        FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
    }

    override function openSubState(SubState:FlxSubState)
    {
        if (paused)
        {
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.pause();
                vocals.pause();
            }

            #if desktop
			DiscordClient.changePresence("PAUSED on " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "Acc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end
            if (!startTimer.finished)
                startTimer.active = false;
        }

        super.openSubState(SubState);
    }

    override function closeSubState()
    {
        if (paused)
        {
            if (FlxG.sound.music != null && !startingSong)
            {
                resyncVocals();
            }

            if (!startTimer.finished)
                startTimer.active = true;
            paused = false;

            #if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "\nAcc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses, iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), iconRPC);
			}
			#end
        }

        super.closeSubState();
    }


    function resyncVocals():Void
    {
        vocals.pause();

        FlxG.sound.music.play();
        Conductor.songPosition = FlxG.sound.music.time;
        vocals.time = Conductor.songPosition;
        vocals.play();

        #if desktop
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "\nAcc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end
    }

    private var paused:Bool = false;
    var startedCountdown:Bool = false;
    var canPause:Bool = true;

    function truncateFloat( number : Float, precision : Int): Float {
        var num = number;
        num = num * Math.pow(10, precision);
        num = Math.round( num ) / Math.pow(10, precision);
        return num;
    }


    function generateRanking():String
    {
        var ranking:String = "N/A";

        if (misses == 0 && bads == 0 && shits == 0 && goods == 0) // Marvelous (SICK) Full Combo
            ranking = "(MFC)";
        else if (misses == 0 && bads == 0 && shits == 0 && goods >= 1) // Good Full Combo (Nothing but Goods & Sicks)
            ranking = "(GFC)";
        else if ((shits < 10 && shits != 0 || bads < 10 && bads != 0) && misses == 0) // Single Digit Combo Breaks
            ranking = "(SDCB)";
        else if (misses == 0 && (shits >= 10 || bads >= 10)) // Regular FC
            ranking = "(FC)";
        else if (misses >= 10 || (shits >= 10 || bads >= 10)) // Combo Breaks
            ranking = "(CB)";
        else
            ranking = "";

        // WIFE TIME :)))) (based on Wife3)

        var wifeConditions:Array<Bool> = [
            accuracy >= 99.9935, // AAAAA
            accuracy >= 99.980, // AAAA:
            accuracy >= 99.970, // AAAA.
            accuracy >= 99.955, // AAAA
            accuracy >= 99.90, // AAA:
            accuracy >= 99.80, // AAA.
            accuracy >= 99.70, // AAA
            accuracy >= 99, // AA:
            accuracy >= 96.50, // AA.
            accuracy >= 93, // AA
            accuracy >= 90, // A:
            accuracy >= 85, // A.
            accuracy >= 80, // A
            accuracy >= 70, // B
            accuracy >= 60, // C
            accuracy < 60 // D
        ];

        for(i in 0...wifeConditions.length)
        {
            var b = wifeConditions[i];
            if (b)
            {
                switch(i)
                {
                    case 0:
                        ranking += " AAAAA";
                    case 1:
                        ranking += " AAAA:";
                    case 2:
                        ranking += " AAAA.";
                    case 3:
                        ranking += " AAAA";
                    case 4:
                        ranking += " AAA:";
                    case 5:
                        ranking += " AAA.";
                    case 6:
                        ranking += " AAA";
                    case 7:
                        ranking += " AA:";
                    case 8:
                        ranking += " AA.";
                    case 9:
                        ranking += " AA";
                    case 10:
                        ranking += " A:";
                    case 11:
                        ranking += " A.";
                    case 12:
                        ranking += " A";
                    case 13:
                        ranking += " B";
                    case 14:
                        ranking += " C";
                    case 15:
                        ranking += " D";
                }
                break;
            }
        }

        if (accuracy == 0)
            ranking = "N/A";

        return ranking;
    }

    public static var songRate = 1.5;

    override public function update(elapsed:Float)
    {
        #if !debug
        perfectMode = false;
        #end

		setAllVar('songPos', Conductor.songPosition);
		setAllVar('hudZoom', camHUD.zoom);
		setAllVar('cameraZoom', FlxG.camera.zoom);
		callAllLua('update', [elapsed], null);
		if (luaStates.exists("modchart")) {
			FlxG.camera.angle = getVar('cameraAngle', 'float', 'modchart');
			camHUD.angle = getVar('camHudAngle', 'float', 'modchart');

			if (getVar("showOnlyStrums", 'bool', 'modchart'))
			{
				healthBarBG.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
			}

			var p1 = getVar("strumLine1Visible", 'bool', 'modchart');
			var p2 = getVar("strumLine2Visible", 'bool', 'modchart');

			for (i in 0...4)
			{
				strumLineNotes.members[i].visible = p1;
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}
		}

        if (FlxG.keys.justPressed.NINE)
        {
            if (iconP1.animation.curAnim.name == 'bf-old')
                iconP1.animation.play(SONG.player1);
            else
                iconP1.animation.play('bf-old');
        }

        switch (curStage)
        {
            case 'philly':
                if (trainMoving)
                {
                    trainFrameTiming += elapsed;

                    if (trainFrameTiming >= 1 / 24)
                    {
                        updateTrainPos();
                        trainFrameTiming = 0;
                    }
                }
            // phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
        }

        super.update(elapsed);

        if (FlxG.save.data.accuracyDisplay)
        {
            scoreTxt.text = "Score:" + (FlxG.save.data.etternaMode ? etternaModeScore + " (" + songScore + ")" : "" + songScore) + " | Misses:" + misses + " | Accuracy:" + truncateFloat(accuracy, 2) + "% | " + generateRanking();
        }
        else
        {
            scoreTxt.text = "Score:" + songScore;
        }
        if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
        {
            persistentUpdate = false;
            persistentDraw = true;
            paused = true;

            // 1 / 1000 chance for Gitaroo Man easter egg
            if (FlxG.random.bool(0.1))
            {
                // gitaroo man easter egg
                FlxG.switchState(new GitarooPause());
            }
            else
                openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
        }

        if (FlxG.keys.justPressed.SEVEN)
        {
            #if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
            FlxG.switchState(new ChartingState());
        }

        // FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
        // FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

        iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
        iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

        iconP1.updateHitbox();
        iconP2.updateHitbox();

        var iconOffset:Int = 26;

        iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
        iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

        if (health > 2)
            health = 2;

        if (healthBar.percent < 20)
            iconP1.animation.curAnim.curFrame = 1;
        else
            iconP1.animation.curAnim.curFrame = 0;

        if (healthBar.percent > 80)
            iconP2.animation.curAnim.curFrame = 1;
        else
            iconP2.animation.curAnim.curFrame = 0;

        /* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

        #if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

        if (startingSong)
        {
            if (startedCountdown)
            {
                Conductor.songPosition += FlxG.elapsed * 1000;
                if (Conductor.songPosition >= 0)
                    startSong();
            }
        }
        else
        {
            // Conductor.songPosition = FlxG.sound.music.time;
            Conductor.songPosition += FlxG.elapsed * 1000;
            /*@:privateAccess
			{
				FlxG.sound.music._channel.
			}*/
            songPositionBar = Conductor.songPosition;

            if (!paused)
            {
                songTime += FlxG.game.ticks - previousFrameTime;
                previousFrameTime = FlxG.game.ticks;

                // Interpolation type beat
                if (Conductor.lastSongPos != Conductor.songPosition)
                {
                    songTime = (songTime + Conductor.songPosition) / 2;
                    Conductor.lastSongPos = Conductor.songPosition;
                    // Conductor.songPosition += FlxG.elapsed * 1000;
                    // trace('MISSED FRAME');
                }
            }

            // Conductor.lastSongPos = FlxG.sound.music.time;
        }

        if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
        {
            if (curBeat % 4 == 0)
            {
                // trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
            }

            if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
            {
                camFollow.setPosition((dad.getMidpoint().x + 150) + dad.followCamX, (dad.getMidpoint().y - 100) + dad.followCamY);
                // camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
				callAllLua("playerTwoTurn", [], null);
                switch (dad.curCharacter)
                {
                    case 'mom':
                        camFollow.y = dad.getMidpoint().y;
                    case 'senpai':
                        camFollow.y = dad.getMidpoint().y - 430;
                        camFollow.x = dad.getMidpoint().x - 100;
                    case 'senpai-angry':
                        camFollow.y = dad.getMidpoint().y - 430;
                        camFollow.x = dad.getMidpoint().x - 100;
                }

                if (dad.curCharacter == 'mom')
                    vocals.volume = 1;


                if (SONG.song.toLowerCase() == 'tutorial')
                {
                    tweenCamIn();
                }

            }

            if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
            {
                camFollow.setPosition((boyfriend.getMidpoint().x - 100) + boyfriend.followCamX, (boyfriend.getMidpoint().y - 100) + boyfriend.followCamY);
				callAllLua("playerOneTurn", [], null);
                switch (curStage)
                {
                    case 'limo':
                        camFollow.x = boyfriend.getMidpoint().x - 300;
                    case 'mall':
                        camFollow.y = boyfriend.getMidpoint().y - 200;
                    case 'school':
                        camFollow.x = boyfriend.getMidpoint().x - 200;
                        camFollow.y = boyfriend.getMidpoint().y - 200;
                    case 'schoolEvil':
                        camFollow.x = boyfriend.getMidpoint().x - 200;
                        camFollow.y = boyfriend.getMidpoint().y - 200;

                }


                if (SONG.song.toLowerCase() == 'tutorial')
                {
                    FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
                }
            }
        }

        if (camZooming)
        {
            FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
            camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
        }

        FlxG.watch.addQuick("beatShit", curBeat);
        FlxG.watch.addQuick("stepShit", curStep);
        if (loadRep) // rep debug
        {
            FlxG.watch.addQuick('rep rpesses',repPresses);
            FlxG.watch.addQuick('rep releases',repReleases);
            // FlxG.watch.addQuick('Queued',inputsQueued);
        }

        if (curSong == 'Fresh')
        {
            switch (curBeat)
            {
                case 16:
                    camZooming = true;
                    gfSpeed = 2;
                case 48:
                    gfSpeed = 1;
                case 80:
                    gfSpeed = 2;
                case 112:
                    gfSpeed = 1;
                case 163:
                // FlxG.sound.music.stop();
                // FlxG.switchState(new TitleState());
            }
        }

        if (curSong == 'Bopeebo')
        {
            switch (curBeat)
            {
                case 128, 129, 130:
                    vocals.volume = 0;
                // FlxG.sound.music.stop();
                // FlxG.switchState(new PlayState());
            }
        }

        if (health <= 0)
        {
            boyfriend.stunned = true;

            persistentUpdate = false;
            persistentDraw = false;
            paused = true;

            vocals.stop();
            FlxG.sound.music.stop();

            openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

            #if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("GAME OVER -- " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(),"\nAcc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end

            // FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
        }

        if (unspawnNotes[0] != null)
        {
            if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
            {
                var dunceNote:Note = unspawnNotes[0];
                notes.add(dunceNote);

                var index:Int = unspawnNotes.indexOf(dunceNote);
                unspawnNotes.splice(index, 1);
            }
        }

        if (generatedMusic)
        {
            notes.forEachAlive(function(daNote:Note)
            {
                if (daNote.y > FlxG.height)
                {
                    daNote.active = false;
                    daNote.visible = false;
                }
                else
                {
                    daNote.visible = true;
                    daNote.active = true;
                }

                if (!daNote.mustPress && daNote.wasGoodHit)
                {
                    if (SONG.song != 'Tutorial')
                        camZooming = true;

                    var altAnim:String = "";

                    if (SONG.notes[Math.floor(curStep / 16)] != null)
                    {
                        if (SONG.notes[Math.floor(curStep / 16)].altAnim)
                            altAnim = '-alt';
                    }

                    switch (Math.abs(daNote.noteData))
                    {
                        case 2:
                            dad.playAnim('singUP' + altAnim, true);
                        case 3:
                            dad.playAnim('singRIGHT' + altAnim, true);
                        case 1:
                            dad.playAnim('singDOWN' + altAnim, true);
                        case 0:
                            dad.playAnim('singLEFT' + altAnim, true);
                    }

                    if (dad.singshake == true) //just a lil easter egg for the curious ones ehehe
                    {
                        FlxG.camera.shake(0.01, 0.05);
                    }

					callAllLua("playerTwoSing", [], null);

                    dad.holdTimer = 0;

                    if (SONG.needsVoices)
                        vocals.volume = 1;

                    daNote.kill();
                    notes.remove(daNote, true);
                    daNote.destroy();
                }

                if (FlxG.save.data.downscroll)
                    daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (-0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
                else
                    daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
                //trace(daNote.y);
                // WIP interpolation shit? Need to fix the pause issue
                // daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

                if (daNote.y < -daNote.height && !FlxG.save.data.downscroll || daNote.y >= strumLine.y + 106 && FlxG.save.data.downscroll)
                {
                    if (daNote.isSustainNote && daNote.wasGoodHit)
                    {
                        daNote.kill();
                        notes.remove(daNote, true);
                        daNote.destroy();
                    }
                    else
                    {
                        health -= 0.075;
                        vocals.volume = 0;
                        if (theFunne)
                            noteMiss(daNote.noteData, daNote);
                    }

                    daNote.active = false;
                    daNote.visible = false;

                    daNote.kill();
                    notes.remove(daNote, true);
                    daNote.destroy();
                }
            });
        }


        if (!inCutscene)
            keyShit();


        #if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
    }

    function endSong():Void
    {
        if (!loadRep)
            rep.SaveReplay();

        canPause = false;
        FlxG.sound.music.volume = 0;
        vocals.volume = 0;
        if (SONG.validScore)
        {
            #if !switch
            Highscore.saveScore(SONG.song, Math.round(songScore), storyDifficulty);
            #end
        }

        if (isStoryMode)
        {
            campaignScore += Math.round(songScore);

            storyPlaylist.remove(storyPlaylist[0]);

            if (storyPlaylist.length <= 0)
            {
                FlxG.sound.playMusic(Paths.music('freakyMenu'));

                transIn = FlxTransitionableState.defaultTransIn;
                transOut = FlxTransitionableState.defaultTransOut;

                FlxG.switchState(new StoryMenuState());

                // if ()
                StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

                if (SONG.validScore)
                {
                    NGio.unlockMedal(60961);
                    Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
                }

                FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
                FlxG.save.flush();
            }
            else
            {
                var difficulty:String = "";

                if (storyDifficulty == 0)
                    difficulty = '-easy';

                if (storyDifficulty == 2)
                    difficulty = '-hard';

                trace('LOADING NEXT SONG');
                trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

                if (SONG.song.toLowerCase() == 'eggnog')
                {
                    var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
                    -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
                    blackShit.scrollFactor.set();
                    add(blackShit);
                    camHUD.visible = false;

                    FlxG.sound.play(Paths.sound('Lights_Shut_off'));
                }

                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
                prevCamFollow = camFollow;

                PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
                FlxG.sound.music.stop();

                LoadingState.loadAndSwitchState(new PlayState());
            }
        }
        else
        {
            trace('WENT BACK TO FREEPLAY??');
            FlxG.switchState(new FreeplayState());
        }
    }

    var endingSong:Bool = false;

	private function popUpScore(strumtime:Float, daNote:Note):Void
    {
        var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
        var wife:Float = EtternaFunctions.wife3(noteDiff, FlxG.save.data.etternaMode ? 1 : 1.7);
        // boyfriend.playAnim('hey');
        vocals.volume = 1;

        var placement:String = Std.string(combo);

        var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
        coolText.screenCenter();
        coolText.x = FlxG.width * 0.55;
        //

        var rating:FlxSprite = new FlxSprite();
        var score:Float = 350;

        var daRating:String = "sick";

        totalNotesHit += wife;

        if (noteDiff > Conductor.safeZoneOffset * 2)
        {
            daRating = 'shit';
            ss = false;
            if (theFunne)
            {
                score = -3000;
                combo = 0;
                health -= 0.2;
            }
            shits++;
        }
        else if (noteDiff < Conductor.safeZoneOffset * -2)
        {
            daRating = 'shit';
            if (theFunne)
            {
                score = -3000;
                combo = 0;
                health -= 0.2;
            }
            ss = false;
            shits++;
        }
        else if (noteDiff < Conductor.safeZoneOffset * -0.45)
        {
            daRating = 'bad';
            if (theFunne)
            {
                score = -1000;
                health -= 0.03;
                combo = 0;
            }
            else
                score = 100;
            ss = false;
            bads++;
        }
        else if (noteDiff > Conductor.safeZoneOffset * 0.45)
        {
            daRating = 'bad';
            if (theFunne)
            {
                score = -1000;
                health -= 0.03;
                combo = 0;
            }
            else
                score = 100;
            ss = false;
            bads++;
        }
        else if (noteDiff < Conductor.safeZoneOffset * -0.25)
        {
            daRating = 'good';
            if (theFunne)
            {
                score = 200;
                //health -= 0.01;
            }
            else
                score = 200;
            ss = false;
            goods++;
        }
        else if (noteDiff > Conductor.safeZoneOffset * 0.35)
        {
            daRating = 'good';
            if (theFunne)
            {
                score = 200;
                //health -= 0.01;
            }
            else
                score = 200;
            ss = false;
            goods++;
		} else {
			var recycledNote = grpNoteSplashes.recycle(NoteSplash);
			recycledNote.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(recycledNote);
		}
        if (daRating == 'sick')
        {
            if (health < 2)
                health += 0.1;
            sicks++;
        }


        if (FlxG.save.data.etternaMode)
            etternaModeScore += Math.round(score / wife);

        // trace('Wife accuracy loss: ' + wife + ' | Rating: ' + daRating + ' | Score: ' + score + ' | Weight: ' + (1 - wife));

        if (daRating != 'shit' || daRating != 'bad')
        {


            songScore += Math.round(score);

            /* if (combo > 60)
					daRating = 'sick';
				else if (combo > 12)
					daRating = 'good'
				else if (combo > 4)
					daRating = 'bad';
			 */

            var pixelShitPart1:String = "";
            var pixelShitPart2:String = '';
            var pixelShitPart3:String = null;

            if (curStage.startsWith('school'))
            {
                pixelShitPart1 = 'weeb/pixelUI/';
                pixelShitPart2 = '-pixel';
                pixelShitPart3 = 'week6';
            }

            rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2, pixelShitPart3));
            rating.screenCenter();
            rating.y += 200;
            rating.x = coolText.x - 40;
            rating.y -= 60;
            rating.acceleration.y = 550;
            rating.velocity.y -= FlxG.random.int(140, 175);
            rating.velocity.x -= FlxG.random.int(0, 10);

            var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2, pixelShitPart3));
            comboSpr.screenCenter();
            comboSpr.x = coolText.x;
            comboSpr.y += 200;
            comboSpr.acceleration.y = 600;
            comboSpr.velocity.y -= 150;

            comboSpr.velocity.x += FlxG.random.int(1, 10);
            add(rating);

            if (!curStage.startsWith('school'))
            {
                rating.setGraphicSize(Std.int(rating.width * 0.7));
                rating.antialiasing = true;
                comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
                comboSpr.antialiasing = true;
            }
            else
            {
                rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
                comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
            }

            comboSpr.updateHitbox();
            rating.updateHitbox();

            var seperatedScore:Array<Int> = [];

            var comboSplit:Array<String> = (combo + "").split('');

            if (comboSplit.length == 2)
                seperatedScore.push(0); // make sure theres a 0 in front or it looks weird lol!

            for(i in 0...comboSplit.length)
            {
                var str:String = comboSplit[i];
                seperatedScore.push(Std.parseInt(str));
            }

            var daLoop:Int = 0;
            for (i in seperatedScore)
            {
                var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2, pixelShitPart3));
                numScore.screenCenter();
                numScore.x = coolText.x + (43 * daLoop) - 90;
                numScore.y += 80 + 200;

                if (!curStage.startsWith('school'))
                {
                    numScore.antialiasing = true;
                    numScore.setGraphicSize(Std.int(numScore.width * 0.5));
                }
                else
                {
                    numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
                }
                numScore.updateHitbox();

                numScore.acceleration.y = FlxG.random.int(200, 300);
                numScore.velocity.y -= FlxG.random.int(140, 160);
                numScore.velocity.x = FlxG.random.float(-5, 5);

                if (combo >= 10 || combo == 0)
                    add(numScore);

                FlxTween.tween(numScore, {alpha: 0}, 0.2, {
                    onComplete: function(tween:FlxTween)
                    {
                        numScore.destroy();
                    },
                    startDelay: Conductor.crochet * 0.002
                });

                daLoop++;
            }
            /*
				trace(combo);
				trace(seperatedScore);
			 */

            coolText.text = Std.string(seperatedScore);
            // add(coolText);

            FlxTween.tween(rating, {alpha: 0}, 0.2, {
                startDelay: Conductor.crochet * 0.001
            });

            FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
                onComplete: function(tween:FlxTween)
                {
                    coolText.destroy();
                    comboSpr.destroy();

                    rating.destroy();
                },
                startDelay: Conductor.crochet * 0.001
            });

            curSection += 1;
        }
    }

    public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
    {
        return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
    }

    var upHold:Bool = false;
    var downHold:Bool = false;
    var rightHold:Bool = false;
    var leftHold:Bool = false;

    private function keyShit():Void
    {
        // HOLDING
        var up = controls.UP;
        var right = controls.RIGHT;
        var down = controls.DOWN;
        var left = controls.LEFT;

        var upP = controls.UP_P;
        var rightP = controls.RIGHT_P;
        var downP = controls.DOWN_P;
        var leftP = controls.LEFT_P;

        var upR = controls.UP_R;
        var rightR = controls.RIGHT_R;
        var downR = controls.DOWN_R;
        var leftR = controls.LEFT_R;

        if (loadRep) // replay code
        {
            // disable input
            up = false;
            down = false;
            right = false;
            left = false;

            // new input


            //if (rep.replay.keys[repPresses].time == Conductor.songPosition)
            //	trace('DO IT!!!!!');

            //timeCurrently = Math.abs(rep.replay.keyPresses[repPresses].time - Conductor.songPosition);
            //timeCurrentlyR = Math.abs(rep.replay.keyReleases[repReleases].time - Conductor.songPosition);


            if (repPresses < rep.replay.keyPresses.length && repReleases < rep.replay.keyReleases.length)
            {
                upP = rep.replay.keyPresses[repPresses].time + 1 <= Conductor.songPosition  && rep.replay.keyPresses[repPresses].key == "up";
                rightP = rep.replay.keyPresses[repPresses].time + 1 <= Conductor.songPosition && rep.replay.keyPresses[repPresses].key == "right";
                downP = rep.replay.keyPresses[repPresses].time + 1 <= Conductor.songPosition && rep.replay.keyPresses[repPresses].key == "down";
                leftP = rep.replay.keyPresses[repPresses].time + 1 <= Conductor.songPosition  && rep.replay.keyPresses[repPresses].key == "left";

                upR = rep.replay.keyPresses[repReleases].time - 1 <= Conductor.songPosition && rep.replay.keyReleases[repReleases].key == "up";
                rightR = rep.replay.keyPresses[repReleases].time - 1 <= Conductor.songPosition  && rep.replay.keyReleases[repReleases].key == "right";
                downR = rep.replay.keyPresses[repReleases].time - 1<= Conductor.songPosition && rep.replay.keyReleases[repReleases].key == "down";
                leftR = rep.replay.keyPresses[repReleases].time - 1<= Conductor.songPosition && rep.replay.keyReleases[repReleases].key == "left";

                upHold = upP ? true : upR ? false : true;
                rightHold = rightP ? true : rightR ? false : true;
                downHold = downP ? true : downR ? false : true;
                leftHold = leftP ? true : leftR ? false : true;
            }
        }
        else if (!loadRep) // record replay code
        {
            if (upP)
                rep.replay.keyPresses.push({time: Conductor.songPosition, key: "up"});
            if (rightP)
                rep.replay.keyPresses.push({time: Conductor.songPosition, key: "right"});
            if (downP)
                rep.replay.keyPresses.push({time: Conductor.songPosition, key: "down"});
            if (leftP)
                rep.replay.keyPresses.push({time: Conductor.songPosition, key: "left"});

            if (upR)
                rep.replay.keyReleases.push({time: Conductor.songPosition, key: "up"});
            if (rightR)
                rep.replay.keyReleases.push({time: Conductor.songPosition, key: "right"});
            if (downR)
                rep.replay.keyReleases.push({time: Conductor.songPosition, key: "down"});
            if (leftR)
                rep.replay.keyReleases.push({time: Conductor.songPosition, key: "left"});
        }
        var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

        // FlxG.watch.addQuick('asdfa', upP);
        if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
        {
            repPresses++;
            boyfriend.holdTimer = 0;

            var possibleNotes:Array<Note> = [];

            var ignoreList:Array<Int> = [];

            notes.forEachAlive(function(daNote:Note)
            {
                if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
                {
                    // the sorting probably doesn't need to be in here? who cares lol
                    possibleNotes.push(daNote);
                    possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

                    ignoreList.push(daNote.noteData);
                }
            });


            if (possibleNotes.length > 0)
            {
                var daNote = possibleNotes[0];

                // Jump notes
                if (possibleNotes.length >= 2)
                {
                    if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
                    {
                        for (coolNote in possibleNotes)
                        {
                            if (controlArray[coolNote.noteData])
                                goodNoteHit(coolNote);
                            else
                            {
                                var inIgnoreList:Bool = false;
                                for (shit in 0...ignoreList.length)
                                {
                                    if (controlArray[ignoreList[shit]])
                                        inIgnoreList = true;
                                }
                            }
                        }
                    }
                    else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
                    {
                        if (loadRep)
                        {
                            if (NearlyEquals(daNote.strumTime,rep.replay.keyPresses[repPresses].time, 30))
                            {
                                goodNoteHit(daNote);
                                trace('force note hit');
                            }
                            else
                                noteCheck(controlArray, daNote);
                        }
                        else
                            noteCheck(controlArray, daNote);
                    }
                    else
                    {
                        for (coolNote in possibleNotes)
                        {
                            if (loadRep)
                            {
                                if (NearlyEquals(coolNote.strumTime,rep.replay.keyPresses[repPresses].time, 30))
                                {
                                    goodNoteHit(coolNote);
                                    trace('force note hit');
                                }
                                else
                                    noteCheck(controlArray, daNote);
                            }
                            else
                                noteCheck(controlArray, coolNote);
                        }
                    }
                }
                else // regular notes?
                {
                    if (loadRep)
                    {
                        if (NearlyEquals(daNote.strumTime,rep.replay.keyPresses[repPresses].time, 30))
                        {
                            goodNoteHit(daNote);
                            trace('force note hit');
                        }
                        else
                            noteCheck(controlArray, daNote);
                    }
                    else
                        noteCheck(controlArray, daNote);
                }
                /*
						if (controlArray[daNote.noteData])
							goodNoteHit(daNote);
					 */
                // trace(daNote.noteData);
                /*
						switch (daNote.noteData)
						{
							case 2: // NOTES YOU JUST PRESSED
								if (upP || rightP || downP || leftP)
									noteCheck(upP, daNote);
							case 3:
								if (upP || rightP || downP || leftP)
									noteCheck(rightP, daNote);
							case 1:
								if (upP || rightP || downP || leftP)
									noteCheck(downP, daNote);
							case 0:
								if (upP || rightP || downP || leftP)
									noteCheck(leftP, daNote);
						}
					 */
                if (daNote.wasGoodHit)
                {
                    daNote.kill();
                    notes.remove(daNote, true);
                    daNote.destroy();
                }
            }
        }

        if ((up || right || down || left) && generatedMusic || (upHold || downHold || leftHold || rightHold) && loadRep && generatedMusic)
        {
            notes.forEachAlive(function(daNote:Note)
            {
                if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
                {
                    switch (daNote.noteData)
                    {
                        // NOTES YOU ARE HOLDING
                        case 2:
                            if (up || upHold)
                                goodNoteHit(daNote);
                        case 3:
                            if (right || rightHold)
                                goodNoteHit(daNote);
                        case 1:
                            if (down || downHold)
                                goodNoteHit(daNote);
                        case 0:
                            if (left || leftHold)
                                goodNoteHit(daNote);
                    }
                }
            });
        }

        if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
        {
            if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
            {
                boyfriend.playAnim('idle');
            }
        }

        playerStrums.forEach(function(spr:FlxSprite)
        {
            switch (spr.ID)
            {
                case 2:
                    if (loadRep)
                    {
                        /*if (upP)
								{
									spr.animation.play('pressed');
									new FlxTimer().start(Math.abs(rep.replay.keyPresses[repReleases].time - Conductor.songPosition) + 10, function(tmr:FlxTimer)
										{
											spr.animation.play('static');
											repReleases++;
										});
								}*/
                    }
                    else
                    {
                        if (upP && spr.animation.curAnim.name != 'confirm' && !loadRep)
                        {
                            spr.animation.play('pressed');
                            trace('play');
                        }
                        if (upR)
                        {
                            spr.animation.play('static');
                            repReleases++;
                        }
                    }
                case 3:
                    if (loadRep)
                    {
                        /*if (upP)
								{
									spr.animation.play('pressed');
									new FlxTimer().start(Math.abs(rep.replay.keyPresses[repReleases].time - Conductor.songPosition) + 10, function(tmr:FlxTimer)
										{
											spr.animation.play('static');
											repReleases++;
										});
								}*/
                    }
                    else
                    {
                        if (rightP && spr.animation.curAnim.name != 'confirm' && !loadRep)
                            spr.animation.play('pressed');
                        if (rightR)
                        {
                            spr.animation.play('static');
                            repReleases++;
                        }
                    }
                case 1:
                    if (loadRep)
                    {
                        /*if (upP)
								{
									spr.animation.play('pressed');
									new FlxTimer().start(Math.abs(rep.replay.keyPresses[repReleases].time - Conductor.songPosition) + 10, function(tmr:FlxTimer)
										{
											spr.animation.play('static');
											repReleases++;
										});
								}*/
                    }
                    else
                    {
                        if (downP && spr.animation.curAnim.name != 'confirm' && !loadRep)
                            spr.animation.play('pressed');
                        if (downR)
                        {
                            spr.animation.play('static');
                            repReleases++;
                        }
                    }
                case 0:
                    if (loadRep)
                    {
                        /*if (upP)
								{
									spr.animation.play('pressed');
									new FlxTimer().start(Math.abs(rep.replay.keyPresses[repReleases].time - Conductor.songPosition) + 10, function(tmr:FlxTimer)
										{
											spr.animation.play('static');
											repReleases++;
										});
								}*/
                    }
                    else
                    {
                        if (leftP && spr.animation.curAnim.name != 'confirm' && !loadRep)
                            spr.animation.play('pressed');
                        if (leftR)
                        {
                            spr.animation.play('static');
                            repReleases++;
                        }
                    }
            }

            if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
            {
                spr.centerOffsets();
                spr.offset.x -= 13;
                spr.offset.y -= 13;
            }
            else
                spr.centerOffsets();
        });
    }

    function noteMiss(direction:Int = 1, daNote:Note):Void
    {
        if (!boyfriend.stunned)
        {
            health -= 0.04;
            if (combo > 5 && gf.animOffsets.exists('sad'))
            {
                gf.playAnim('sad');
            }
            combo = 0;
            misses++;

            var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
            var wife:Float = EtternaFunctions.wife3(noteDiff, FlxG.save.data.etternaMode ? 1 : 1.7);

            totalNotesHit += wife;

            songScore -= 10;

            FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
            // FlxG.sound.play(Paths.sound('missnote1'), 1, false);
            // FlxG.log.add('played imss note');

            switch (direction)
            {
                case 0:
                    boyfriend.playAnim('singLEFTmiss', true);
                case 1:
                    boyfriend.playAnim('singDOWNmiss', true);
                case 2:
                    boyfriend.playAnim('singUPmiss', true);
                case 3:
                    boyfriend.playAnim('singRIGHTmiss', true);
            }

            updateAccuracy();
			callAllLua("playerOneMiss", [], null);

        }
    }

    /*function badNoteCheck()
		{
			// just double pasting this shit cuz fuk u
			// REDO THIS SYSTEM!
			var upP = controls.UP_P;
			var rightP = controls.RIGHT_P;
			var downP = controls.DOWN_P;
			var leftP = controls.LEFT_P;

			if (leftP)
				noteMiss(0);
			if (upP)
				noteMiss(2);
			if (rightP)
				noteMiss(3);
			if (downP)
				noteMiss(1);
			updateAccuracy();
		}
	*/
    function updateAccuracy()
    {
        if (misses > 0 || accuracy < 96)
            fc = false;
        else
            fc = true;
        totalPlayed += 1;
        accuracy = Math.max(0,totalNotesHit / totalPlayed * 100);
    }


    function getKeyPresses(note:Note):Int
    {
        var possibleNotes:Array<Note> = []; // copypasted but you already know that

        notes.forEachAlive(function(daNote:Note)
        {
            if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
            {
                possibleNotes.push(daNote);
                possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
            }
        });
        if (possibleNotes.length == 1)
            return possibleNotes.length + 1;
        return possibleNotes.length;
    }

    var mashing:Int = 0;
    var mashViolations:Int = 0;

    var etternaModeScore:Int = 0;

    function noteCheck(controlArray:Array<Bool>, note:Note):Void // sorry lol
    {
        if (loadRep)
        {
            if (controlArray[note.noteData])
                goodNoteHit(note);
            else if (rep.replay.keyPresses.length > repPresses && !controlArray[note.noteData])
            {
                if (NearlyEquals(note.strumTime,rep.replay.keyPresses[repPresses].time, 4))
                {
                    goodNoteHit(note);
                }
            }
        }
        else if (controlArray[note.noteData])
        {
            for (b in controlArray) {
                if (b)
                    mashing++;
            }

            // ANTI MASH CODE FOR THE BOYS

            if (mashing <= getKeyPresses(note) && mashViolations < 2)
            {
                mashViolations++;
                goodNoteHit(note, (mashing <= getKeyPresses(note)));
            }
            else
            {
                playerStrums.members[note.noteData].animation.play('static');
                trace('mash ' + mashing);
            }

            if (mashing != 0)
                mashing = 0;
        }
    }

    function goodNoteHit(note:Note, resetMashViolation = true):Void
    {

        if (resetMashViolation)
            mashViolations--;

        if (!note.wasGoodHit)
        {
            if (!note.isSustainNote)
            {
				popUpScore(note.strumTime, note);
                combo += 1;
            }
            else
                totalNotesHit += 1;


            switch (note.noteData)
            {
                case 2:
                    boyfriend.playAnim('singUP', true);
                case 3:
                    boyfriend.playAnim('singRIGHT', true);
                case 1:
                    boyfriend.playAnim('singDOWN', true);
                case 0:
                    boyfriend.playAnim('singLEFT', true);
            }

			callAllLua("playerOneSing", [], null);

            if (boyfriend.singshake == true) //just a lil easter egg for the curious ones ehehe
            {
                FlxG.camera.shake(0.01, 0.05);
            }


            if (!loadRep)
                playerStrums.forEach(function(spr:FlxSprite)
                {
                    if (Math.abs(note.noteData) == spr.ID)
                    {
                        spr.animation.play('confirm', true);
                    }
                });

            note.wasGoodHit = true;
            vocals.volume = 1;

            note.kill();
            notes.remove(note, true);
            note.destroy();

            updateAccuracy();
        }
    }


    var fastCarCanDrive:Bool = true;

    function resetFastCar():Void
    {
        fastCar.x = -12600;
        fastCar.y = FlxG.random.int(140, 250);
        fastCar.velocity.x = 0;
        fastCarCanDrive = true;
    }

    function fastCarDrive()
    {
        FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

        fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
        fastCarCanDrive = false;
        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
            resetFastCar();
        });
    }

    var trainMoving:Bool = false;
    var trainFrameTiming:Float = 0;

    var trainCars:Int = 8;
    var trainFinishing:Bool = false;
    var trainCooldown:Int = 0;

    function trainStart():Void
    {
        trainMoving = true;
        if (!trainSound.playing)
            trainSound.play(true);
    }

    var startedMoving:Bool = false;

    function updateTrainPos():Void
    {
        if (trainSound.time >= 4700)
        {
            startedMoving = true;
            gf.playAnim('hairBlow');
        }

        if (startedMoving)
        {
            phillyTrain.x -= 400;

            if (phillyTrain.x < -2000 && !trainFinishing)
            {
                phillyTrain.x = -1150;
                trainCars -= 1;

                if (trainCars <= 0)
                    trainFinishing = true;
            }

            if (phillyTrain.x < -4000 && trainFinishing)
                trainReset();
        }
    }

    function trainReset():Void
    {
        gf.playAnim('hairFall');
        phillyTrain.x = FlxG.width + 200;
        trainMoving = false;
        // trainSound.stop();
        // trainSound.time = 0;
        trainCars = 8;
        trainFinishing = false;
        startedMoving = false;
    }

    function lightningStrikeShit():Void
    {
        FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
        halloweenBG.animation.play('lightning');

        lightningStrikeBeat = curBeat;
        lightningOffset = FlxG.random.int(8, 24);

        boyfriend.playAnim('scared', true);
        gf.playAnim('scared', true);
    }

    override function stepHit()
    {
        super.stepHit();
        if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
        {
            resyncVocals();
        }

        if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
        {
            // dad.dance();
        }


        // yes this updates every step.
        // yes this is bad
        // but i'm doing it to update misses and accuracy
        #if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + generateRanking(), "Acc: " + truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC,true,  songLength - Conductor.songPosition);
		#end

		setAllVar("curStep", curStep);
		callAllLua("stepHit", [curStep], null);

    }

    var lightningStrikeBeat:Int = 0;
    var lightningOffset:Int = 8;

    override function beatHit()
    {
        super.beatHit();

        if (generatedMusic)
        {
            notes.sort(FlxSort.byY, FlxSort.DESCENDING);
        }

        if (SONG.notes[Math.floor(curStep / 16)] != null)
        {
            if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
            {
                Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
                FlxG.log.add('CHANGED BPM!');
            }
            // else
            // Conductor.changeBPM(SONG.bpm);

            // Dad doesnt interupt his own notes
            if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
                dad.dance();
        }
        // FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
        wiggleShit.update(Conductor.crochet);

        // HARDCODING FOR MILF ZOOMS!
        if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
        {
            FlxG.camera.zoom += 0.015;
            camHUD.zoom += 0.03;
        }

        if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
        {
            FlxG.camera.zoom += 0.015;
            camHUD.zoom += 0.03;
        }

        iconP1.setGraphicSize(Std.int(iconP1.width + 30));
        iconP2.setGraphicSize(Std.int(iconP2.width + 30));

        iconP1.updateHitbox();
        iconP2.updateHitbox();

        if (curBeat % gfSpeed == 0)
        {
            gf.dance();
        }

        if (!boyfriend.animation.curAnim.name.startsWith("sing"))
        {
            boyfriend.playAnim('idle');
        }

        if (curBeat % 8 == 7 && curSong == 'Bopeebo')
        {
            boyfriend.playAnim('hey', true);

            if (SONG.song == 'Tutorial' && dad.curCharacter == 'gf')
            {
                dad.playAnim('cheer', true);
            }
        }

        switch (curStage)
        {
            case 'school':
                bgGirls.dance();

            case 'mall':
                upperBoppers.animation.play('bop', true);
                bottomBoppers.animation.play('bop', true);
                santa.animation.play('idle', true);

            case 'limo':
                grpLimoDancers.forEach(function(dancer:BackgroundDancer)
                {
                    dancer.dance();
                });

                if (FlxG.random.bool(10) && fastCarCanDrive)
                    fastCarDrive();
            case "philly":
                if (!trainMoving)
                    trainCooldown += 1;

                if (curBeat % 4 == 0)
                {
                    phillyCityLights.forEach(function(light:FlxSprite)
                    {
                        light.visible = false;
                    });

                    curLight = FlxG.random.int(0, phillyCityLights.length - 1);

                    phillyCityLights.members[curLight].visible = true;
                    // phillyCityLights.members[curLight].alpha = 1;
                }

                if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
                {
                    trainCooldown = FlxG.random.int(-4, 0);
                    trainStart();
                }
        }

        if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
        {
            lightningStrikeShit();
        }
		setAllVar('curBeat', curBeat);
		callAllLua('beatHit', [curBeat],null);
    }

    var curLight:Int = 0;
}