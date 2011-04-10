// FishVox: fishy voices
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100318_221440: initial version
// ====

class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}

public class FishVox extends Vox {
    // ================================================================
    // class constants

    5::ms => static dur ENVELOPE_DURATION;
    static NoteOnReq @ NOTE_ON_REQ; 
    static NoteOffReq @ NOTE_OFF_REQ; 
    static NoteSilenceReq @ NOTE_SILENCE_REQ; 
    static NoteEnded @ NOTE_ENDED; 

    // ================================================================
    // instance variables
    
    SndBuf _sndbuf;		// sample being played
    string _sound_file;		// name of backing sample data

    Envelope _envelope;		// click avoidance
    float _playback_rate;	// 1.0 = normal, 2.0 = up one octave
    int _is_looping;		// repeating sample?

    Semaphore _semaphore;	// waits for timeout or signal

    // ================================================================
    // controls specific to this voice

    fun void load_sample_data(string filename) { 
	if (filename != _sound_file) {
	    filename => _sound_file;
	    _sndbuf.read(_sound_file); 
	}
    }

    fun float get_playback_rate() { return _playback_rate; }
    fun FishVox set_playback_rate(float playback_rate) {
	playback_rate => _playback_rate;
	_sndbuf.rate(_playback_rate);
	return this;
    }

    fun int is_looping() { return _is_looping; }
    fun FishVox set_looping(int looping) {
	looping => _is_looping;
	_sndbuf.loop(_is_looping);
    }

    fun float get_playback_pitch() { 
	return Math.log2(get_playback_rate()) * 12.0; 
    }
    fun FishVox set_playback_pitch(float semitones) {
	return set_playback_rate(Math.pow(2.0, semitones/12.0));
    }

    // ================================================================
    // Subclasssed from Vox

    fun Vox init() { 
	set_playback_rate(get_playback_rate());
	set_looping(is_looping());
	_envelope.duration(ENVELOPE_DURATION);
	return this; 
    }

    // called when a note on requested.
    fun Vox request_note_on() { return _signal(NOTE_ON_REQ); }

    // called when a note off requested.
    fun Vox request_note_off() { return _signal(NOTE_OFF_REQ); }

    // called when a note silence requested.
    fun Vox request_note_silence() { return _signal(NOTE_SILENCE_REQ); }

    // called before the note starts sounding.
    fun Vox note_started() { 
	_sndbuf.pos(0);
	_sndbuf => _envelope => AudioIO.output_bus();
	return this; 
    }

    // called after the note has finished sounding.
    fun Vox note_ended() { 
	_sndbuf =< _envelope =< AudioIO.output_bus();
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
	    _envelope.keyOn();
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    _envelope.keyOff();
	    _semaphore.set_timeout(ENVELOPE_DURATION, NOTE_ENDED);
	    return this;

	} else {
	    <<< "Unknown semaphore event:", cause, "...stopping note." >>>;
	    return null;
	}
    }

    // ================================================================
    // private methods

    fun FishVox _signal(Object cause) {
	_semaphore.signal(cause);
	return this;
    }

}

// load-time initialization
(new NoteOnReq) @=> FishVox.NOTE_ON_REQ;
(new NoteOffReq) @=> FishVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> FishVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> FishVox.NOTE_ENDED;
