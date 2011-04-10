// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_120700: Moved static initializers to end of file
// 100110_211355: Rename of QueueOp to Operation
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

// Thoughts about a GameTrak plucked patch:
//
// Plucking left or right GameTrak string starts a note.  With pedal
// down, new notes accumulate (voice controller mode = MULTIPHONIC),
// otherwise new notes re-start existing note (voice controller mode =
// STRICT_MONOPHONIC).  Pulling back on right string stops all notes.
//
// GameTrak Right Z determines pitch.
// GameTrak Right X determines octave.
//
// None of this is implemented yet!

// Iterator classes to help us update all active voices
class VoiceOp extends Operation {
    float _value;
    fun VoiceOp set_value(float value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) { 
	(element $ NoseVox) @=> NoseVox @ vox;
	if (vox.is_active()) apply_active(vox);
	return null; 
    }
    fun void apply_active(NoseVox vox) { }; // to be subclassed
}
class PitchOp extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_pitch(_value); }
}
class GainOp extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_gain(_value); }
}
class PitchbendOp extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_pitchbend(_value); }
}
class Formant1Op extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_formant1(_value); }
}
class Formant2Op extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_formant2(_value); }
}
class Formant3Op extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_formant3(_value); }
}
class ResonanceOp extends VoiceOp {
    fun void apply_active(NoseVox vox) { vox.set_resonance(_value); }
}

// ================================================================
// shim classes to make PickPatch observe GameTrakPluckDetector msgs
// (since Patch is not a subclass of Observer)

class PluckObserver extends Observer {
    PickPatch @ _pick_patch;
    fun PluckObserver init(PickPatch pick_patch) {
	pick_patch @=> _pick_patch;
	return this;
    }
}
class PluckLeftObserver extends PluckObserver {
    fun void update(Observable o, Msg message) {
	_pick_patch.handle_pluck_left(message $ PluckEvt);
    }
}
class PluckRightObserver extends PluckObserver {
    fun void update(Observable o, Msg message) {
	_pick_patch.handle_pluck_right(message $ PluckEvt);
    }
}



// ================================================================
// class PickPatch

class PickPatch extends Patch {

    // define iterators for updating active voices.  these statics are
    // initialized once at load time at the bottom of the file.
    static PitchOp @ PITCH_OP; 
    static GainOp @ GAIN_OP; 
    static PitchbendOp @ PITCHBEND_OP; 
    static Formant1Op @ FORMANT1_OP; 
    static Formant2Op @ FORMANT2_OP; 
    static Formant3Op @ FORMANT3_OP; 
    static ResonanceOp @ RESONANCE_OP; 

    // ================================================================
    // instance variables

    NoseVoxController _vox_controller;
    GameTrakPluckDetector _pluck_left_detector;
    GameTrakPluckDetector _pluck_right_detector;
    PluckLeftObserver _pluck_left_observer;
    PluckRightObserver _pluck_right_observer;

    // pluck only
    float _pitch;

    // values distributed to all voices
    float _gain;
    float _pitchbend;
    float _formant1;
    float _formant2;
    float _formant3;
    float _resonance;

    // ================================================================
    // controls specific to PickPatch

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(NoseVox voice, float pitch) {
	voice.set_pitch(pitch);
	voice.set_gain(_gain);
	voice.set_pitchbend(_pitchbend);
	voice.set_formant1(_formant1);
	voice.set_formant2(_formant2);
	voice.set_formant3(_formant3);
	voice.set_resonance(_resonance);
    }

    fun float get_pitch() { return _pitch; }
    fun PickPatch set_pitch(float pitch) { 
	pitch => _pitch; 
	_vox_controller.get_voices().apply(PITCH_OP.set_value(_pitch));
	return this; 
    }

