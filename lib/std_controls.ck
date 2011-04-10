// StdControls: attach standard MIDI controls to a StdControlsObserver
// 
// StdControls simplifies the connection between various the MIDI
// control sources used in our system (keys, modwheels, joysticks) and
// a StdControlsObserver.  After a call to std_control.attach(), a
// note_on MIDI event (e.g.) will call obs.handle_key_press().
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091203_163130: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

// ================================================================
// helper classes to implment StdControls

class StdControl extends Observer {
    0 => static int ATTACH;
    1 => static int DETACH;
    2 => static int RESEND;

    StdControlsObserver @ _obs;
    Dispatcher @ _dispatcher;
    fun StdControl init(StdControlsObserver obs, Dispatcher dispatcher) {
	obs @=> _obs;
	dispatcher @=> _dispatcher;
	return this;
    }
    fun StdControl attach() { _dispatcher.attach(this); return this; }
    fun StdControl detach() { _dispatcher.detach(this); return this; }
    fun StdControl resend() { 
	_dispatcher.get_state() @=> Msg @ prev;
	if (prev != null) this.update(_dispatcher, prev);
	return this;
    }
    fun StdControl process(int op) {
	if (op == ATTACH) {
	    this.attach();
	} else if (op == DETACH) {
	    this.detach();
	} else if (op == RESEND) {
	    this.resend();
	}
	return this;
    }
}
class StdKeyPress extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_key_press(msg $ ChannelEvt); }
}
class StdPitchWheel extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_pitchwheel(msg $ ChannelEvt); }
}
class StdModWheel extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_modwheel(msg $ ChannelEvt); }
}
class StdDataEntry extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_dataentry(msg $ ChannelEvt); }
}
class StdKnob05 extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_knob_05(msg $ ChannelEvt); }
}
class StdKnob06 extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_knob_06(msg $ ChannelEvt); }
}
class StdKnob07 extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_knob_07(msg $ ChannelEvt); }
}
class StdKeyboardPedal extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_keyboard_pedal(msg $ ChannelEvt); }
}
class StdGameTrakLeftX extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_left_x(msg $ ChannelEvt); }
}
class StdGameTrakLeftY extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_left_y(msg $ ChannelEvt); }
}
class StdGameTrakLeftZ extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_left_z(msg $ ChannelEvt); }
}
class StdGameTrakRightX extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_right_x(msg $ ChannelEvt); }
}
class StdGameTrakRightY extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_right_y(msg $ ChannelEvt); }
}
class StdGameTrakRightZ extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_right_z(msg $ ChannelEvt); }
}
class StdGameTrakFootswitch extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_footswitch(msg $ ChannelEvt); }
}
class StdGameTrakLeftSquelched extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_left_squelched(msg $ ChannelEvt); }
}
class StdGameTrakRightSquelched extends StdControl {
    fun void update(Observable o, Msg msg) { _obs.handle_game_trak_right_squelched(msg $ ChannelEvt); }
}

// ================================================================
// the public class starts here

public class StdControls {

    // ================================================================
    // instance variables

    StdKeyPress _key_press_observer;
    StdPitchWheel _pitchwheel_observer;
    StdModWheel _modwheel_observer;
    StdDataEntry _dataentry_observer;
    StdKnob05 _knob_05_observer;
    StdKnob06 _knob_06_observer;
    StdKnob07 _knob_07_observer;
    StdKeyboardPedal _keyboard_pedal_observer;
    StdGameTrakLeftX _game_trak_left_x_observer;
    StdGameTrakLeftY _game_trak_left_y_observer;
    StdGameTrakLeftZ _game_trak_left_z_observer;
    StdGameTrakRightX _game_trak_right_x_observer;
    StdGameTrakRightY _game_trak_right_y_observer;
    StdGameTrakRightZ _game_trak_right_z_observer;
    StdGameTrakFootswitch _game_trak_footswitch_observer;
    StdGameTrakLeftSquelched _game_trak_left_squelched_observer;
    StdGameTrakRightSquelched _game_trak_right_squelched_observer;

