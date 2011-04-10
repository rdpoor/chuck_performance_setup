// Basic patch for controlling a SproingVox
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100110_004902: Test scaffolding Version
// 100110_052815: Added GameTrak plucking control.  What this shows
//	me is that there's too much hysteresis in the GameTrak output
//	to be useful as a direct control for pitch.  Some things to
//	consider: hysteresis compensation (ugh), use a higher-level
//	algorithm for pitch selection (could be fun), give it up.
// 100110_211355: Rename of QueueOp to Operation
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

// ================================================================
// Iterator classes to help us update all active voices

class VoiceOp extends Operation {
    float _value;
    fun VoiceOp set_value(float value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) { 
	(element $ SproingVox) @=> SproingVox @ vox;
	if (vox.is_active()) apply_active(vox);
	return null; 
    }
    fun void apply_active(SproingVox vox) { }; // to be subclassed
}
class PitchbendOp extends VoiceOp {
    fun void apply_active(SproingVox vox) { vox.set_pitchbend(_value); }
}
class SproingDepthOp extends VoiceOp {
    fun void apply_active(SproingVox vox) { vox.set_sproing_depth(_value); }
}
class SproingDurOp extends Operation {
    dur _d;
    fun SproingDurOp set_value(dur d) { d => _d; return this; }
    fun Object apply(Object element, Object argument) {
	(element $ SproingVox) @=> SproingVox @ vox;
	if (vox.is_active()) vox.set_sproing_dur(_d);
	return null;
    }
}

// ================================================================
// Aux classes to make SpoingPatch an observer of GameTrackPluckDetector

class PluckObserver extends Observer {
    GameTrakPluckDetector _pluck_detector;
    SproingPatch @ _sproing_patch;
    fun PluckObserver init(SproingPatch sproing_patch, int x, int y) {
	_pluck_detector.init(x, y);
	sproing_patch @=> _sproing_patch;
	return this;
    }
    fun PluckObserver attach() {
	_pluck_detector.get_dispatcher().attach(this);
    }
    fun PluckObserver detach() {
	_pluck_detector.get_dispatcher().detach(this);
    }
}

// We create Left and Right observer classes so we can distinguish on
// the handle_pluck_xxxx() method.  ### Note, though, with the
// Observable argument, the receiver can discriminate by looking at
// the sender.
class PluckLeftObserver extends PluckObserver {
    fun void update(Observable o, Msg message) {
	_sproing_patch.handle_pluck_left(message $ PluckEvt);
    }
}
class PluckRightObserver extends PluckObserver {
    fun void update(Observable o, Msg message) {
	_sproing_patch.handle_pluck_right(message $ PluckEvt);
    }
}


// ================================================================

class SproingPatch extends Patch {

    // define iterators for updating active voices.  these statics are
    // initalized at load time at the bottom of the file
    static PitchbendOp @ PITCHBEND_OP; 
    static SproingDepthOp @ SPROING_DEPTH_OP; 
    static SproingDurOp @ SPROING_DUR_OP;

    SproingVoxController _vox_controller;

    PluckLeftObserver _pluck_left_observer;
    PluckRightObserver _pluck_right_observer;

    float _pitch;		// last plucked pitch

    // values distributed to all voices
    float _pitchbend;
    float _sproing_depth;
    dur _sproing_dur;

    // ================================================================
    // controls specific to SproingPatch

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(SproingVox voice, float gain, int midikey) {
	voice.set_pitch(midikey);
	voice.set_gain(gain);
	voice.set_pitchbend(_pitchbend);
	voice.set_sproing_depth(_sproing_depth);
	voice.set_sproing_dur(_sproing_dur);
    }

    fun Queue get_voices() { return _vox_controller.get_voices(); }

    fun void set_pitchbend(float pitchbend) {
	Util.trace(this, ".set_pitchbend(" + pitchbend + ")");
	pitchbend => _pitchbend;
	get_voices().apply(PITCHBEND_OP.set_value(_pitchbend));
    }

    fun void set_sproing_depth(float sproing_depth) {
	Util.trace(this, ".set_sproing_depth(" + sproing_depth + ")");
	sproing_depth => _sproing_depth;
	get_voices().apply(SPROING_DEPTH_OP.set_value(_sproing_depth));
    }

