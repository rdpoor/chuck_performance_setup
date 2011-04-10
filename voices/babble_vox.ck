// 100109_125100: Moved static initializers to end of file


class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class LoopTimingEvent extends Object{}

public class BabbleVox extends Vox {

    // ================================================================
    // class constants

    5::ms => static dur ENVELOPE_DURATION;
    static NoteOnReq @ NOTE_ON_REQ; 
    static NoteOffReq @ NOTE_OFF_REQ; 
    static NoteSilenceReq @ NOTE_SILENCE_REQ; 
    static NoteEnded @ NOTE_ENDED; 
    static LoopTimingEvent @ LOOP_TIMING_EVENT; 

    // ================================================================
    // instance variables

    FMVoices _vox;
    float _pitch;
    float _pitchbend;
    dur _babble_delay;
    float _phoneme_span;
    Semaphore _semaphore;
    Shred @ _phoneme_handle;

    // ================================================================
    // controls specific to this voice

    fun float get_pitch() { return _pitch; }
    fun BabbleVox set_pitch(float pitch) { 
	pitch => _pitch;
	return _update_pitch();
    }

    fun BabbleVox set_pitchbend(float pitchbend) {
	Util.trace(this, ".set_pitchbend(" + pitchbend + ")");
	pitchbend => _pitchbend;
	return _update_pitch();
    }

    fun BabbleVox set_babble_rate(float hz) {
	Util.trace(this, ".set_babble_rate(" + hz + ")");
	1::second / hz => _babble_delay;
	return this;
    }

    // 0 = limit set_phoneme() to 1st phoneme, 1.0 = unlimited
    fun BabbleVox set_phoneme_span(float span) {
	span => _phoneme_span;
	return this;
    }

    // 0 = all harmonics, 1.0 increases fundamental
    fun BabbleVox set_fundamental_mix(float ctrl) {
	_vox.controlChange(2, ctrl * 128);
	return this;
    }

    // sets the phoneme (despite the name)
    fun BabbleVox set_phoneme(float ctrl) {
	(ctrl * _phoneme_span * 126) $ int => int val;
	_vox.controlChange(4, val);
	return this;
    }


    // ================================================================
    // subclassing Vox

    // one-time initialization
    fun Vox init() { 
	set_pitch(40);
	set_babble_rate(1.0);
	set_phoneme_span(1.0);
	set_fundamental_mix(1.0);
	set_phoneme(0.0);
	return this; 
    }

    // called when a note on requested.
    fun Vox request_note_on() { 
	Util.trace(this, "request_note_on[1]()");
	return _signal(NOTE_ON_REQ); 
    }

    // called when a note off requested.
    fun Vox request_note_off() { return _signal(NOTE_OFF_REQ); }

    // called when a note silence requested.
    fun Vox request_note_silence() { return _signal(NOTE_SILENCE_REQ); }

    // called when the note first starts.
    fun Vox note_started() { 
	Util.trace(this, "note_started[1]()");
	spork ~ _phoneme_proc() @=> _phoneme_handle; // start babbling
	_vox.freq(Std.mtof(get_pitch()));
	_vox => AudioIO.output_bus();
	return this; 
    }

    // called when note has finished.
    fun Vox note_ended() { 
	Util.trace(this, "note_ended[1]()");
	null @=> _phoneme_handle; // stop babbling
	_vox =< AudioIO.output_bus();
	return this; 
    }

    // called repeatedly until it returns null
    fun Vox note_proc() { 
	Util.trace(this, "note_proc[1]()");
	_semaphore.wait() @=> Object cause;
	if (cause == NOTE_SILENCE_REQ) {
	    return null;

	} else if (cause == NOTE_ENDED) {
	    return null;

	} else if (cause == NOTE_ON_REQ) {
	    _vox.noteOn(0.8);
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    _vox.noteOff(0.0);
	    _semaphore.set_timeout(ENVELOPE_DURATION, NOTE_ENDED);
	    return this;

	} else {
	    <<< now, me, this.toString(), ".note_proc(): unknown cause", cause >>>;
	    return this;

	}
    }

    // ================================================================
    // private methods

    fun BabbleVox _update_pitch() {
	_vox.freq(Std.mtof(_pitch + _pitchbend));
	return this;
    }
	
    // signal the player proc
    fun BabbleVox _signal(Object cause) { _semaphore.signal(cause); return this; }

    // shred that modifies phonemes
    fun void _phoneme_proc() {
	Util.trace(this, "_phoneme_proc[1]()");
	while (me == _phoneme_handle) {
	    Util.trace(this, "_phoneme_proc[2]()");
	    set_phoneme(Std.rand2f(0.0, 1.0));
	    // this could be better done with a semaphore: when the
	    // babble_delay changes (e.g. gets shorter) we may want to
	    // break out of the delay.
	    _babble_delay => now;
	}
	Util.trace(this, "_phoneme_proc[3]()");
    }

}

// load-time initialization
(new NoteOnReq) @=> BabbleVox.NOTE_ON_REQ;
(new NoteOffReq) @=> BabbleVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> BabbleVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> BabbleVox.NOTE_ENDED;
(new LoopTimingEvent) @=> BabbleVox.LOOP_TIMING_EVENT;