    fun void set_gain(float gain) {
	Util.trace(this, ".set_gain(" + gain + ")");
	gain => _gain;
	_vox_controller.get_voices().apply(GAIN_OP.set_value(_gain));
    }
    fun void set_pitchbend(float pitchbend) {
	Util.trace(this, ".set_pitchbend(" + pitchbend + ")");
	pitchbend => _pitchbend;
	_vox_controller.get_voices().apply(PITCHBEND_OP.set_value(_pitchbend));
    }
    fun void set_formant1(float formant1) {
	Util.trace(this, ".set_formant1(" + formant1 + ")");
	formant1 => _formant1;
	_vox_controller.get_voices().apply(FORMANT1_OP.set_value(_formant1));
    }
    fun void set_formant2(float formant2) {
	Util.trace(this, ".set_formant2(" + formant2 + ")");
	formant2 => _formant2;
	_vox_controller.get_voices().apply(FORMANT2_OP.set_value(_formant2));
    }
    fun void set_formant3(float formant3) {
	Util.trace(this, ".set_formant3(" + formant3 + ")");
	formant3 => _formant3;
	_vox_controller.get_voices().apply(FORMANT3_OP.set_value(_formant3));
    }
    fun void set_resonance(float resonance) {
	Util.trace(this, ".set_resonance(" + resonance + ")");
	resonance => _resonance;
	_vox_controller.get_voices().apply(RESONANCE_OP.set_value(_resonance));
    }

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "PickPatch"; }

    fun Patch init() {
	set_gain(1.0);
	set_pitchbend(0.0);
	set_formant1(0.0);
	set_formant2(0.0);
	set_formant3(0.0);
	set_resonance(0.0);
	_pluck_left_detector.init(GameTrak.LEFT_X, GameTrak.LEFT_Y);
	_pluck_right_detector.init(GameTrak.RIGHT_X, GameTrak.RIGHT_Y);
	_pluck_left_observer.init(this);
	_pluck_right_observer.init(this);
	_vox_controller.init();
	_vox_controller.set_mode(VoxController.POLYPHONIC_STRICT);
	return this;
    }

    fun Patch start() {
	attach_std_controls();
	resend_std_controls();
	// start receiving pluck messages
	_pluck_left_detector.get_dispatcher().attach(_pluck_left_observer);
	_pluck_right_detector.get_dispatcher().attach(_pluck_right_observer);
	return this;
    }

    fun Patch stop() {
	// stop receiving pluck messages
	_pluck_right_detector.get_dispatcher().detach(_pluck_right_observer);
	_pluck_left_detector.get_dispatcher().detach(_pluck_left_observer);
	detach_std_controls();
	_vox_controller.all_notes_silent();
	return this;
    }

    // ================================================================
    // target methods for PluckObserver

    fun void handle_pluck_left(PluckEvt message) {
	<<< now, me, this.toString(), ".handle_pluck_left()" >>>;
	handle_pluck(message);
    }
    fun void handle_pluck_right(PluckEvt message) {
	<<< now, me, this.toString(), ".handle_pluck_right()" >>>;
	handle_pluck(message);
    }
    fun void handle_pluck(PluckEvt message) {
	_vox_controller.note_on(1) $ NoseVox @=> NoseVox @ voice;
	init_voice(voice, get_pitch());
    }

    // ================================================================
    // subclassing StdControlObserver

    fun void handle_key_press(ChannelEvt msg) { 
	msg.get_channel() => int midikey;
	msg.get_value() => float velocity;
	if (velocity > 0.0) {
	    _vox_controller.note_on(midikey) $ NoseVox @=> NoseVox @ voice;
	    init_voice(voice, midikey);
	} else {
	    _vox_controller.note_off(midikey);
	}
    }
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	Util.lerp(v, -12.0, 12.0) => float semitones;
	set_pitchbend(semitones);
    }
    fun void handle_modwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_resonance(v);
    }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	set_formant1(v);
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_formant2(v);
    }
    fun void handle_knob_07(ChannelEvt msg) {
	msg.get_value() => float v;
	set_formant3(v);
    }
    fun void handle_keyboard_pedal(ChannelEvt msg) { }
    fun void handle_game_trak_left_x(ChannelEvt msg) { handle_knob_05(msg); }
    fun void handle_game_trak_left_y(ChannelEvt msg) { handle_knob_06(msg); }
    fun void handle_game_trak_left_z(ChannelEvt msg) { }
    fun void handle_game_trak_right_x(ChannelEvt msg) { }
    fun void handle_game_trak_right_y(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_gain(v);
    }
    fun void handle_game_trak_right_z(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_pitch(_v_to_pitch(v)); 
    }
    fun void handle_game_trak_footswitch(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) { 
	// when squelching, revert to corresponding oxygen8 controls
	if (msg.get_value() == 1.0) {
	    _get_std_controls()._knob_05_observer.resend();
	    _get_std_controls()._knob_06_observer.resend();
	    _get_std_controls()._knob_07_observer.resend();
	}
    }
    fun void handle_game_trak_right_squelched(ChannelEvt msg) {
	// when squelching, revert to corresponding oxygen8 controls
	if (msg.get_value() == 1.0) {
	    _get_std_controls()._modwheel_observer.resend();
	    set_gain(1.0);	// no corresponding control...
	    _get_std_controls()._pitchwheel_observer.resend();
	}
    }

    // ================================================================
    // private methods

    // _v_to_pitch: convert GameTrak z axis to a MIDI pitch
    //
    // TODO: needs hysterisis
    // TODO: make quantize blend parameter controllable?
    //
    fun float _v_to_pitch(float v) {
	Util.lerp(v, 0.35, 0.65, 40, 80) => float pitch;
	return Util.quantize(pitch, 0.5);
    }
}

// initialize statics at load time
(new PitchOp) @=> PickPatch.PITCH_OP;
(new GainOp) @=> PickPatch.GAIN_OP;
(new PitchbendOp) @=> PickPatch.PITCHBEND_OP;
(new Formant1Op) @=> PickPatch.FORMANT1_OP;
(new Formant2Op) @=> PickPatch.FORMANT2_OP;
(new Formant3Op) @=> PickPatch.FORMANT3_OP;
(new ResonanceOp) @=> PickPatch.RESONANCE_OP;

// register the patch
PatchManager.register_patch(new PickPatch);
