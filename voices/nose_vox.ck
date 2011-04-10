// NoseVox: Three formants filter a single band-limited pulse wave.
//
// Note that the functions set_formant{1,2,3}() set_resonance() are
// normalized -- the argument should be between 0.0 and 1.0.

class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class LoopTimingEvent extends Object{}

public class NoseVox extends Vox {

    // ================================================================
    // class constants

    0.0 => static float F1_GAIN_DB;
    270.0 => static float F1_MIN_FREQ;
    770.0 => static float F1_MAX_FREQ;
    1.0 => static float F1_MIN_Q;
    20.0 => static float F1_MAX_Q;

    -0.0 => static float F2_GAIN_DB;
    890.0 => static float F2_MIN_FREQ;
    2100.0 => static float F2_MAX_FREQ;
    1.0 => static float F2_MIN_Q;
    20.0 => static float F2_MAX_Q;

    -0.0 => static float F3_GAIN_DB;
    1440.0 => static float F3_MIN_FREQ;
    2800.0 => static float F3_MAX_FREQ;
    1.0 => static float F3_MIN_Q;
    20.0 => static float F3_MAX_Q;

    second / samp => static float SRATE;

    50::ms => static dur ENVELOPE_DURATION;
    // the following constants are initialized at the end of this file...
    static NoteOnReq @ NOTE_ON_REQ;
    static NoteOffReq @ NOTE_OFF_REQ;
    static NoteSilenceReq @ NOTE_SILENCE_REQ;
    static NoteEnded @ NOTE_ENDED;
    static LoopTimingEvent @ LOOP_TIMING_EVENT;

    // ================================================================
    // instance variables

    float _pitch;		// central pitch
    float _pitchbend;		// deviation from pitch
    Blit _excite;		// excitation function
    ResonZ _formfilt1;		// formant filter 1
    ResonZ _formfilt2;		// formant filter 2
    // ResonZ _formfilt3;	// formant filter 3
    Envelope _envelope;

    Semaphore _semaphore;


    // ================================================================
    // controls specific to this voice

    fun NoseVox set_gain(float gain) {
	_envelope.gain(gain);
	return this;
    }

    fun NoseVox set_pitch(float pitch) {
	pitch => _pitch;
	return _update_pitch();
    }

    fun NoseVox set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	return _update_pitch();
    }

    fun NoseVox set_formant1(float v) {
	_formfilt1.freq(Util.lerp(v, F1_MIN_FREQ, F1_MAX_FREQ));
	return this;
    }

    fun NoseVox set_formant2(float v) {
	_formfilt2.freq(Util.lerp(v, F2_MIN_FREQ, F2_MAX_FREQ));
	return this;
    }

    // currently a no-op
    fun NoseVox set_formant3(float v) {
	// 	_formfilt3.freq(Util.lerp(v, F3_MIN_FREQ, F3_MAX_FREQ));
	return this;
    }

    fun NoseVox set_resonance(float v) {
	_formfilt1.Q(Util.lerp(v, F1_MIN_Q, F1_MAX_Q));
	_formfilt2.Q(Util.lerp(v, F2_MIN_Q, F2_MAX_Q));
	//	_formfilt3.Q(Util.lerp(v, F3_MIN_Q, F3_MAX_Q));
	return this;
    }


    // ================================================================
    // subclassing Vox

    // one-time initialization
    fun Vox init() { 
	_excite.gain(0.7);
	_excite.harmonics(20);	// should this be changed when pitch changes?
	_formfilt1.gain(Util.db_to_ratio(F1_GAIN_DB));
	_formfilt2.gain(Util.db_to_ratio(F2_GAIN_DB));
	//	_formfilt3.gain(Util.db_to_ratio(F3_GAIN_DB));
	_envelope.duration(ENVELOPE_DURATION);
	set_gain(1.0);
	set_pitch(40);
	set_pitchbend(0.0);
	set_formant1(0.5);
	set_formant2(0.5);
	set_formant3(0.5);
	set_resonance(0.5);
	// pre-patch -- only envelope needs to be connected to complete the graph
	// _excite => _formfilt1 => _formfilt2 => _formfilt3 => _envelope;
	_excite => _formfilt1 => _envelope;
	_excite => _formfilt2 => _envelope;
	// _excite => _formfilt3 => _envelope;
	return this; 
    }

    // called when a note on requested.
    fun Vox request_note_on() { return _signal(NOTE_ON_REQ); }

    // called when a note off requested.
    fun Vox request_note_off() { return _signal(NOTE_OFF_REQ); }

    // called when a note silence requested.
    fun Vox request_note_silence() { return _signal(NOTE_SILENCE_REQ); }

    // called when the note first starts.
    fun Vox note_started() { _envelope => AudioIO.output_bus(); return this; }

    // called when note has finished.
    fun Vox note_ended() { _envelope =< AudioIO.output_bus(); return this; }

    // note_proc() is called repeatedly until it returns null
    fun Vox note_proc() { 
	_semaphore.wait() @=> Object cause; // wait for signal or timeout

	if (cause == NOTE_SILENCE_REQ) {
	    return null;

	} else if (cause == NOTE_ON_REQ) {
	    _envelope.keyOn();
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    _envelope.keyOff();
	    _semaphore.set_timeout(ENVELOPE_DURATION, NOTE_ENDED);
	    return this;

	} else if (cause == NOTE_ENDED) {
	    return null;

	} else {
	    <<< now, me, this.toString(), ".note_proc(): unknown cause", 
		(cause==null)?"null":cause.toString() >>>;
	    return this;

	}
    }

    // ================================================================
    // private methods

    // signal the note_proc()
    fun NoseVox _signal(Object cause) { _semaphore.signal(cause); return this; }

    fun NoseVox _update_pitch() {
	Std.mtof(_pitch + _pitchbend) => float freq;
	_excite.freq(freq);
	// set highest harmonic = F2_MAX_FREQ * 4
	(F2_MAX_FREQ * 4.0 / freq) $ int => int nharm;
	_excite.harmonics((nharm<1)?1:nharm);
	return this;
    }

}

// One-time initialization
(new NoteOnReq) @=> NoseVox.NOTE_ON_REQ;
(new NoteOffReq) @=> NoseVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> NoseVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> NoseVox.NOTE_ENDED;
(new LoopTimingEvent) @=> NoseVox.LOOP_TIMING_EVENT;
