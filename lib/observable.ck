// Observable: a source of Msg objects via notify()
// 
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100117_043803: created
// ====

public class Observable {

    // ================================================================
    // Instance variables

    Msg @ _state;

    // ================================================================
    // Instance methods
    
    fun Msg get_state() { return _state; }

    // set state equal to msg and notify observers if there
    // was a change.
    fun Observable set_state(Msg msg) {	return set_state(msg, false); }
    fun Observable set_state(Msg msg, int force_notify) {
	Util.trace(this, "set_state()[1]");
	false => int need_notify;
	if (force_notify) {
	    Util.trace(this, "set_state()[2]");
	    true => need_notify;
	} else if (msg == null) {
	    Util.trace(this, "set_state()[3]");
	    (_state != null) => need_notify;
	} else if (_state == null) {
	    Util.trace(this, "set_state()[4]");
	    (msg != null) => need_notify;
	} else {
	    Util.trace(this, "set_state()[5]");
	    !msg.equals(_state) => need_notify;
	}
	msg @=> _state;
	if (need_notify) {
	    Util.trace(this, "set_state()[6]");
	    notify(_state);
	    Util.trace(this, "set_state()[7]");
	    return this;
	} else {
	    Util.trace(this, "set_state()[8]");
	    return null;
	}
    }

    fun Observable notify() { 
	if (_state != null) notify(_state);
	return this;
    }

    // to be subclassed
    fun Observable notify(Msg msg) { return this; }
}
