// GameTrakMotionFilter: only forward significant motion events.
// 
// The GameTrak emits a constant birrage of motion events, whether
// or not there is any signficant change on an axis or not.  This
// class implements a filter that only forwards events when there
// has been a significant change.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

public class GameTrakMotionFilter extends Observer {

    // trigger event when the time error * x or y error exceeds this
    0.002 => static float _XY_THRESHOLD;

    // trigger event when the time error * z error exceeds this
    0.001 => static float _Z_THRESHOLD;

    // ================================================================
    // singleton instance

    static GameTrakMotionFilter @ _game_trak_motion_filter;

    fun static GameTrakMotionFilter game_trak_motion_filter() {
	if (_game_trak_motion_filter == null) new GameTrakMotionFilter @=> _game_trak_motion_filter;
	return _game_trak_motion_filter;
    }

    // ================================================================
    // instance variables

    Dispatcher _dispatcher[GameTrak.CHANNEL_COUNT];

    // ================================================================
    // instance methods

    // one-time initialization: attach this filter to all GameTrak
    // raw outputs.
    fun GameTrakMotionFilter init() { return init(GameTrak.game_trak()); }
    fun GameTrakMotionFilter init(GameTrak gt) {
	for (0 => int axis; axis<GameTrak.CHANNEL_COUNT; axis++) {
	    gt.get_dispatcher(axis).attach(this);
	}
	return this;
    }

    fun Dispatcher get_dispatcher(int axis) { return _dispatcher[axis]; }

    // Arrive here with any message from GameTrak
    fun void update(Observable o, Msg message) {
	Util.trace(this, "update(" + o.toString() + "," + message.toString() + ")[1]");
	message $ ChannelEvt @=> ChannelEvt cm;
	cm.get_channel() => int axis;

	_XY_THRESHOLD => float threshold;
	if ((axis == GameTrak.LEFT_Z) || (axis == GameTrak.RIGHT_Z)) {
	    _Z_THRESHOLD => threshold;
	}

	// compute value and time errors between previously broadcast
	// message (prev) and currently offered message (cm).
	get_dispatcher(axis) @=> Dispatcher @ dispatcher;
	(dispatcher.get_state() $ ChannelEvt) @=> ChannelEvt @ prev;

	true => int needs_update;
	if (prev != null) {
	    cm.get_value() - prev.get_value() => float dv;
	    (cm.get_time() - prev.get_time()) / 1::second => float dt;
	    // broadcast iff (dv * dt) exceeds threshold
	    if (Math.fabs(dv * dt) < threshold) {
		false => needs_update;
	    } else {
		Util.trace(this, "update(" + o.toString() + "," + message.toString() + ")[3]");
	    }
	}

	if (needs_update) {
	    Util.trace(this, "update(" + o.toString() + "," + message.toString() + ")[4]");
	    dispatcher.set_state(ChannelEvt.create(axis, cm.get_value(), cm.get_time(), prev));
	}
	Util.trace(this, "update(" + o.toString() + "," + message.toString() + ")[5]");
    }
}