    fun void set_sproing_dur(dur sproing_dur) {
	Util.trace(this, ".set_sproing_dur(" + Util.to_s(sproing_dur) + ")");
	sproing_dur => _sproing_dur;
	get_voices().apply(SPROING_DUR_OP.set_value(_sproing_dur));
    }

    fun float get_pitch() {
	return Util.quantize(_pitch, 1.0);
    }

    fun void set_pitch(float pitch) {
	pitch => _pitch;
    }

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "SproingPatch"; }

    fun Patch init() {
	set_pitchbend(0.0);
	set_sproing_depth(1.0);
	set_sproing_dur(100::ms);
	_vox_controller.init();
	_vox_controller.set_mode(VoxController.POLYPHONIC);
	_pluck_left_observer.init(this, GameTrak.LEFT_X, GameTrak.LEFT_Y);
	_pluck_right_observer.init(this, GameTrak.RIGHT_X, GameTrak.RIGHT_Y);
	return this;
    }

    fun Patch start() {
	attach_std_controls();
	resend_std_controls();
	_pluck_left_observer.attach();
	_pluck_right_observer.attach();
	return this;
    }

    fun Patch stop() {
	_pluck_right_observer.detach();
	_pluck_left_observer.detach();
	detach_std_controls();
	_vox_controller.all_notes_silent();
	return this;
    }

    // ================================================================
    // here's where we field messages from GameTrakPluckDetector

    fun void handle_pluck_left(PluckEvt msg) {
	<<< msg.toString() >>>;
	handle_pluck_aux(msg);
    }

    fun void handle_pluck_right(PluckEvt msg) {
	<<< msg.toString() >>>;
	handle_pluck_aux(msg);
    }

    fun void handle_pluck_aux(PluckEvt msg) {
	_vox_controller.note_on(0) $ SproingVox @=> SproingVox @ voice;
	voice.init_all(get_pitch(), 
		       0.8, // msg.get_amplitude(),
		       _pitchbend, 
		       _sproing_depth, 
		       _sproing_dur);
    }

    // ================================================================
    // subclassing StdControlObserver

    fun void handle_key_press(ChannelEvt msg) { 
	msg.get_channel() => int key;
	msg.get_value() => float vel;
	if (vel > 0.0) {
	    _vox_controller.note_on(key) $ SproingVox @=> SproingVox @ voice;
	    voice.init_all(key, vel, _pitchbend, _sproing_depth, _sproing_dur);
	} else {
	    _vox_controller.note_off(key);
	}
    }
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	(v - 0.5) * 24.0 => float semitones;
	set_pitchbend(Math.pow(2.0, semitones/12.0));
    }
    fun void handle_modwheel(ChannelEvt msg) { }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	set_sproing_depth(v*5);
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_sproing_dur(100::ms * v);
    }
    fun void handle_knob_07(ChannelEvt msg) { }
    fun void handle_keyboard_pedal(ChannelEvt msg) { }

    // we also receive GameTrak position messages courtesy of Patch
    // extends StdControlsObserver
    fun void handle_game_trak_left_x(ChannelEvt msg) { }
    fun void handle_game_trak_left_y(ChannelEvt msg) { }
    fun void handle_game_trak_left_z(ChannelEvt msg) { }
    fun void handle_game_trak_right_x(ChannelEvt msg) { 
    }
    fun void handle_game_trak_right_y(ChannelEvt msg) { 
	msg.get_value() => float v;
	Math.max(0.0, Util.lerp(v, 0.5, 1.0, 0.0, 1.0)) => float g;
	// <<< g >>>;
	AudioIO.audio_io().set_pre_gain(g);
    }
    fun void handle_game_trak_right_z(ChannelEvt msg) {
	msg.get_value() => float v;
	set_pitch(Util.lerp(v, 0.4, 0.6, 60, 72));
    }
    fun void handle_game_trak_footswitch(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) { }
    fun void handle_game_trak_right_squelched(ChannelEvt msg) { }

}


// initialize statics at file load time
(new PitchbendOp) @=> SproingPatch.PITCHBEND_OP;
(new SproingDepthOp) @=> SproingPatch.SPROING_DEPTH_OP;
(new SproingDurOp) @=> SproingPatch.SPROING_DUR_OP;

// register the patch
PatchManager.register_patch(new SproingPatch);
