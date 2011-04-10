// Vox: template for general noise-making
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class Vox {
    
    int _tag;
    true => int _is_idle;

    fun int get_tag() { return _tag; }
    fun int is_idle() { return _is_idle; }
    fun int is_active() { return !_is_idle; }

    // ================================================================
    // Methods to be subclassed

    // one-time initialization
    fun Vox init() { return this; } 

    // called when a note on requested.
    fun Vox request_note_on() { return this; }

    // called when a note off requested.
    fun Vox request_note_off() { return this; }

    // called when a note silence requested.
    fun Vox request_note_silence() { return this; }

    // called when the note first starts.
    fun Vox note_started() { return this; }

    // called when note has finished.
    fun Vox note_ended() { return this; }

    // called repeatedly until it returns null
    fun Vox note_proc() { return null; }

    // ================================================================
    // public methods.

    fun Vox start(int tag) {
	if (Util.is_tracing()) Util.trace(this, ".start[1](" + tag + ")");
	tag => _tag;
	if (is_idle()) {
	    if (Util.is_tracing()) Util.trace(this, ".start[2](" + tag + ")");
	    spork ~ _player_proc();
	    me.yield();
	}
	return request_note_on();
    }

    fun Vox stop() {
	return is_idle()?this:request_note_off();
    }

    fun Vox silence() {
	return is_idle()?this:request_note_silence();
    }

    // ================================================================
    // private methods.

    // player_proc() is the thread in which all sound production happens.
    fun void _player_proc() {
	if (Util.is_tracing()) Util.trace(this, "._player_proc()");
	false => _is_idle;
	note_started();
	while (note_proc() != null) {
	}
	note_ended();
	true => _is_idle;
    }

}
