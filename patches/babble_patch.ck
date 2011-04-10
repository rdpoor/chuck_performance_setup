// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_120700: Moved static initializers to end of file
// 100110_211355: Rename of QueueOp to Operation
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

// Iterator classes to help us update all active voices
class VoiceOp extends Operation {
    float _value;
    fun VoiceOp set_value(float value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) { 
	(element $ BabbleVox) @=> BabbleVox @ vox;
	if (vox.is_active()) a(vox);
	return null; 
    }
    fun void a(BabbleVox vox) { }; // to be subclassed
}
class PitchbendOp extends VoiceOp {
    fun void a(BabbleVox vox) { vox.set_pitchbend(_value); }
}
class BabbleRateOp extends VoiceOp {
    fun void a(BabbleVox vox) { vox.set_babble_rate(_value); }
}
class FundamentalMixOp extends VoiceOp {
    fun void a(BabbleVox vox) { vox.set_fundamental_mix(_value); }
}
class PhonemeSpanOp extends VoiceOp {
    fun void a(BabbleVox vox) { vox.set_phoneme_span(_value); }
}

// ================================================================
// class BabblePatch

class BabblePatch extends Patch {

    // define iterators for updating active voices.  These statics
    // are initialized at the bottom of the file (at load time).
    static PitchbendOp @ PITCHBEND; 
    static BabbleRateOp @ BABBLE_RATE; 
    static FundamentalMixOp @ FUNDAMENTAL_MIX; 
    static PhonemeSpanOp @ PHONEME_SPAN; 

    // ================================================================
    // instance variables

    BabbleVoxController _vox_controller;

    // values distributed to all voices
    0.0 => float _pitchbend;
    1.0 => float _babble_rate;
    1.0 => float _fundmental_mix;
    1.0 => float _phoneme_span;

    // ================================================================
    // controls specific to BabbleVox

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(BabbleVox voice, int midikey) {
	voice.set_pitch(midikey);
	voice.set_pitchbend(_pitchbend);
	voice.set_babble_rate(_babble_rate);
	voice.set_phoneme_span(_phoneme_span);
	voice.set_fundamental_mix(_fundmental_mix);
    }

    fun void set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	_update_voices(PITCHBEND, _pitchbend);
    }
    fun void set_babble_rate(float babble_rate) {
	Util.trace(this, ".set_babble_rate(" + babble_rate + ")");
	babble_rate => _babble_rate;
	_update_voices(BABBLE_RATE, _babble_rate);
    }
    fun void set_fundamental_mix(float fundamental_mix) {
	fundamental_mix => _fundmental_mix;
	_update_voices(FUNDAMENTAL_MIX, _fundmental_mix);
    }
    fun void set_phoneme_span(float phoneme_span) {
	phoneme_span => _phoneme_span;
	_update_voices(PHONEME_SPAN, _phoneme_span);
    }

    // Apply operator OP to all voices
    fun void _update_voices(VoiceOp op, float value) {
	_vox_controller.get_voices().apply(op.set_value(value));
    }

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "BabblePatch"; }

    fun Patch init() {
	Util.trace(this, ".init[1]()");
	_vox_controller.init();
	_vox_controller.set_mode(VoxController.POLYPHONIC);
	Util.trace(this, ".init[2]()");
	return this;
    }

    fun Patch start() {
	Util.trace(this, ".start[1]()");
	attach_std_controls();
	Util.trace(this, ".start[2]()");
	resend_std_controls();
	Util.trace(this, ".start[3]()");
	return this;
    }

    fun Patch stop() {
	Util.trace(this, ".stop[1]()");
	detach_std_controls();
	_vox_controller.all_notes_silent();
	Util.trace(this, ".stop[2]()");
	return this;
    }

    // ================================================================
    // subclassing StdControlObserver

    fun void handle_key_press(ChannelEvt msg) { 
	Util.trace(this, "handle_key_press[1]()");
	msg.get_channel() => int midikey;
	msg.get_value() => float velocity;
	if (velocity > 0.0) {
	    Util.trace(this, "handle_key_press[2]()");
	    _vox_controller.note_on(midikey) $ BabbleVox @=> BabbleVox @ voice;
	    init_voice(voice, midikey);
	} else {
	    Util.trace(this, "handle_key_press[3]()");
	    _vox_controller.note_off(midikey);
	}
	Util.trace(this, "handle_key_press[4]()");
    }
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_pitchbend(24.0 * (v - 0.5));
    }
    fun void handle_modwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_babble_rate(1.0 + 29 * v);
    }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	set_fundamental_mix(v);
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_phoneme_span(v);
    }
    fun void handle_knob_07(ChannelEvt msg) { }
    fun void handle_keyboard_pedal(ChannelEvt msg) { }
    fun void handle_game_trak_left_x(ChannelEvt msg) { }
    fun void handle_game_trak_left_y(ChannelEvt msg) { }
    fun void handle_game_trak_left_z(ChannelEvt msg) { }
    fun void handle_game_trak_right_x(ChannelEvt msg) { }
    fun void handle_game_trak_right_y(ChannelEvt msg) { }
    fun void handle_game_trak_right_z(ChannelEvt msg) { }
    fun void handle_game_trak_footswitch(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) { }
    fun void handle_game_trak_right_squelched(ChannelEvt msg) { }

}

// initialize statics when file is loaded
(new PitchbendOp) @=> BabblePatch.PITCHBEND;
(new BabbleRateOp) @=> BabblePatch.BABBLE_RATE;
(new FundamentalMixOp) @=> BabblePatch.FUNDAMENTAL_MIX;
(new PhonemeSpanOp) @=> BabblePatch.PHONEME_SPAN;

// register the patch
PatchManager.register_patch(new BabblePatch);
