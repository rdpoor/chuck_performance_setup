// 100109_125100: Moved static initializers to end of file


class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class LoopTimingEvent extends Object{}

public class FarfisaVox extends Vox {

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

    BeeThree _vox1;
    BeeThree _vox2;
    float _pitch;
    float _pitchbend;
    float _frequency_spread;

    Semaphore _semaphore;

    // ================================================================
    // controls specific to this voice

    fun FarfisaVox set_aftertouch(float v) {
	_vox1.afterTouch(v);
	_vox2.afterTouch(v);
	return this;
    }

    fun FarfisaVox set_pitch(float pitch) { 
	pitch => _pitch;
	return _update_freq();
    }

    fun FarfisaVox set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	return _update_freq();
    }

    fun FarfisaVox set_frequency_spread(float v) {
	v => _frequency_spread;
	return _update_freq();
    }

    fun FarfisaVox set_modulation_depth(float depth) {
	_vox1.lfoDepth(depth);
	_vox2.lfoDepth(depth);
	return this;
    }

    fun FarfisaVox set_modulation_speed(float hz) {
	_vox1.lfoSpeed(hz);
	_vox2.lfoSpeed(hz+0.1);
	return this;
    }

    fun FarfisaVox set_drawbar1(float v) {
	_vox1.controlChange(2, v);
	_vox2.controlChange(2, v);
	return this;
    }

    fun FarfisaVox set_drawbar2(float v) {
	_vox1.controlChange(4, v);
	_vox2.controlChange(4, v);
	return this;
    }

    // ================================================================
    // subclassing Vox

    // one-time initialization
    fun Vox init() { 
	set_aftertouch(0.0);
	set_pitch(40);
	set_frequency_spread(0.0);
	set_modulation_depth(0.0);
	set_modulation_speed(0.0);
	set_drawbar1(0.0);
	set_drawbar2(0.0);
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
	_vox1 => AudioIO.output_bus();
	_vox2 => AudioIO.output_bus();
	return this; 
    }

    // called when note has finished.
    fun Vox note_ended() { 
	_vox1 =< AudioIO.output_bus();
	_vox2 =< AudioIO.output_bus();
	return this; 
    }

    // called repeatedly until it returns null
    fun Vox note_proc() { 
	_semaphore.wait() @=> Object cause;
	if (cause == NOTE_SILENCE_REQ) {
	    return null;

	} else if (cause == NOTE_ENDED) {
	    return null;

	} else if (cause == NOTE_ON_REQ) {
	    _vox1.noteOn(0.8);
	    _vox2.noteOn(0.8);
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    _vox1.noteOff(0.0);
	    _vox2.noteOff(0.0);
	    _semaphore.set_timeout(ENVELOPE_DURATION, NOTE_ENDED);
	    return this;

	} else {
	    <<< now, me, this.toString(), ".note_proc(): unknown cause", cause >>>;
	    return this;

	}
    }

    // ================================================================
    // private methods

    fun FarfisaVox _update_freq() {
	Std.mtof(_pitch + _pitchbend) => float freq;
	_vox1.freq(freq * (1 + _frequency_spread));
	_vox2.freq(freq * (1 - _frequency_spread));
	return this;
    }

    // signal the player proc
    fun FarfisaVox _signal(Object cause) { _semaphore.signal(cause); return this; }

}

// load-time initialization
(new NoteOnReq) @=> FarfisaVox.NOTE_ON_REQ;
(new NoteOffReq) @=> FarfisaVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> FarfisaVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> FarfisaVox.NOTE_ENDED;
(new LoopTimingEvent) @=> FarfisaVox.LOOP_TIMING_EVENT;