    // ================================================================
    // public methods

    fun StdControls init(StdControlsObserver obs) {
	if (Util.is_tracing()) Util.trace(this, ".init[1]()");
	MIDIKeys.midi_key_dispatcher() @=> Dispatcher @ midi_keys;
	Oxygen8.oxygen8() @=> Oxygen8 @ oxygen8;
	GameTrakMotionFilter.game_trak_motion_filter() @=> GameTrakMotionFilter @ gtmf;
	
	_key_press_observer.init(obs, midi_keys);
	_modwheel_observer.init(obs, oxygen8.modwheel_dispatcher());
	_dataentry_observer.init(obs, oxygen8.dataentry_dispatcher());
	_pitchwheel_observer.init(obs, oxygen8.pitchwheel_dispatcher());
	_knob_05_observer.init(obs, oxygen8.knob_dispatcher(Oxygen8.KNOB_5));
	_knob_06_observer.init(obs, oxygen8.knob_dispatcher(Oxygen8.KNOB_6));
	_knob_07_observer.init(obs, oxygen8.knob_dispatcher(Oxygen8.KNOB_7));
	_keyboard_pedal_observer.init(obs, oxygen8.sustain_pedal_dispatcher());
	
	_game_trak_left_x_observer.init(obs, gtmf.get_dispatcher(GameTrak.LEFT_X));
	_game_trak_left_y_observer.init(obs, gtmf.get_dispatcher(GameTrak.LEFT_Y));
	_game_trak_left_z_observer.init(obs, gtmf.get_dispatcher(GameTrak.LEFT_Z));
	_game_trak_right_x_observer.init(obs, gtmf.get_dispatcher(GameTrak.RIGHT_X));
	_game_trak_right_y_observer.init(obs, gtmf.get_dispatcher(GameTrak.RIGHT_Y));
	_game_trak_right_z_observer.init(obs, gtmf.get_dispatcher(GameTrak.RIGHT_Z));
	_game_trak_footswitch_observer.init(obs, gtmf.get_dispatcher(GameTrak.FOOTSWITCH));
	_game_trak_left_squelched_observer.init(obs, gtmf.get_dispatcher(GameTrak.LEFT_SQUELCHED));
	_game_trak_right_squelched_observer.init(obs, gtmf.get_dispatcher(GameTrak.RIGHT_SQUELCHED));
	if (Util.is_tracing()) Util.trace(this, ".init[2]()");
	return this;
    }

    // set up to receive handle_xxx(ChannelEvt msg) messages
    fun StdControls attach() { return _process(StdControl.ATTACH); }

    // stop receiving handle_xxx(ChannelEvt msg) messages
    fun StdControls detach() { return _process(StdControl.DETACH); }

    // ask each std control to re-issue an update() ChannelEvt
    // with its previously stored value
    fun StdControls resend() { return _process(StdControl.RESEND); }

    // ================================================================
    // private methods

    fun StdControls _process(int op) {
	if (Util.is_tracing()) Util.trace(this, ".process[1](" + op + ")");
	_key_press_observer.process(op);
	_pitchwheel_observer.process(op);
	_modwheel_observer.process(op);
	_dataentry_observer.process(op);
	_knob_05_observer.process(op);
	_knob_06_observer.process(op);
	_knob_07_observer.process(op);
	_keyboard_pedal_observer.process(op);
	_game_trak_left_x_observer.process(op);
	_game_trak_left_y_observer.process(op);
	_game_trak_left_z_observer.process(op);
	_game_trak_right_x_observer.process(op);
	_game_trak_right_y_observer.process(op);
	_game_trak_right_z_observer.process(op);
	_game_trak_footswitch_observer.process(op);
	_game_trak_left_squelched_observer.process(op);
	_game_trak_right_squelched_observer.process(op);
	if (Util.is_tracing()) Util.trace(this, ".process[2]()");
	return this;
    }

}

