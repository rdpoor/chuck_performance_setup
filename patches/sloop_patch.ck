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
	(element $ SloopVox) @=> SloopVox @ vox;
	if (vox.is_active()) a(vox);
	return null; 
    }
    fun void a(SloopVox vox) { }; // to be subclassed
}
class GainOp extends VoiceOp {
    fun void a(SloopVox vox) { vox.set_gain(_value); }
}
class InitialPhaseOp extends VoiceOp {
    fun void a(SloopVox vox) { vox.set_initial_phase(_value); }
}
class LoopDurOp extends Operation {
    dur _dur;
    fun LoopDurOp set_value(dur duration) { duration => _dur; return this; }
    fun Object apply(Object element, Object argument) {
	(element $ SloopVox) @=> SloopVox @ vox;
	if (vox.is_active()) vox.set_loop_duration(_dur);
	return null;
    }
}
class DutyCycleOp extends VoiceOp {
    fun void a(SloopVox vox) { vox.set_duty_cycle(_value); }
}
class PlaybackRateOp extends VoiceOp {
    fun void a(SloopVox vox) { vox.set_playback_rate(_value); }
}

// ================================================================
// class SloopPatch

class SloopPatch extends Patch {

    // define iterators for updating active voices.  these statics are
    // initialized once at file load time at the bottom of the file.
    static GainOp @ GAIN; 
    static InitialPhaseOp @ INITIAL_PHASE; 
    static LoopDurOp @ LOOP_DURATION; 
    static DutyCycleOp @ DUTY_CYCLE; 
    static PlaybackRateOp @ PLAYBACK_RATE; 

    // ================================================================
    // instance variables

    SloopVoxController _vox_controller;

    // values distributed to all voices
    float _gain;
    float _initial_phase;
    dur _loop_duration;
    float _duty_cycle;
    float _playback_rate;

    // ================================================================
    // should be abstracted into a voice bank

    "/Users/r/Library/Sounds/banks/hits/" => string SOUND_LIB;

    // Load up the library of sounds
    [SOUND_LIB + "unchained_a.wav",
     SOUND_LIB + "boogie_oogie_01.wav",
     SOUND_LIB + "boogie_oogie_02.wav",
     SOUND_LIB + "boogie_oogie_03.wav",
     SOUND_LIB + "cantando_no_toro_01.wav",
     SOUND_LIB + "cats_squirrel.wav",
     SOUND_LIB + "cats_squirrel_02.wav",
     SOUND_LIB + "fresh_garbage_01.wav",
     SOUND_LIB + "fresh_garbage_02.wav",
     SOUND_LIB + "fresh_garbage_03.wav",
     SOUND_LIB + "mechanical_world_01.wav",
     SOUND_LIB + "mechanical_world_02.wav",
     SOUND_LIB + "mechanical_world_03.wav",
     SOUND_LIB + "moaning_low_01.wav",
     SOUND_LIB + "moaning_low_02.wav",
     SOUND_LIB + "music_for_a_large_ensemble.wav",
     SOUND_LIB + "rhythm_nation_01.wav",
     SOUND_LIB + "rhythm_nation_02.wav",
     SOUND_LIB + "rhythm_nation_03.wav",
     SOUND_LIB + "rhythm_nation_04.wav",
     SOUND_LIB + "rhythm_nation_05.wav",
     SOUND_LIB + "rhythm_nation_06.wav",
     SOUND_LIB + "rhythm_nation_07.wav",
     SOUND_LIB + "rhythm_nation_08.wav",
     SOUND_LIB + "sweet_sixteen_01.wav",
     SOUND_LIB + "sweet_sixteen_02.wav",
     SOUND_LIB + "sweet_sixteen_03.wav",
     SOUND_LIB + "sweet_sixteen_04.wav",
     SOUND_LIB + "sweet_sixteen_05.wav",
     SOUND_LIB + "sweet_soul_revue_01.wav",
     SOUND_LIB + "sweet_soul_revue_02.wav",
     SOUND_LIB + "sweet_soul_revue_03.wav",
     SOUND_LIB + "sweet_soul_revue_04.wav",
     SOUND_LIB + "sweet_soul_revue_05.wav",
     SOUND_LIB + "downtown_a.wav",
     SOUND_LIB + "el_pajaro_a.wav",
     SOUND_LIB + "i_will_survive_a.wav",
     SOUND_LIB + "if_a.wav",
     SOUND_LIB + "live_to_tell_a.wav",
     SOUND_LIB + "longbottom_a.wav",
     SOUND_LIB + "lucky_star_a.wav",
     SOUND_LIB + "material_a.wav",
     SOUND_LIB + "queer_notions_a.wav",
     SOUND_LIB + "the_box_a.wav",
     SOUND_LIB + "unchained_a.wav"] @=> static string SOUND_BANK[];

