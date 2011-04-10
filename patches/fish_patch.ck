// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100318_170437: Initial version
// ====

// Patch for Dogs Playing Poker "I'm a Fish".  
// Supports the following gestures:
// [1] trigger "I'm a fish"
// [2] trigger "I'm a fishfish"
// [3] trigger "I'm a fish...fish"
// [4] trigger random technical terms
// [5] trigger "what the fish .... of the river"
// [6] trigger "i'm so happy"
// [7] trigger whale sounds
// [a] controlling playback speed
// [b] controlling gain
// [c] controlling sustain (looping)

// ================================================================
// Iterator classes to help us update all active voices

class PlaybackRateOp extends Operation {
    float _value;
    fun PlaybackRateOp set_value(float value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) {
	(element $ FishVox) @=> FishVox @ vox;
	vox.set_playback_rate(_value);
	return null;
    }
}
class LoopingOp extends Operation {
    int _value;
    fun LoopingOp set_value(int value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) {
	(element $ FishVox) @=> FishVox @ vox;
	vox.set_looping(_value);
	return null;
    }
}


// ================================================================
// "shim" class to obseve GameTrakPluckDetector messages, since
// FishPatch can't be an observer (Patch is not a subclass of
// Observer).

class PluckObserver extends Observer {
    FishPatch @ _patch;
    fun PluckObserver init(FishPatch patch) {
	patch @=> _patch;
	return this;
    }
    fun void update(Observable o, Msg message) {
	<<< "PluckObserver:", o, message >>>;
	_patch.handle_pluck(o, message $ PluckEvt);
    }
}

class FishPatch extends Patch {
    // ================================================================
    // statics: all statics are initialized at the end of the file
    // (otherwise they get re-initalized at every object instantiation)

    // iterators for updating active voices.
    static PlaybackRateOp @ PLAYBACK_RATE;
    static LoopingOp @ LOOPING;

    // groupings of sound file names
    static string FISH[];
    static string FISHFISH[];
    static string FISH__FISH[];
    static string JARGON[];
    static string WHAT_THE_FISH[];
    static string SO_HAPPY[];
    static string WHALES[];

    // ================================================================
    // instance variables

    GameTrakPluckDetector _pluck_left_detector;
    GameTrakPluckDetector _pluck_right_detector;
    PluckObserver _pluck_observer;

    FishVoxController _vox_controller; // factory for FishVox objects
    float _playback_rate;
    int _is_looping;
    
    // ================================================================
    // subclassing Patch

    fun string get_name() { return "FishPatch"; }

    fun Patch init() {
	_vox_controller.init();
	_vox_controller.set_mode(VoxController.MONOPHONIC);

	set_playback_rate(1.0);
	set_looping(false);

	_pluck_left_detector.init(GameTrak.LEFT_X, GameTrak.LEFT_Y);
	_pluck_right_detector.init(GameTrak.RIGHT_X, GameTrak.RIGHT_Y);
	_pluck_observer.init(this);

	return this;
    }

    fun Patch start() {
	attach_std_controls();
	resend_std_controls();

	// start receiving pluck messages
	_pluck_left_detector.get_dispatcher().attach(_pluck_observer);
	_pluck_right_detector.get_dispatcher().attach(_pluck_observer);

	return this;
    }

    fun Patch stop() {
	// stop receiving pluck messages
	_pluck_right_detector.get_dispatcher().detach(_pluck_observer);
	_pluck_left_detector.get_dispatcher().detach(_pluck_observer);

	detach_std_controls();

	_vox_controller.all_notes_silent();
	return this;
    }

    // ================================================================
    // knobs specific to FishPatch

    fun void start_gesture(int gesture_number) {
	if (gesture_number == 0) {
	    trigger_fish();
	} else if (gesture_number == 1) {
	    trigger_fishfish();
	} else if (gesture_number == 2) {
	    trigger_fish__fish();
	} else if (gesture_number == 3) {
	    trigger_so_happy();
	} else if (gesture_number == 4) {
	    trigger_what_the_fish();
	} else if (gesture_number == 5) {
	    trigger_jargon();
	} else if (gesture_number == 6) {
	    trigger_whales();
	} else {
	    // ignored
	}
    }

