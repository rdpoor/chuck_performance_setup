// AudioIO: standard setup for audio input and output.
//
// AudioIO provides an audio bus into which to patch samples and some
// standard processing for the samples: compression, reverb, echo,
// gain and pan.
//
// Convention: methods prefixed with an '_' are considered internal
// (private) to this class.  Only methods without an underscore prefix
// should be called outside of this file.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class AudioIO {

    // ================================================================
    // singleton instance

    static AudioIO @ _audio_io;

    fun static AudioIO audio_io() {
	Util.trace("AudioIO", "audio_io(1)");
	if (_audio_io == null) {
	    Util.trace("AudioIO", "audio_io(2)");
	    new AudioIO @=> _audio_io;
	}
	Util.trace("AudioIO", "audio_io(3)");
	return _audio_io;
    }

    fun static UGen output_bus() {
	return AudioIO.audio_io().get_output_bus();
    }

    // ================================================================
    // instance variables

    Gain @ _ug_gain;
    Dyno @ _ug_dyno;
    NRev @ _ug_nrev;
    Echo @ _ug_echo;
    Pan2 @ _ug_pan;
    
    // one-time initialization: allocate the unit generators and patch
    // them together
    //
    fun AudioIO init() {
	new Gain @=> _ug_gain;
	new NRev @=> _ug_nrev;
	new Dyno @=> _ug_dyno;
	_ug_dyno.compress();
	_ug_dyno.releaseTime(500::ms);
	_ug_dyno.thresh(0.25);	   // compressor threshold -6db
	_ug_dyno.slopeAbove(0.2);  // nearly limiting
	_ug_dyno.gain(2.0);	   // make-up gain
	new Echo @=> _ug_echo;
	new Pan2 @=> _ug_pan;

	// This defines the output audio processing chain.  Note that
	// you can crank up the pre_gain to hit the compressor harder
	// if you want a more squashed sound.
	_ug_gain => _ug_nrev => _ug_dyno => _ug_echo => _ug_pan => dac;

	reset();		// reset adjustable parameters to defaults

	return this;
    }

    fun void reset() {
	set_pre_gain(1.0);
	set_reverb_mix(0.0);
	set_echo_mix(0.0);
	set_echo_delay(0.0);
	set_post_gain(1.0);
	dac.gain(1.0);
    }

    // _ug_gain happens to be the first in the audio chain.  use its
    // input to feed the output stage.
    fun UGen get_output_bus() { return _ug_gain; }

    // ================================================================
    // following are the public controls for the output stage

    // emergency silence
    fun void silence() { set_post_gain(0.0); }
	
    // gain before the reverb and compressor
    fun float get_pre_gain() { return _ug_gain.gain(); }
    fun void set_pre_gain(float gain) { _ug_gain.gain(gain); }

    // reverb
    fun float get_reverb_mix() { return _ug_nrev.mix(); }
    fun void set_reverb_mix(float mix) { _ug_nrev.mix(mix); }

    // delay
    fun float get_echo_mix() { return _ug_echo.mix(); }
    fun void set_echo_mix(float mix) { 
	<<< "AudioIO.set_echo_mix(", mix, ")" >>>;
	_ug_echo.mix(mix); 
    }

    // delay ranges from 0 (no delay) to 1.0 (max delay or 4096 samples?)
    fun float get_echo_delay() { return (_ug_echo.delay() * 1.0 / _ug_echo.max()); }
    fun void set_echo_delay(float delay) { _ug_echo.delay(delay * _ug_echo.max()); }

    // post gain isn't gain at all: it sets the pan between "house" (1.0)
    // and "audition" (0.0).
    fun float get_post_gain() { return (_ug_pan.pan() * 0.5) + 0.5; }
    fun void set_post_gain(float gain) { _ug_pan.pan((gain * 2.0) - 1.0); }

    // play a one-second tone to test the audio connection
    fun void boop() {
	Util.trace(this, "boop(00)");
	get_post_gain() => float saved_gain;
	set_post_gain(0.2);
	SinOsc s1 => dac;
	s1.freq(440.0);
	1.0::second => now;
	s1 =< dac;
	set_post_gain(saved_gain);
	Util.trace(this, "boop(01)");
    }

}
