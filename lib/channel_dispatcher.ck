// ChannelDispatcher: a Dispatcher with built-in ChannelEvt.
//
// A ChannelDispatcher is a Dispatcher with its own ChannelEvt.
// Calling set_state() automagically causes the ChannelEvt to
// be forwarded.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class ChannelDispatcher extends Dispatcher {

    int _channel;

    fun int get_channel() { return _channel; }
    fun ChannelDispatcher set_channel(int channel) { 
	channel => _channel; 
	return this; 
    }

    // get the most recently set value
    fun float get_value() {
	(get_state() $ ChannelEvt) @=> ChannelEvt @ prev;
	return (prev == null)?0.0:prev.get_value();
    }

    // set the value of the contained ChannelEvt and broadcast the new
    // ChannelEvt to all attached Observers
    fun ChannelDispatcher set_value(float value) {
	Util.trace(this, "set_value()[1]");
	(get_state() $ ChannelEvt) @=> ChannelEvt @ prev;
	set_state(ChannelEvt.create(_channel, value, now, prev));
	Util.trace(this, "set_value()[2]");
    }

}