    fun void stop_gesture() {
	_vox_controller.all_notes_off();
    }

    fun void trigger_fish() {
	disable_whale_echo();
	_trigger(_random_select(FISH));
    }

    fun void trigger_fishfish() {
	disable_whale_echo();
	_trigger(_random_select(FISHFISH));
    }

    fun void trigger_fish__fish() {
	disable_whale_echo();
	_trigger(_random_select(FISH__FISH));
    }

    fun void trigger_jargon() {
	disable_whale_echo();
	_trigger(_random_select(JARGON));
    }

    fun void trigger_what_the_fish() {
	disable_whale_echo();
	_trigger(_random_select(WHAT_THE_FISH));
    }

    fun void trigger_so_happy() {
	disable_whale_echo();
	_trigger(_random_select(SO_HAPPY));
    }

    fun void trigger_whales() {
	enable_whale_echo();
	_trigger(_random_select(WHALES));
    }

    fun void set_playback_rate(float playback_rate) {
	playback_rate => _playback_rate;
	_vox_controller.get_voices().apply(PLAYBACK_RATE.set_value(_playback_rate));
    }

    fun void set_looping(int is_looping) {
	is_looping => _is_looping;
	_vox_controller.get_voices().apply(LOOPING.set_value(_is_looping));
    }

    // select a string from an array of strings
    fun string _random_select(string strings[]) {
	return strings[Std.rand2(0, strings.size()-1)];
    }

    // start playing filename
    fun void _trigger(string soundfilename) {
	_vox_controller.note_on(0) $ FishVox @=> FishVox @ vox;
	vox.load_sample_data(soundfilename);
	vox.set_playback_rate(_playback_rate);
	vox.set_looping(_is_looping);
    }

    fun void enable_whale_echo() {
	AudioIO.audio_io().set_echo_delay(1.0);
	AudioIO.audio_io().set_echo_mix(0.5);
    }

    // To turn off whale echo, we ask the Oxygen8 to re-broadcast its
    // values for knob3 and knob4, which (as of this writing) are the
    // controls for echo delay and echo mix.
    fun void disable_whale_echo() {
	Oxygen8.oxygen8().knob_dispatcher(Oxygen8.KNOB_3).notify();
	Oxygen8.oxygen8().knob_dispatcher(Oxygen8.KNOB_4).notify();
    }

    // set the gain by directly tweaking the DAC stage...
    fun void set_gain(float gain) {
	
    }

    // Ask Oxygen8's data slider to re-send its value to anyone
    // listening, in particular, the AudioIO gain method.
    fun void revert_gain() {
    }

    // ================================================================
    // subclassing StdControlObserver

    // Keyboard triggers one of seven "gestures"
    fun void handle_key_press(ChannelEvt msg) { 
	msg.get_channel() => int key; 
	msg.get_value() => float velocity;

	// because this is a monophonic patch, we can call all_notes_off
	// for any velocity == 0.0
	if (velocity == 0.0) {
	    stop_gesture();
	} else {
	    start_gesture(key % 12); // key MOD 12 : any octave will do....
	}
    }

