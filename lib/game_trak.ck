// GameTrak: a low-level interface to a GameTrak game controller.
//
// The GameTrak controller presents as a six-axis joystick and a
// single footswitch.  This GameTrak class provides:
//
// * Dispatcher/Observer interface
// * Inhibition of messages when corresponding string released.
// * Outputs normalized 0..1
//
// GameTrak runs a listener thread, waiting for messages to arrive on
// its USB port.  When it receives a message, it posts a message on
// the appropriate Dispatcher port.
//
// The ports:
//
// AXES
// 	LEFT_X: left-hand "east-west" axis (increasing x => east)
//	LEFT_Y: left-hand "north-south" axis (increasing y => north)
//	LEFT_Z: left-hand "up-down" axis (increasing z => up)
// 	RIGHT_X: right-hand "east-west" axis (increasing x => east)
//	RIGHT_Y: right-hand "north-south" axis (increasing y => north)
//	RIGHT_Z: right-hand "up-down" axis (increasing z => up)
//
// PSEUDO_AXES 
//	FOOTSWITCH: v==0.0 => released, v==1.0 => pressed
//	LEFT_SQUELCHED: v=1.0 => left string released
//	RIGHT_SQUELCHED: v=1.0 => right string released
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

public class GameTrak {

    0 => static int DEFAULT_JOYSTICK_DEVICE;

    // Names for the joystick "channels" (msg.channel).
    0 => static int LEFT_X;
    1 => static int LEFT_Y;
    2 => static int LEFT_Z;
    3 => static int RIGHT_X;
    4 => static int RIGHT_Y;
    5 => static int RIGHT_Z;
    6 => static int FOOTSWITCH;
    7 => static int LEFT_SQUELCHED;
    8 => static int RIGHT_SQUELCHED;

    // the number of channels
    9 => static int CHANNEL_COUNT;

    // bit masks for set_squelched() / is_squelched()
    (1 << LEFT_X)|(1 << LEFT_Y)|(1 << LEFT_Z)|(1 << LEFT_SQUELCHED) => static int LEFT_GROUP;
    (1 << RIGHT_X)|(1 << RIGHT_Y)|(1 << RIGHT_Z)|(1 << RIGHT_SQUELCHED) => static int RIGHT_GROUP;

    // when Z dips below this value (i.e. when the joystick's string
    // is released), we stop sending messages to attached observers
    0.0175 => static float _Z_SQUELCH_THRESHOLD;

    // ================================================================
    // singleton instance

    static GameTrak @ _game_trak;

    fun static GameTrak game_trak() {
	if (_game_trak == null) new GameTrak @=> _game_trak;
	return _game_trak;
    }

    // ================================================================
    // instance variables

    // most recent messages for each axis
    ChannelEvt _messages[CHANNEL_COUNT];

    // one dispatcher per axis
    Dispatcher _dispatcher[CHANNEL_COUNT];

    // per-axis squelch (implemented as a bit vector)
    int _squelched;

    // ================================================================
    // instance methods

    fun ChannelEvt get_message(int axis) { return _messages[axis]; }
    fun Dispatcher get_dispatcher(int axis) { return _dispatcher[axis]; }

    // ================================================================
    // private methods

    fun GameTrak init() { return init(DEFAULT_JOYSTICK_DEVICE); }
    fun GameTrak init(int device) {
	spork ~ _process(device);
	me.yield();
	return this;
    }

    fun void _process(int device) {
	Hid hid;
	HidMsg msg;

	while (!hid.openJoystick(device)) {
	    <<< now, me, this, "can't open joystick", device, "...waiting 10 seconds" >>>;
	    10::second => now;
	}
	<<< now, me, this, "reading joystick data from port", device, "->",hid.name() >>>;
	while (true) {
	    // wait for an event and dispatch according to event type
	    hid => now;
	    while (hid.recv(msg)) {
		if (msg.isAxisMotion()) {
		    _process_motion(msg.which, msg.axisPosition);
		} else if (msg.isButtonDown()) {
		    _process_motion(FOOTSWITCH, 1.0);
		} else if (msg.isButtonUp()) {
		    _process_motion(FOOTSWITCH, -1.0);
		} else if (msg.isHatMotion()) {
		    <<< now, me, this,"joystick hat", msg.which,":", msg.idata >>>;
		} else {
		    <<< now, me, this,"unknown msg", msg >>>;
		}
	    }
	}
    }

    // Process a motion event.  
    //
    fun void _process_motion(int axis, float raw_v) {
	// <<< now, me, this, "_process_motion[1](", axis, raw_v, ")" >>>;

	// flip value for z axes
	if ((axis == LEFT_Z) || (axis == RIGHT_Z)) { -1.0 *=> raw_v; }

	// convert from -1..1 to 0..1
	(raw_v * 0.5) + 0.5 => float curr_v;

	update_squelch(axis, curr_v);
	if (!is_squelched(axis)) {
	    get_dispatcher(axis) @=> Dispatcher @ dispatcher;
	    (dispatcher.get_state() $ ChannelEvt) @=> ChannelEvt @ prev;
	    dispatcher.set_state(ChannelEvt.create(axis, curr_v, now, prev));
	}
    }

    fun int is_squelched(int axis) {
	return ((1 << axis) & _squelched) != 0;
    }

    fun void update_squelch(int axis, float value) {
	value < _Z_SQUELCH_THRESHOLD => int squelched;
	if (axis == LEFT_Z) {
	    set_squelched(LEFT_SQUELCHED, LEFT_GROUP, squelched);
	} else if (axis == RIGHT_Z) {
	    set_squelched(RIGHT_SQUELCHED, RIGHT_GROUP, squelched);
	}
    }

    // if squelched differs from the current squelch status for the named
    // axis, update the _squelched bitmask and send a LEFT_SQUELCHED or
    // RIGHT_SQUELCHED message.
    //
    fun void set_squelched(int axis, int bitmask, int squelched) {
	if (is_squelched(axis) != squelched) {
	    set_squelch_bitmask(bitmask, squelched);
	    get_dispatcher(axis) @=> Dispatcher @ dispatcher;
	    (dispatcher.get_state() $ ChannelEvt) @=> ChannelEvt @ prev;
	    dispatcher.set_state(ChannelEvt.create(axis, (squelched?1.0:0.0), now, prev));
	}
    }
	
    // if squelched is true, turn on the bitmask in _squelched.
    // if squelched if false, turn off the bitmask in _squelched.
    //
    fun void set_squelch_bitmask(int bitmask, int squelched) {
	if (squelched) {
	    bitmask |=> _squelched;
	} else {
	    ~bitmask &=> _squelched;
	}
    }

}
