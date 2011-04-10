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
	(element $ FarfisaVox) @=> FarfisaVox @ vox;
	if (vox.is_active()) a(vox);
	return null; 
    }
    fun void a(FarfisaVox vox) { }; // to be subclassed
}
class PitchbendOp extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_pitchbend(_value); }
}
class FrequencySpreadOp extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_frequency_spread(_value); }
}
class ModulationDepthOp extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_modulation_depth(_value); }
}
class ModulationSpeedOp extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_modulation_speed(_value); }
}
class Drawbar1Op extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_drawbar1(_value); }
}
class Drawbar2Op extends VoiceOp {
    fun void a(FarfisaVox vox) { vox.set_drawbar2(_value); }
}

class FarfisaPatch extends Patch {

    // ================================================================
    // class constants

    // define iterators for updating active voices
    // initialized at the bottom of the file at load time
    static PitchbendOp @ PITCHBEND; 
    static FrequencySpreadOp @ FREQUENCY_SPREAD; 
    static ModulationDepthOp @ MODULATION_DEPTH; 
    static ModulationSpeedOp @ MODULATION_SPEED; 
    static Drawbar1Op @ DRAWBAR1; 
    static Drawbar2Op @ DRAWBAR2; 

    // ================================================================
    // instance variables

    FarfisaVoxController _vox_controller;

    // values distributed to all voices
    0.0 => float _pitchbend;
    0.0 => float _frequency_spread;
    0.0 => float _modulation_depth;
    0.0 => float _modulation_speed;
    0.0 => float _drawbar1;
    0.0 => float _drawbar2;

    // ================================================================
    // controls specific to FarfisaVox

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(FarfisaVox voice, float aftertouch, int midikey) {
	voice.set_aftertouch(aftertouch);
	voice.set_pitch(midikey);
	voice.set_pitchbend(_pitchbend);
	voice.set_frequency_spread(_frequency_spread);
	voice.set_modulation_depth(_modulation_depth);
	voice.set_modulation_speed(_modulation_speed);
	voice.set_drawbar1(_drawbar1);
	voice.set_drawbar2(_drawbar2);
    }

    fun void set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	_update_voices(PITCHBEND, _pitchbend);
    }
    fun void set_frequency_spread(float frequency_spread) {
	frequency_spread => _frequency_spread;
	_update_voices(FREQUENCY_SPREAD, _frequency_spread);
    }
    fun void set_modulation_depth(float modulation_depth) {
	modulation_depth => _modulation_depth;
	_update_voices(MODULATION_DEPTH, _modulation_depth);
    }
    fun void set_modulation_speed(float modulation_speed) {
	modulation_speed => _modulation_speed;
	_update_voices(MODULATION_SPEED, _modulation_speed);
    }
    fun void set_drawbar1(float drawbar1) {
	drawbar1 => _drawbar1;
	_update_voices(DRAWBAR1, _drawbar1);
    }
    fun void set_drawbar2(float drawbar2) {
	drawbar2 => _drawbar2;
	_update_voices(DRAWBAR2, _drawbar2);
    }

    // Apply operator OP to all voices
    fun void _update_voices(VoiceOp op, float value) {
	_vox_controller.get_voices().apply(op.set_value(value));
    }

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "FarfisaPatch"; }

    fun Patch init() {
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
	    _vox_controller.note_on(midikey) $ FarfisaVox @=> FarfisaVox @ voice;
	    init_voice(voice, velocity, midikey);
	} else {
	    if (Util.is_tracing()) Util.trace(this, "handle_key_press[3]()");
	    _vox_controller.note_off(midikey);
	}
	if (Util.is_tracing()) Util.trace(this, "handle_key_press[4]()");
    }
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_pitchbend(24.0 * (v - 0.5));
    }
    fun void handle_modwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_modulation_depth((v + 0.1) * 0.1);
	set_modulation_speed(v * 10.0);
    }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	set_drawbar1(v * 128.0);
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_drawbar2(v * 128.0);
    }
    fun void handle_knob_07(ChannelEvt msg) {
	msg.get_value() => float v;
	set_frequency_spread(v * .05);
    }
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

// initialize statics at load time
(new PitchbendOp) @=> FarfisaPatch.PITCHBEND;
(new FrequencySpreadOp) @=> FarfisaPatch.FREQUENCY_SPREAD;
(new ModulationDepthOp) @=> FarfisaPatch.MODULATION_DEPTH;
(new ModulationSpeedOp) @=> FarfisaPatch.MODULATION_SPEED;
(new Drawbar1Op) @=> FarfisaPatch.DRAWBAR1;
(new Drawbar2Op) @=> FarfisaPatch.DRAWBAR2;

// register the patch
PatchManager.register_patch(new FarfisaPatch);
