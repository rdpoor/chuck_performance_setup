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
// class NosePatch

class NosePatch extends Patch {

    // define iterators for updating active voices.  these statics are
    // initalized at load time at the bottom of the file
    static GainOp @ GAIN_OP; 
    static PitchbendOp @ PITCHBEND_OP; 
    static Formant1Op @ FORMANT1_OP; 
    static Formant2Op @ FORMANT2_OP; 
    static Formant3Op @ FORMANT3_OP; 
    static ResonanceOp @ RESONANCE_OP; 

    // ================================================================
    // instance variables

    NoseVoxController _vox_controller;

    // values distributed to all voices
    float _gain;
    float _pitchbend;
    float _formant1;
    float _formant2;
    float _formant3;
    float _resonance;

    // ================================================================
    // controls specific to NosePatch

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(NoseVox voice, int midikey) {
	voice.set_pitch(midikey);
	voice.set_gain(_gain);
	voice.set_pitchbend(_pitchbend);
	voice.set_formant1(_formant1);
	voice.set_formant2(_formant2);
	voice.set_formant3(_formant3);
	voice.set_resonance(_resonance);
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

    fun string get_name() { return "NosePatch"; }

    fun Patch init() {
	set_gain(1.0);
	set_pitchbend(0.0);
	set_formant1(0.0);
	set_formant2(0.0);
	set_formant3(0.0);
	set_resonance(0.0);
	_vox_controller.init();
	_vox_controller.set_mode(VoxController.POLYPHONIC);
	return this;
    }

    fun Patch start() {
	attach_std_controls();
	resend_std_controls();
	return this;
    }

    fun Patch stop() {
	detach_std_controls();
	_vox_controller.all_notes_silent();
	return this;
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
	(v - 0.5) * 24.0 => float semitones;
	set_pitchbend(Math.pow(2.0, semitones/12.0));
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
    fun void handle_game_trak_left_z(ChannelEvt msg) { handle_knob_07(msg); }
    fun void handle_game_trak_right_x(ChannelEvt msg) { handle_modwheel(msg); }
    fun void handle_game_trak_right_y(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_gain(v);
    }
    fun void handle_game_trak_right_z(ChannelEvt msg) { handle_pitchwheel(msg); }
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

}

// initialize statics at file load time
(new GainOp) @=> NosePatch.GAIN_OP;
(new PitchbendOp) @=> NosePatch.PITCHBEND_OP;
(new Formant1Op) @=> NosePatch.FORMANT1_OP;
(new Formant2Op) @=> NosePatch.FORMANT2_OP;
(new Formant3Op) @=> NosePatch.FORMANT3_OP;
(new ResonanceOp) @=> NosePatch.RESONANCE_OP;

// register the patch
PatchManager.register_patch(new NosePatch);
