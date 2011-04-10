// SloopVox: Sound Loop Vox
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_125100: Moved static initializers to end of file
// ====

class NoteOnReq extends Object{}
class NoteOffReq extends Object{}
class NoteSilenceReq extends Object{}
class NoteEnded extends Object{}
class LoopTimingEvent extends Object{}

public class SloopVox extends Vox {
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
    
    SndBuf _sndbuf;		// sample being played
    string _sound_file;		// name of backing sample data

    Envelope _envelope;		// click avoidance
    float _gain;		// gain
    float _initial_phase;	// starting point of each loop: 0..1
    dur _loop_duration;		// loop duration
    float _duty_cycle;		// ratio of sound/silence: 0..1
    float _playback_rate;	// 1.0 = normal, 2.0 = up one octave
    int _is_muted;		// true if in the silent part of loop

    Semaphore _semaphore;	// waits for timeout or signal
    time _loop_start_time;	// set to now at start of each loop

    // ================================================================
    // controls specific to this voice

    fun void load_sample_data(string filename) { 
	if (filename != _sound_file) {
	    filename => _sound_file;
	    _sndbuf.read(_sound_file); 
	}
    }

    fun float get_gain() { return _gain; }
    fun SloopVox set_gain(float gain) {
	gain => _gain;
	return _set_gain();
    }

    fun float get_initial_phase() { return _initial_phase; }
    fun SloopVox set_initial_phase(float initial_phase) {
	initial_phase => _initial_phase;
	return this;
    }

    fun dur get_loop_duration() { return _loop_duration; }
    fun SloopVox set_loop_duration(dur loop_duration) {
	loop_duration => _loop_duration;
	return _timing_changed();
    }

    fun float get_duty_cycle() { return _duty_cycle; }
    fun SloopVox set_duty_cycle(float duty_cycle) {
	duty_cycle => _duty_cycle;
	return _timing_changed();
    }

    fun float get_playback_rate() { return _playback_rate; }
    fun SloopVox set_playback_rate(float playback_rate) {
	playback_rate => _playback_rate;
	_sndbuf.rate(_playback_rate);
	return this;
    }

    fun float get_playback_pitch() { 
	return Math.log2(get_playback_rate()) * 12.0; 
    }
    fun SloopVox set_playback_pitch(float semitones) {
	return set_playback_rate(Math.pow(2.0, semitones/12.0));
    }

    fun int is_muted() { return _is_muted; }
    fun SloopVox set_muted(int is_muted) {
	is_muted => _is_muted;
	return _set_gain();
    }

    // ================================================================
    // Subclasssed from Vox

    fun Vox init() { 
	_sndbuf.loop(true);
	_envelope.duration(ENVELOPE_DURATION);
	set_loop_duration(1::second);
	set_duty_cycle(1.0);
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
	_sndbuf => _envelope => AudioIO.output_bus();
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
	    now => _loop_start_time; // note start time of loop
	    _process_loop_event();   // mute or unmute voice
	    return this;

	} else if (cause == NOTE_OFF_REQ) {
	    // NOTE: there's a small bug here: once a NOTE_OFF_REQ is
	    // processed, note_proc() stops looping the sample.  If
	    // ENVELOPE_DURATION is very short, this should be no
	    // problem.  But if it's long, you will hear the looping
	    // stop.  (Implmenting the state machine to do ramping AND
	    // keep looping is a bit more subtle than I want to tackle
	    // right now.)
	    _envelope.keyOff();
	    _semaphore.set_timeout(ENVELOPE_DURATION, NOTE_ENDED);
	    return this;

	} else if (cause == LOOP_TIMING_EVENT) {
	    _process_loop_event();
	    return this;

	}
    }

    // called when note has finished.
    fun Vox note_ended() { 
	_sndbuf =< _envelope =< AudioIO.output_bus();
	return this; 
    }

    // ================================================================
    // private methods

    // Called when either the gain changes or the muting changes:
    // update the sndbuf gain accordingly...
    fun SloopVox _set_gain() {
	_sndbuf.gain(is_muted()?0.0:get_gain());
	return this;
    }

    fun SloopVox _signal(Object cause) {
	_semaphore.signal(cause);
	return this;
    }

    // Called when some aspect of the timing (either loop duration
    // or duty cycle) changed.  Triggers the semaphore to request
    // re-evaluation of timing.
    fun SloopVox _timing_changed() { return _signal(LOOP_TIMING_EVENT); }

    // Arrive here:
    // - at the beginning of a loop (now == _loop_start_time)
    // - at the end of a loop (now == _loop_start_time + loop_duration)
    // - at the transition from playing to silence of the loop
    //   (now == _loop_start_time + loop_duration * duty_cycle)
    // - at any time when loop_duration or duty_cycle change
    //   (see set_loop_duration() and set_duty_cycle())
    // Mute or unmute voice and set the semaphore to wake up at the
    // next transition.  
    //
    // Note: if get_loop_duration() == 0, the playing process will
    // get stuck.  Should guard against that.
    //
    fun void _process_loop_event() {

	// wow -- truncate_time() makes all the difference.
	Semaphore.truncate_time(_loop_start_time + get_loop_duration()) => time t1;

	// the end of one loop is the start of another...
	if (now >= t1) {
	    now => _loop_start_time;
	}

	// if at the very start of the loop, re-set the phase of the sample
	if (now == _loop_start_time) {
	    _sndbuf.phase(get_initial_phase());
	}

	// compute time at which this loop goes mute and when it ends
	_loop_start_time + (get_loop_duration() * get_duty_cycle()) => time loop_mute_time;
	Semaphore.truncate_time(loop_mute_time) => loop_mute_time;

	_loop_start_time + get_loop_duration() => time loop_end_time;
	Semaphore.truncate_time(loop_end_time) => loop_end_time;

	if (now < loop_mute_time) {
	    // here during the "sounding" phase
	    set_muted(false);
	    _semaphore.set_timeout(loop_mute_time, LOOP_TIMING_EVENT);

	} else /* if (now < loop_end_time) */ {
	    // here during the "muted" phase
	    set_muted(true);
	    _semaphore.set_timeout(loop_end_time, LOOP_TIMING_EVENT);
	    
	}
    }

}

// load-time initialization
(new NoteOnReq) @=> SloopVox.NOTE_ON_REQ;
(new NoteOffReq) @=> SloopVox.NOTE_OFF_REQ;
(new NoteSilenceReq) @=> SloopVox.NOTE_SILENCE_REQ;
(new NoteEnded) @=> SloopVox.NOTE_ENDED;
(new LoopTimingEvent) @=> SloopVox.LOOP_TIMING_EVENT;
