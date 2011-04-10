// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_120700: Moved static initializers to end of file
// 100110_211355: Rename of QueueOp to Operation
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

// Iterator classes to help us update all active voices
class FloatOp extends Operation {
    float _value;
    fun FloatOp set_value(float value) { value => _value; return this; }
    fun Object apply(Object element, Object argument) { 
	(element $ PipesVox) @=> PipesVox @ vox;
	if (vox.is_active()) a(vox);
	return null; 
    }
    fun void a(PipesVox vox) { }; // to be subclassed
}
class PitchbendOp extends FloatOp {
    fun void a(PipesVox vox) { vox.set_pitchbend(_value); }
}
class ResonanceOp extends FloatOp {
    fun void a(PipesVox vox) { vox.set_resonance(_value); }
}
class SoundSourceOp extends Operation {
    fun Object apply(Object element, Object argument) {
	(element $ PipesVox) @=> PipesVox @ vox;
	if (vox.is_active()) vox.set_sound_source(argument $ SndBuf);
	return null;
    }
}

class PipesPatch extends Patch {

    // ================================================================
    // class constants

    // define iterators for updating active voices.  these statics are
    // initialized once at load time at the bottom of the file.
    static PitchbendOp @ PITCHBEND; 
    static ResonanceOp @ RESONANCE; 
    static SoundSourceOp @ SOUND_SOURCE; 

    // ================================================================
    // instance variables

    PipesVoxController _vox_controller;

    0.0 => float _pitchbend;
    1.0 => float _resonance;
    1.0 => float _playback_rate;
    // implementation note: we use one SndBuf throughout, but call
    // _sound_source.read(filename) when we want to source sounds.
    SndBuf _sound_source;
    "" => string _sound_file;

    "/Users/r/Library/Sounds/banks/p_pipes/" => string SOUND_LIB;

    [ 
     SOUND_LIB + "224V1642_c.wav", // banda
     SOUND_LIB + "224V1676_c.wav", // short, industrial noise?
     SOUND_LIB + "224V1679_c.wav", // shaman, whistle and shake
     SOUND_LIB + "224V1762_c.wav", // good banda!
     SOUND_LIB + "224V2276_c.wav", // fast polka banda
     SOUND_LIB + "224V2363_c.wav", // remote banda, pop, whoa voices
     SOUND_LIB + "224V2557_c.wav", // pipe organ
     SOUND_LIB + "224V3857_c.wav", // finches (budgies?)
     SOUND_LIB + "224V3865_c.wav", // mostly silent, horn and morning dove
     SOUND_LIB + "224V4467_c.wav", // church bells
     SOUND_LIB + "224V4899_c.wav", // street musians - accordian and voives
     SOUND_LIB + "224V4912_c.wav", // hurdy gurdy (good)
     SOUND_LIB + "224V4959_c.wav", // street voives, laughing
     SOUND_LIB + "224V4963_c.wav", // hurdy gurdy ii
     SOUND_LIB + "224V5006_c.wav", // accordian, clap dance
     SOUND_LIB + "224V5020_c.wav", // crowd noise, laughter
     SOUND_LIB + "224V5052_c.wav", // opera , soprani
     SOUND_LIB + "224V5061_c.wav", // opera, both
     SOUND_LIB + "224V5064_c.wav", // applause
     SOUND_LIB + "224V5435_c.wav", // inaudible choir
     SOUND_LIB + "224V5738_c.wav", // street morocco - percussive
     SOUND_LIB + "224V6017_c.wav", // street morocco - hawkers
     SOUND_LIB + "224V6752_c.wav", // minaret
     SOUND_LIB + "224V6801_c.wav", // horsehoofs and barbara
     SOUND_LIB + "224V7013_c.wav"  // fast drumming fez
      ] @=> string _sound_files[];

