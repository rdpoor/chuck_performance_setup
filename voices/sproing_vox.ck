// SproingVox: A plucked voice with a pitch twang at the beginning
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100109_163759: Initial Version
// 100110_015153: Removed Clarinet -- didn't start reliably
// ====

class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class SproingUpdate extends Object{}

public class SproingVox extends Vox {
    // ================================================================
    // class constants

    25::ms => dur UPDATE_INTERVAL;

    // the following constants are initialized at the end of this file...
    static NoteOnReq @ NOTE_ON_REQ;
    static NoteOffReq @ NOTE_OFF_REQ;
    static NoteSilenceReq @ NOTE_SILENCE_REQ;
    static NoteEnded @ NOTE_ENDED;
    static SproingUpdate @ SPROING_UPDATE;

    // ================================================================
    // instance variables

    float _gain;
    float _pitch;		// central pitch
    float _pitchbend;		// deviation from pitch

    // At each attack, the pitch oscillates (once) around the central
    // pitch: it first rises up to _pitch + _sproing_depth, then 
    // passes through _pitch at start + sproing_dur before passing
    // through _pitch - _sproing_depth.  It slowly rises back up
    // to _pitch.
    //
    // The underlying sproing pitch function is:
    //  p(t) = _pitch + _depth * sin(4*arctan(_dur * (start-t)))

    float _sproing_depth;    // in semitones
    dur _sproing_dur;	     // time at which it passes through _pitch

    time _note_on_time;	      // time at which note started
    float _pitch_deviation;   // computed pitch deviation in semitones

    Mandolin _mandolin;
    PercFlut _flute;

    Semaphore _semaphore;

    // ================================================================
    // controls specific to this voice

    fun SproingVox init_all(float pitch,
			    float gain,
			    float pitchbend,
			    float sproing_depth,
			    dur sproing_dur) {
	set_pitch(pitch);
	set_gain(gain);
	set_pitchbend(pitchbend);
	set_sproing_depth(sproing_depth);
	set_sproing_dur(sproing_dur);
	return this;
    }

    fun SproingVox set_gain(float gain) {
	gain => _gain;
	return this;
    }

    fun SproingVox set_pitch(float pitch) {
	pitch => _pitch;
	return _update_pitch();
    }

    fun SproingVox set_pitchbend(float pitchbend) {
	pitchbend => _pitchbend;
	return _update_pitch();
    }

    fun SproingVox set_sproing_depth(float depth) {
	depth => _sproing_depth;
	return this;
    }

    fun SproingVox set_sproing_dur(dur duration) {
	duration => _sproing_dur;
	return this;
    }

    // ================================================================
    // subclassing Vox

    // one-time initialization
    fun Vox init() { 
	return init_all(42, 1.0, 0.0, 0.0, 0::second);
    }

    // called when a note on requested.
    fun Vox request_note_on() { return _signal(NOTE_ON_REQ); }

    // called when a note off requested.
    fun Vox request_note_off() { return _signal(NOTE_OFF_REQ); }

    // called when a note silence requested.
    fun Vox request_note_silence() { return _signal(NOTE_SILENCE_REQ); }

    // called when the note first starts.
    fun Vox note_started() { 
	_mandolin => AudioIO.output_bus(); 
	_flute => AudioIO.output_bus(); 
	return this; 
    }

    // called when note has completely finished.
    fun Vox note_ended() { 
	_flute =< AudioIO.output_bus(); 
	_mandolin =< AudioIO.output_bus(); 
	return this; 
    }

    // note_proc() is called repeatedly until it returns null
    fun Vox note_proc() { 
	_semaphore.wait() @=> Object cause; // wait for signal or timeout

	if (cause == NOTE_SILENCE_REQ) {
	    return null;

	} else if (cause == NOTE_ON_REQ) {
	    _mandolin.pluck(_gain);
	    _flute.noteOn(_gain);
	    // capture note on time
	    now => _note_on_time;
	    _sproing_update();
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    _mandolin.noteOff(0.0);
	    _flute.noteOff(0.0);
	    _semaphore.set_timeout(50::ms, NOTE_ENDED);
	    return this;

	} else if (cause == NOTE_ENDED) {
	    return null;

	} else if (cause == SPROING_UPDATE) {
	    _sproing_update();
	    return this;

	} else {
	    <<< now, me, this.toString(), ".note_proc(): unknown cause", 
		(cause==null)?"null":cause.toString() >>>;
	    return this;

	}
    }


    // ================================================================
    // private methods

    // signal the note_proc() with the given cause
    fun SproingVox _signal(Object cause) { 
	_semaphore.signal(cause); 
	return this; 
    }

    // update pitch from _pitch and _pitchbend
    fun SproingVox _update_pitch() {
	Std.mtof(_pitch + _pitchbend) => float m_freq;
	// I have no idea why PercFlut sounds a perfect fifth above
	// pitch, but we correct for it here.  With deviation...
	Std.mtof(_pitch + _pitchbend + _pitch_deviation - 7.0) => float f_freq;
	_mandolin.freq(m_freq);
	_flute.freq(f_freq);
	return this;
    }

    // update _pitch_deviation every UPDATE_INTERVAL
    fun SproingVox _sproing_update() {
	if ((_sproing_depth == 0.0) || (_sproing_dur == 0::second)) {
	    0.0 => _pitch_deviation;
	} else {
	    sproing_fn(now - _note_on_time) => _pitch_deviation;
	    // set semaphore to fire again in UPDATE_INTERVAL
	    Semaphore.truncate_time(now + UPDATE_INTERVAL) => time next_update;
	    _semaphore.set_timeout(next_update, SPROING_UPDATE);
	}
	_update_pitch();
	return this;
    }

    // return the pitch deviation (in semitones) as a function of time
    // since note started
    fun float sproing_fn(dur dt) {
	// as dt goes from 0.._sproing_dur, x goes from 0..1.0
	Util.lerp(dt, 0::second, _sproing_dur, 0.0, 1.0) => float x;
	return _sproing_depth * Math.sin(4.0 * Math.atan(x));
    }

}

(new NoteOnReq) @=> SproingVox.NOTE_ON_REQ;
(new NoteOffReq) @=> SproingVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> SproingVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> SproingVox.NOTE_ENDED;
(new SproingUpdate) @=> SproingVox.SPROING_UPDATE;
