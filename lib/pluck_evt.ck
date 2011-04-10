// PluckEvt: encapsulate info about GameTrak pluck events
//
// PluckEvt captures the amplitude, phase and time of a plucked
// string.  Currently, generated only by the GameTrakPluckDetector
// class.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091210_000642: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// 100318_214230: Add detector slot to message.  And backed out of it.
// ====

public class PluckEvt extends Evt {
    float _amplitude;		// pluck amplitude
    float _omega;		// 0 <= phase <= 1.0

    fun static PluckEvt create(float amplitude, float omega, time t) {
	new PluckEvt @=> PluckEvt @ n;
	amplitude => n._amplitude;
	omega => n._omega;
	t => n._time;
	return n;
    }

    fun Msg clone() {
	new PluckEvt @=> PluckEvt @ n;
	return n.set_state(_amplitude, _omega, get_time());
    }

    fun PluckEvt set_state(float amplitude) {
	return set_state(amplitude, 0.0, now);
    }

    fun PluckEvt set_state(float amplitude, float omega) {
	return set_state(amplitude, omega, now);
    }

    fun PluckEvt set_state(float amplitude, float omega, time t) {
	amplitude => _amplitude;
	omega => _omega;
	t => _time;
	return this;
    }

    fun float get_amplitude() { return _amplitude; }
    fun float get_omega() { return _omega; }

}