    // pitchwheel modifies playback rate
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	(v - 0.5) * 60.0 => float semitones;
	set_playback_rate(Math.pow(2.0, semitones/12.0));
    }
    fun void handle_modwheel(ChannelEvt msg) { }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) { }
    fun void handle_knob_06(ChannelEvt msg) { }
    fun void handle_knob_07(ChannelEvt msg) { }

    // pedal sets / clears looping
    fun void handle_keyboard_pedal(ChannelEvt msg) { 
	set_looping(msg.get_value() > 0.5);
    }

    // game trak left position does nothing in particular (but see pluck and quadrant)
    fun void handle_game_trak_left_x(ChannelEvt msg) { }
    fun void handle_game_trak_left_y(ChannelEvt msg) { }
    fun void handle_game_trak_left_z(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) {
	<<< "FishPatch.handle_game_trak_left_squelched()" >>>;
    }

    // game trak right: gain, pitch
    fun void handle_game_trak_right_x(ChannelEvt msg) { }
    fun void handle_game_trak_right_y(ChannelEvt msg) { 
	msg.get_value() => float gain;
	AudioIO.audio_io().set_post_gain(gain);
    }
    fun void handle_game_trak_right_z(ChannelEvt msg) { handle_pitchwheel(msg); }
    fun void handle_game_trak_right_squelched(ChannelEvt msg) {
	<<< "FishPatch.handle_game_trak_right_squelched()" >>>;
	// when squelching, revert to corresponding oxygen8 controls
	if (msg.get_value() == 1.0) {
	    <<< "FishPatch.handle_game_trak_right_squelched()[1]" >>>;
	    Oxygen8.oxygen8().dataentry_dispatcher() @=> Dispatcher @ d;
	    <<< "FishPatch.handle_game_trak_right_squelched()[2], d=", d >>>;
	    d.notify();
	    <<< "FishPatch.handle_game_trak_right_squelched()[3]" >>>;
	    Oxygen8.oxygen8().pitchwheel_dispatcher().notify();
	}
    }

    fun void handle_game_trak_footswitch(ChannelEvt msg) { }

    // ================================================================
    // target methods for PluckObserver

    // left pluck starts a "gesture" according to current game trak
    // left x, y positions.  right pluck stops gesture.
    //
    fun void handle_pluck(Observable o, PluckEvt message) {
	// Explanation: Since handle_pluck() receives messages from
	// both the left and the right joystick, we need to figure out
	// who sent it.  Luckily, every update() message carries with
	// it the Observable object that generated it, which allows us
	// to compare Observable o with the joystick's dispatcher...
	if (o == _pluck_left_detector.get_dispatcher()) {
	    <<< "pluck left" >>>;
	    start_gesture(gametrack_xy_to_gesture_number());
	} else if (o == _pluck_right_detector.get_dispatcher()) {
	    <<< "pluck right" >>>;
	    stop_gesture();
	} else {
	    <<< "can't determine origin of pluck message." >>>;
	}
    }

    // Reach into GameTrak to get Left X and Y axes.  Map their values
    // into a 3 x 3 grid (nine equal squares) to return a value
    // between 0 and 8.
    //
    // ToDo: consider generalizing this in GameTrackMotionFilter.
    fun int gametrack_xy_to_gesture_number() {
	GameTrakMotionFilter.game_trak_motion_filter() @=> GameTrakMotionFilter @ gtmf;
	gtmf.get_dispatcher(GameTrak.LEFT_X).get_state() $ ChannelEvt @=> ChannelEvt @ lx;
	gtmf.get_dispatcher(GameTrak.LEFT_Y).get_state() $ ChannelEvt @=> ChannelEvt @ ly;
	if ((lx == null) || (ly == null)) return 0; // not likely...

	Math.min(lx.get_value() * 3.0, 2.0) $ int => int ix;
	Math.min(ly.get_value() * 3.0, 2.0) $ int => int iy;
	<<< "x=", ix, "y=", iy >>>;
	return ix + (3 * iy);
    }

} // class FishPatch

// name of the directory containing the sound files
"/Users/r/Projects/DPP/perf_1.1/sndlib/" => string SOUND_LIB;


// initialize statics (once) when the file is loaded

// initialize the statics once at file load time
(new PlaybackRateOp) @=> FishPatch.PLAYBACK_RATE;
(new LoopingOp) @=> FishPatch.LOOPING;

[SOUND_LIB + "asdf.wav"] @=> FishPatch.FISH;

[SOUND_LIB + "ImAFish-01.wav",
 SOUND_LIB + "ImAFish-02.wav",
 SOUND_LIB + "ImAFish-03.wav",
 SOUND_LIB + "ImAFish-04.wav",
 SOUND_LIB + "ImAFish-05.wav"] @=> FishPatch.FISH;
[SOUND_LIB + "ImAFish-06.wav",
 SOUND_LIB + "ImAFish-07.wav",
 SOUND_LIB + "ImAFish-08.wav",
 SOUND_LIB + "ImAFish-09.wav",
 SOUND_LIB + "ImAFish-10.wav"] @=> FishPatch.FISHFISH;
[SOUND_LIB + "ImAFish-11.wav",
 SOUND_LIB + "ImAFish-12.wav",
 SOUND_LIB + "ImAFish-13.wav",
 SOUND_LIB + "ImAFish-14.wav",
 SOUND_LIB + "ImAFish-15.wav"] @=> FishPatch.FISH__FISH;
