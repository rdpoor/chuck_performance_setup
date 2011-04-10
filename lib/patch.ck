// Patch: Generic patch class.
//
// Working in conjunction with the PatchManager, the Patch class
// starts and stops an individual patch and provides some generic
// methods for MIDI control.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class Patch extends StdControlsObserver {

    // ================================================================
    // instance variables

    StdControls @ _std_controls;

    // ================================================================
    // private methods

    fun StdControls _get_std_controls() {
	if (_std_controls == null) {
	    (new StdControls).init(this) @=> _std_controls;
	}
	return _std_controls;
    }

    // ================================================================
    // public methods

    // set up to receive handle_xxx(ChannelMessage msg) messages
    fun Patch attach_std_controls() { 
	if (Util.is_tracing()) Util.trace(this, ".attach_std_controls[1]()");
	_get_std_controls().attach(); 
	if (Util.is_tracing()) Util.trace(this, ".attach_std_controls[2]()");
	return this; 
    }


    // stop receiving handle_xxx(ChannelMessage msg) messages
    fun Patch detach_std_controls() { _get_std_controls().detach(); return this; }


    // ask each std control to re-issue an update() ChannelMessage
    // with its previously stored value
    fun Patch resend_std_controls() { 
	_get_std_controls().resend(); 
	return this; 
    }

    // ================================================================
    // methods to be subclassed

    fun string get_name() { return "Generic Patch"; }
    fun Patch init() { return this; }  // one-time initialization
    fun Patch start() { return this; } // allocate resources and begin
    fun Patch stop() { return this; }  // silence and release resources

}
