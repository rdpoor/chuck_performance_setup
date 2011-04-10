// ChannelEvt: general purpose Evt with a channel and a value
//
// ChannelEvt carries an integer channel number, a floating point
// value and a time.  For convenience, it also carries the previous
// value and the previous time, as well as change in value per unit
// time.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

public class ChannelEvt extends Evt {

    int _channel;
    float _value;
    float _prev_value;
    time _prev_time;

    fun static ChannelEvt create(int channel, float value, time t, ChannelEvt prev) {
	new ChannelEvt @=> ChannelEvt @ n;
	channel => n._channel;
	value => n._value;
	t => n._time;
	if (prev == null) {
	    0.0 => n._prev_value;
	    Util.TIME_ZERO => n._prev_time;
	} else {
	    prev._value => n._prev_value;
	    prev._time => n._prev_time;
	}
	return n;
    }

    fun Msg clone() {
	new ChannelEvt @=> ChannelEvt @ n;
	_channel => n._channel;
	_value => n._value;
	_prev_value => n._prev_value;
	_time => n._time;
	_prev_time => n._prev_time;
	return n;
    }

    fun int equals(Msg other) {
	(other $ ChannelEvt) @=> ChannelEvt @ o;
	if (o == null) {
	    return false;
	} else if (this._time != o._time) {
	    return false;
	} else if (this._channel != o._channel) {
	    return false;
	} else if (this._value != o._value) {
	    return false;
	}
	return true;
    }

    fun ChannelEvt set_value(float value) {
	return set_state(_channel, value, now);
    }

    fun ChannelEvt set_state(int channel, float value) {
        return set_state(channel, value, now);
    }

    fun ChannelEvt set_state(int channel, float value, time t) {
	_value => _prev_value;
	_time => _prev_time;

	channel => _channel;
	value => _value;
	t => _time;

	return this;
    }

    fun int get_channel() { return _channel; }
    fun float get_value() { return _value; }

    fun float get_prev_value() { return _prev_value; }
    fun time get_prev_time() { return _prev_time; }

    fun float get_dv() { return _value - _prev_value; }
    fun dur get_dt() { return _time - _prev_time; }

    fun float get_dvdt() { return get_dv() / ((get_dt() / 1::second)); }
	
}