[SOUND_LIB + "ImAFish-17.wav",
 SOUND_LIB + "ImAFish-18.wav",
 SOUND_LIB + "ImAFish-19.wav",
 SOUND_LIB + "ImAFish-21.wav",
 SOUND_LIB + "ImAFish-22.wav",

 SOUND_LIB + "ImAFish-23.wav",
 SOUND_LIB + "ImAFish-24.wav",
 SOUND_LIB + "ImAFish-25.wav",
 SOUND_LIB + "ImAFish-26.wav",
 SOUND_LIB + "ImAFish-27.wav",
 SOUND_LIB + "ImAFish-28.wav",
 SOUND_LIB + "ImAFish-29.wav",
 SOUND_LIB + "ImAFish-30.wav",
 SOUND_LIB + "ImAFish-31.wav",
 SOUND_LIB + "ImAFish-32.wav",
 SOUND_LIB + "ImAFish-33.wav",
 SOUND_LIB + "ImAFish-34.wav",
 SOUND_LIB + "ImAFish-35.wav",
 SOUND_LIB + "ImAFish-36.wav",
 SOUND_LIB + "ImAFish-37.wav",
 SOUND_LIB + "ImAFish-38.wav",
 SOUND_LIB + "ImAFish-39.wav",

 SOUND_LIB + "ImAFish-40.wav",
 SOUND_LIB + "ImAFish-41.wav",
 SOUND_LIB + "ImAFish-42.wav",
 SOUND_LIB + "ImAFish-43.wav",
 SOUND_LIB + "ImAFish-44.wav",
 SOUND_LIB + "ImAFish-45.wav",
 SOUND_LIB + "ImAFish-46.wav",
 SOUND_LIB + "ImAFish-47.wav",
 SOUND_LIB + "ImAFish-48.wav",
 SOUND_LIB + "ImAFish-49.wav",
 SOUND_LIB + "ImAFish-50.wav",
 SOUND_LIB + "ImAFish-51.wav",
 SOUND_LIB + "ImAFish-52.wav",
 // SOUND_LIB + "ImAFish-53.wav",
 SOUND_LIB + "ImAFish-54.wav",
 SOUND_LIB + "ImAFish-55.wav",
 SOUND_LIB + "ImAFish-56.wav",
 SOUND_LIB + "ImAFish-57.wav",
 SOUND_LIB + "ImAFish-58.wav",
 SOUND_LIB + "ImAFish-59.wav",
 SOUND_LIB + "ImAFish-60.wav",
 SOUND_LIB + "ImAFish-61.wav",
 SOUND_LIB + "ImAFish-62.wav",
 SOUND_LIB + "ImAFish-63.wav",
 SOUND_LIB + "ImAFish-64.wav",
 SOUND_LIB + "ImAFish-65.wav",
 SOUND_LIB + "ImAFish-66.wav",
 SOUND_LIB + "ImAFish-67.wav",
 SOUND_LIB + "ImAFish-68.wav",
 SOUND_LIB + "ImAFish-69.wav",
 SOUND_LIB + "ImAFish-70.wav",
 SOUND_LIB + "ImAFish-71.wav"] @=> FishPatch.JARGON;

[SOUND_LIB + "ImAFish-73.wav",
 SOUND_LIB + "ImAFish-74.wav",
 SOUND_LIB + "ImAFish-75.wav",
 SOUND_LIB + "ImAFish-76.wav",
 SOUND_LIB + "ImAFish-77.wav"] @=> FishPatch.SO_HAPPY;

[SOUND_LIB + "ImAFish-20.wav"] @=> FishPatch.WHAT_THE_FISH;

[SOUND_LIB + "whale-01.wav",
 SOUND_LIB + "whale-02.wav",
 SOUND_LIB + "whale-03.wav",
 SOUND_LIB + "queer_notions_a.wav",
 SOUND_LIB + "el_pajaro_a.wav",
 SOUND_LIB + "rhythm_nation_07.wav"
 ] @=> FishPatch.WHALES;

<<< "registering fish patch" >>>;

// register the patch
PatchManager.register_patch(new FishPatch);



