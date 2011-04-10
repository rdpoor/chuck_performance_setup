// 100109_125100: Moved static initializers to end of file

class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class LoopTimingEvent extends Object{}

public class PipesVox extends Vox {

    // ================================================================
    // class constants

    50::ms => static dur ENVELOPE_DURATION;
    static NoteOnReq @ NOTE_ON_REQ; 
    static NoteOffReq @ NOTE_OFF_REQ; 
    static NoteSilenceReq @ NOTE_SILENCE_REQ; 
    static NoteEnded @ NOTE_ENDED; 
    static LoopTimingEvent @ LOOP_TIMING_EVENT; 

    // ================================================================
    // instance variables

    float _pitch;
    float _pitchbend;
    ResonZ _filter;
    Envelope _envelope;
    UGen @ _sound_source;	// sound source

    Semaphore _semaphore;

    // ================================================================
    // controls specific to this voice

    fun PipesVox set_pitch(float pitch) {
	pitch => _pitch;
	return _update_pitch();
    }

    fun PipesVox set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	return _update_pitch();
    }

    fun PipesVox set_resonance(float v) {
	_filter.Q(v);
	return this;
    }

    fun PipesVox set_sound_source(UGen sound_source) {
	// the actual patching happens in note_started() and note_ended()
	sound_source @=> _sound_source;
	return this;
    }

    // ================================================================
    // subclassing Vox

    // one-time initialization
    fun Vox init() { 
	_envelope.duration(ENVELOPE_DURATION);
	set_pitch(40);
	set_resonance(1.0);
	set_sound_source(null);
	return this; 
    }

    // called when a note on requested.
    fun Vox request_note_on() { return _signal(NOTE_ON_REQ); }

    // called when a note off requested.
    fun Vox request_note_off() { return _signal(NOTE_OFF_REQ); }

    // called when a note silence requested.
    fun Vox request_note_silence() { return _signal(NOTE_SILENCE_REQ); }

    // called when the note first starts.
    fun Vox note_started() { 
	_filter => _envelope => AudioIO.output_bus();
	if (_sound_source != null) _sound_source => _filter;
	return this; 
    }

    // called when note has finished.
    fun Vox note_ended() { 
	_filter =< _envelope =< AudioIO.output_bus();
	if (_sound_source != null) _sound_source =< _filter;
	return this; 
    }

    // called repeatedly until it returns null
    fun Vox note_proc() { 
	_semaphore.wait() @=> Object cause;
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
	    <<< now, me, this.toString(), ".note_proc(): unknown cause", cause >>>;
	    return this;

	}
    }

    // ================================================================
    // private methods

    // signal the player proc
    fun PipesVox _signal(Object cause) { _semaphore.signal(cause); return this; }

    fun PipesVox _update_pitch() {
	_filter.freq(Std.mtof(_pitch + _pitchbend));
	return this;
    }


}


// load-time initialization
(new NoteOnReq) @=> PipesVox.NOTE_ON_REQ;
(new NoteOffReq) @=> PipesVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> PipesVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> PipesVox.NOTE_ENDED;
(new LoopTimingEvent) @=> PipesVox.LOOP_TIMING_EVENT;