    [ 
     "banda I",			  // SOUND_LIB + "224V1642_c.wav", // 
     "short, industrial noise",	  // SOUND_LIB + "224V1676_c.wav", // 
     "shaman, whistle and shake", // SOUND_LIB + "224V1679_c.wav", // 
     "good banda!",		  // SOUND_LIB + "224V1762_c.wav", // 
     "fast polka banda",	  // SOUND_LIB + "224V2276_c.wav", // 
     "remote banda, fireworks",	  // SOUND_LIB + "224V2363_c.wav", // 
     "pipe organ",		  // SOUND_LIB + "224V2557_c.wav", // 
     "finches (budgies?)",	  // SOUND_LIB + "224V3857_c.wav", // 
     "horn and morning dove",	  // SOUND_LIB + "224V3865_c.wav", // 
     "church bells",		  // SOUND_LIB + "224V4467_c.wav", // 
     "street accordian and voices", // SOUND_LIB + "224V4899_c.wav", // 
     "hurdy gurdy I",		  // SOUND_LIB + "224V4912_c.wav", // 
     "street voices, laughing",	  // SOUND_LIB + "224V4959_c.wav", // 
     "hurdy gurdy II",		  // SOUND_LIB + "224V4963_c.wav", // 
     "accordian, clap dance",	  // SOUND_LIB + "224V5006_c.wav", // 
     "crowd noise, laughter",	  // SOUND_LIB + "224V5020_c.wav", // 
     "opera, soprani",		  // SOUND_LIB + "224V5052_c.wav", // 
     "opera, both",		  // SOUND_LIB + "224V5061_c.wav", // 
     "applause",		  // SOUND_LIB + "224V5064_c.wav", // 
     "inaudible choir",		  // SOUND_LIB + "224V5435_c.wav", // 
     "street morocco - percussive", // SOUND_LIB + "224V5738_c.wav", // 
     "street morocco - hawkers",  // SOUND_LIB + "224V6017_c.wav", // 
     "minaret",			  // SOUND_LIB + "224V6752_c.wav", // 
     "horsehoofs and barbara",	  // SOUND_LIB + "224V6801_c.wav", // 
     "fast drumming fez"	  // SOUND_LIB + "224V7013_c.wav"  // 
      ] @=> string _sound_names[];

    // ================================================================
    // controls specific to PipesPatch

    // initialize a voice with both individual params (midikey) and
    // global params (pitchbend, etc...)
    fun void init_voice(PipesVox voice, int midikey) {
	voice.set_pitch(midikey);
	voice.set_pitchbend(_pitchbend);
	voice.set_resonance(_resonance);
	voice.set_sound_source(_sound_source);
    }

    // set the pitchbend in all active voices
    fun void set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	_vox_controller.get_voices().apply(PITCHBEND.set_value(_pitchbend));
    }
    // set the resonance in all active voices
    fun void set_resonance(float resonance) {
	resonance => _resonance;
	_vox_controller.get_voices().apply(RESONANCE.set_value(_resonance));
    }	
    // set the sound source in all active voices
    fun void set_sound_source(SndBuf src) {
	if (_sound_source != null) { _sound_source =< blackhole; }
	src @=> _sound_source;
	if (_sound_source != null) { 
	    _sound_source => blackhole; 
	    _sound_source.loop(true);
	}
	set_playback_rate(_playback_rate);
	_vox_controller.get_voices().apply(SOUND_SOURCE, _sound_source);
    }	
    // set the playback rate of the sound source
    fun void set_playback_rate(float playback_rate) {
	playback_rate => _playback_rate;
	if (_sound_source != null) {
	    _sound_source.rate(_playback_rate);
	}
    }

    // ================================================================
    // subclassing Patch

    fun string get_name() { return "PipesPatch"; }

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
	    _vox_controller.note_on(midikey) $ PipesVox @=> PipesVox @ voice;
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
	set_resonance(Math.max(1.0, v*128.0));
    }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) {
	msg.get_value() => float v;
	(v * _sound_files.size()) $ int => int index;
	if ((index < _sound_files.size()) && (_sound_files[index] != _sound_file)) {
	    <<< "Now playing", _sound_names[index] >>>;
	    _sound_files[index] @=> _sound_file;
	    _sound_source.read(_sound_file);
	    set_sound_source(_sound_source);
	}
    }
    fun void handle_knob_06(ChannelEvt msg) {
	msg.get_value() => float v;
	set_playback_rate(Math.pow(2.0, (v-0.5) * 4.0));
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

// initialize the statics
(new PitchbendOp) @=> PipesPatch.PITCHBEND;
(new ResonanceOp) @=> PipesPatch.RESONANCE;
(new SoundSourceOp) @=> PipesPatch.SOUND_SOURCE;

// register the patch
PatchManager.register_patch(new PipesPatch);
