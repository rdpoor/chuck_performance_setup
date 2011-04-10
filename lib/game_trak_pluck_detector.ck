// GameTrakPluckDetector: detect plucks on GameTrak string
//
// When we receive an X or Y axis message from the GameTrak, we look
// at the instantaneous magnitude rate of change.  If it exceeds a
// threshold, we consider it to be a pluck.
//
// 19 Nov 2009: This version appears to be working quite well.  Plucks
// are accurately detected, although "phase" isn't dependable.  We are
// getting double-plucks as the un-damped GameTrak string resonates.
// One way to fix that is to make a "decaying threshold" after each
// pluck: a new pluck must be above the threshold, which decays from
// initial pluck value down to zero over some interval.  This should
// fix the problem of the resonating string, but will also inhibit
// a soft pluck following a hard pluck.  C'est la vie.
//
// 19 Nov 2009: It appears that the first hit above threshold level
// is a reasonably accurate determinant for phase, so we shoud use
// that.  
//
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.


public class GameTrakPluckDetector extends Observer {
    // ================================================================
    // class constants

    25.0 => float MAG2_THRESHOLD; // ignore mag^2 less than this value
    1600.0 => float MAG2_MAX;	  // largest expected mag^2
    .1::second => dur PLUCK_HOLDOFF;

    // ================================================================
    // instance variables

    time _prev_pluck_time;
    GameTrak @ _gt;
    int _x_axis;
    int _y_axis;
    PluckEvt _pluck_message;
    Dispatcher _dispatcher;

    // ================================================================
    // public methods

    // get the Observer for the pluck detector
    fun Observer get_observer() { return this; }

    // get the Dispatcher for the pluck detector
    fun Dispatcher get_dispatcher() { return _dispatcher; }

    // get the previously sent message
    fun PluckEvt get_message() { return _pluck_message; }

    // Direct x and y joystick updates to this pluck detector
    fun GameTrakPluckDetector init(int x_axis, int y_axis) {
	return init(GameTrak.game_trak(), x_axis, y_axis);
    }
    // ### Could be better: once initialized, GameTrakPluckDetector is
    // always attached to the GameTrak -- should be a way to detach it
    // when unused in order to save cycles.
    fun GameTrakPluckDetector init(GameTrak gt, int x_axis, int y_axis) {
	Util.IS_TRACING => int p;
	true => Util.IS_TRACING;
	Util.trace(this, "init(" + x_axis + "," + y_axis + ")");
	p => Util.IS_TRACING;
	gt @=> _gt;
	x_axis => _x_axis;
	y_axis => _y_axis;
	_gt.get_dispatcher(x_axis).attach(this);
	_gt.get_dispatcher(y_axis).attach(this);
	return this;
    }

    // Arrive here when the GameTrak produces a message on _x_axis or
    // on _y_axis. If the message is on the x_axis, we "reach back"
    // into the GameTrak to get the previous y_axis value and vice
    // versa.
    // 
    fun void update(Observable o, Msg message) {
	message $ ChannelEvt @=> ChannelEvt cm;
	if (cm.get_channel() == _x_axis) {
	    _process(cm, _gt.get_message(_y_axis));
	} else if (cm.get_channel() == _y_axis) {
	    _process(_gt.get_message(_x_axis), cm);
	}
    }

    // ================================================================
    // private methods

    fun void _process(ChannelEvt x, ChannelEvt y) {
	// don't double-pluck...
	if ((now - _prev_pluck_time) < PLUCK_HOLDOFF) return;

	Util.IS_TRACING => int p;
	false => Util.IS_TRACING;
	Util.trace(this, "_process[1](" + x.toString() + "," + y.toString() + ")");
	p => Util.IS_TRACING;

	// <<< x.get_time(), y.get_time() >>>;
	// ### experiment: does assuring equal times help or hurt?
	// if (x.get_time() != y.get_time()) return;

	// Util.IS_TRACING => int p;
	false => Util.IS_TRACING;
	Util.trace(this, "_process[2](" + x.toString() + "," + y.toString() + ")");
	p => Util.IS_TRACING;

	// magnitude squared = dxdt^2 + dydt^2
	x.get_dvdt() => float dxdt;
	y.get_dvdt() => float dydt;
	(dxdt*dxdt) + (dydt*dydt) => float mag2;

	false => Util.IS_TRACING;
	Util.trace(this, "_process[3](" + dxdt + "\t" + dydt + "\t" + mag2 + ")");
	p => Util.IS_TRACING;
	if (mag2 > MAG2_THRESHOLD) {
	    Math.min(1.0, mag2/MAG2_MAX) => float amplitude;
	    (Math.atan2(dxdt, dydt) + pi) / (2*pi) => float omega;
	    // 0.0 < omega <= 1.0 and describes the direction of plucking
	    now => _prev_pluck_time;
	    Util.IS_TRACING => int p;
	    true => Util.IS_TRACING;
	    Util.trace(this, "do_pluck()");
	    _dispatcher.set_state(PluckEvt.create(amplitude, omega, now));
	    p => Util.IS_TRACING;
	}
    }

}