    // ================================================================
    // controls specific to SloopPatch

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(SloopVox voice, string filename) {
	voice.load_sample_data(filename);
	voice.set_gain(_gain);
	voice.set_initial_phase(_initial_phase);
	voice.set_loop_duration(_loop_duration);
	voice.set_duty_cycle(_duty_cycle);
	voice.set_playback_rate(_playback_rate);
    }

    fun void set_gain(float gain) {
	Util.trace(this, ".set_gain(" + gain + ")");
	gain => _gain;
	_vox_controller.get_voices().apply(GAIN.set_value(_gain));
    }
    fun void set_initial_phase(float initial_phase) {
	Util.trace(this, ".set_initial_phase(" + initial_phase + ")");
	initial_phase => _initial_phase;
	_vox_controller.get_voices().apply(INITIAL_PHASE.set_value(_initial_phase));
    }
    fun void set_loop_duration(dur loop_duration) {
	// Util.trace(this, ".set_loop_duration(" + loop_duration + ")");
	loop_duration => _loop_duration;
	_vox_controller.get_voices().apply(LOOP_DURATION.set_value(_loop_duration));
    }
    fun void set_duty_cycle(float duty_cycle) {
	Util.trace(this, ".set_duty_cycle(" + duty_cycle + ")");
	duty_cycle => _duty_cycle;
	_vox_controller.get_voices().apply(DUTY_CYCLE.set_value(_duty_cycle));
    }	
    fun void set_playback_rate(float playback_rate) {
	Util.trace(this, ".set_playback_rate(" + playback_rate + ")");
	playback_rate => _playback_rate;
	_vox_controller.get_voices().apply(PLAYBACK_RATE.set_value(_playback_rate));
    }	

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "SloopPatch"; }

    fun Patch init() {
	set_gain(1.0);
	set_initial_phase(0.0);
	set_loop_duration(1::second);
	set_duty_cycle(1.0);
	set_playback_rate(1.0);
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
	if (midikey >= SOUND_BANK.size()) {
	    <<< now, me, this.toString(), "handle_key_press(): midikey", midikey, "out of range" >>>;
	    return;
	}
	msg.get_value() => float velocity;
	if (velocity > 0.0) {
	    _vox_controller.note_on(midikey) $ SloopVox @=> SloopVox @ voice;
	    // NOTE: vox_controller.note_on() tries to return a voice
	    // with a matching ID, so we may not end up reloading sound
	    // data as often as you think.
	    init_voice(voice, SOUND_BANK[midikey]);
	} else {
	    _vox_controller.note_off(midikey);
	}
    }
    fun void handle_pitchwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	(v - 0.5) * 24.0 => float semitones;
	set_playback_rate(Math.pow(2.0, semitones/12.0));
    }
    fun void handle_modwheel(ChannelEvt msg) { 
	msg.get_value() => float v;
	Util.lerp(v, 1.0, 30.0) => float hz;
	set_loop_duration((1.0/hz)::second);
    }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	set_initial_phase(v);
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_duty_cycle(v);
    }
    fun void handle_knob_07(ChannelEvt msg) { }
    fun void handle_keyboard_pedal(ChannelEvt msg) { }
    fun void handle_game_trak_left_x(ChannelEvt msg) { handle_knob_05(msg); }
    fun void handle_game_trak_left_y(ChannelEvt msg) { handle_knob_06(msg); }
    fun void handle_game_trak_left_z(ChannelEvt msg) { 
	msg.get_value() => float v;
	// make right_z be up one octave from left_z
	// ((v - 0.5) * 48.0) - 6.0 => float semitones;
	// not really...
	((v - 0.5) * 48.0) + 6.0 => float semitones;
	set_playback_rate(Math.pow(2.0, semitones/12.0));
    }
    fun void handle_game_trak_right_x(ChannelEvt msg) { handle_modwheel(msg); }
    fun void handle_game_trak_right_y(ChannelEvt msg) { 
	msg.get_value() => float v;
	set_gain(v);
    }
    fun void handle_game_trak_right_z(ChannelEvt msg) { 
	msg.get_value() => float v;
	// make right_z be up one octave from left_z
	((v - 0.5) * 48.0) + 6.0 => float semitones;
	set_playback_rate(Math.pow(2.0, semitones/12.0));
    }
    fun void handle_game_trak_footswitch(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) {
	// when squelching, revert to corresponding oxygen8 controls
	if (msg.get_value() == 1.0) {
	    _get_std_controls()._knob_05_observer.resend();
	    _get_std_controls()._knob_06_observer.resend();
	    _get_std_controls()._pitchwheel_observer.resend();
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

// initialize the statics once at file load time
(new GainOp) @=> SloopPatch.GAIN;
(new InitialPhaseOp) @=> SloopPatch.INITIAL_PHASE;
(new LoopDurOp) @=> SloopPatch.LOOP_DURATION;
(new DutyCycleOp) @=> SloopPatch.DUTY_CYCLE;
(new PlaybackRateOp) @=> SloopPatch.PLAYBACK_RATE;


// register the patch
PatchManager.register_patch(new SloopPatch);
