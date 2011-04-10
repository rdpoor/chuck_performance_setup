// Oxygen8: Generic interface to MIDIMan Oxygen8 midi keyboard.  
// 
// This class provides:
// * Dispatcher/Observer interface
// * all_notes_off()
// * Manages sustain pedal
// * Controller outputs normalized 0..1
// 
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class Oxygen8 extends MidiIn {

    // ================================================================
    // class variables

    0 => static int DEFAULT_MIDI_DEVICE;

    128 => static int MIDI_KEY_COUNT;
    8 => static int KNOB_COUNT;

    // Map each message generating source to a unique channel number
    0 =>			static int KEY_CHANNEL_BASE;
    KEY_CHANNEL_BASE + MIDI_KEY_COUNT =>	static int KNOB_CHANNEL_BASE;
    KNOB_CHANNEL_BASE + KNOB_COUNT =>		static int PITCHWHEEL_CHANNEL;
    PITCHWHEEL_CHANNEL + 1 =>	static int MODWHEEL_CHANNEL;
    MODWHEEL_CHANNEL + 1 =>	static int DATAENTRY_CHANNEL;
    DATAENTRY_CHANNEL + 1 =>	static int SUSTAIN_PEDAL_CHANNEL;
    
    SUSTAIN_PEDAL_CHANNEL + 1 => static int CHANNEL_COUNT;

    // knob => channel indeces
    0 => static int KNOB_1;
    1 => static int KNOB_2;
    2 => static int KNOB_3;
    3 => static int KNOB_4;
    4 => static int KNOB_5;
    5 => static int KNOB_6;
    6 => static int KNOB_7;
    7 => static int KNOB_8;

    // ================================================================
    // singleton instance

    static Oxygen8 @ _oxygen8;

    fun static Oxygen8 oxygen8() {
	if (_oxygen8 == null) new Oxygen8 @=> _oxygen8;
	return _oxygen8;
    }

    // ================================================================
    // class methods

    // Midi Value to Float: convert a one-byte controller value
    // (0..127) into a float between 0.0 and 1.0 (inclusive)
    fun static float mv_to_f(int data) { return (data / 127.0); }

    // Midi Value to Float: convert a two-byte controller value
    // (e.g. pitchwheel) to a float between 0.0 and 1.0 (inclusive)
    //
    // Implementation note:
    //
    // hibyte spans values from 0...127 (inclusive)
    // lobyte spans values from 0...127 (inclusive)
    // lobyte has a weight of hibyte/128.
    // The goal is to map f(lobyte,hibyte) => 0.0 ... 1.0 (inclusive)
    //
    // If we simply do linear interpolation between the two endpoints,
    // the "middle" value (hibyte=64, lobyte=0) isn't 0.5.  So we use
    // two slopes, one for the lower half and one for the upper half.

    0.5 / ((63 * 128) + 128) => static float _MVTOF_LO_SLOPE;
    0.5 / ((63 * 128) + 127) => static float _MVTOF_HI_SLOPE;

    fun static float mv_to_f(int lobyte, int hibyte) {
	float v;
	if (hibyte <= 64) {
	    ((hibyte * 128) + lobyte) * _MVTOF_LO_SLOPE => v;
	} else {
	    0.5 + (((hibyte - 64) * 128) + lobyte) * _MVTOF_HI_SLOPE => v;
	}
	return v;
    }

    fun static int is_key_press(MidiMsg msg) { return (msg.data1 == 144); }
    fun static int is_pitchwheel(MidiMsg msg) { return (msg.data1 == 224); }

    fun static int is_control_change(MidiMsg msg) { return msg.data1 == 176 ; }
    // the following methods assume that data1 == 176
    fun static int is_modwheel(int data2) { return data2 == 1; }
    fun static int is_data_entry(int data2) { return data2 == 7; }
    fun static int is_sustain_pedal(int data2) { return data2 == 64; }
    fun static int is_knob_1(int data2) { return data2 == 74; }
    fun static int is_knob_2(int data2) { return data2 == 71; }
    fun static int is_knob_3(int data2) { return data2 == 81; }
    fun static int is_knob_4(int data2) { return data2 == 91; }
    fun static int is_knob_5(int data2) { return data2 == 16; }
    fun static int is_knob_6(int data2) { return data2 == 80; }
    fun static int is_knob_7(int data2) { return data2 == 19; }
    fun static int is_knob_8(int data2) { return data2 == 2; }

    // ================================================================
    // instance variables

    // one big array to hold all the state
    ChannelDispatcher _state[CHANNEL_COUNT];

    int _key_state[128];	// on, off, sustained
    0 => static int KEY_OFF;	// key is off
    1 => static int KEY_ON;	// key is on
    2 => static int KEY_SUS;	// key is being sustained by pedal

    // ================================================================
    // methods

    fun ChannelDispatcher key_dispatcher(int i) { return _state[i+KEY_CHANNEL_BASE]; }
    fun ChannelDispatcher pitchwheel_dispatcher() { return _state[PITCHWHEEL_CHANNEL]; }
    fun ChannelDispatcher modwheel_dispatcher() { return _state[MODWHEEL_CHANNEL]; }
    fun ChannelDispatcher dataentry_dispatcher() { return _state[DATAENTRY_CHANNEL]; }
    fun ChannelDispatcher knob_dispatcher(int i) { return _state[i+KNOB_CHANNEL_BASE]; }
    fun ChannelDispatcher sustain_pedal_dispatcher() { return _state[SUSTAIN_PEDAL_CHANNEL]; }

    fun Oxygen8 reset() {
	all_notes_off();
	pitchwheel_dispatcher().set_value(0.0);
	modwheel_dispatcher().set_value(0.0);
	dataentry_dispatcher().set_value(0.0);
	for (0=>int i; i<KNOB_COUNT; i++) { knob_dispatcher(i).set_value(0.0); }
	sustain_pedal_dispatcher().set_value(0.0);
	return this;
    }

    fun Oxygen8 all_notes_off() {
	for (0=>int i; i< MIDI_KEY_COUNT; i++) { _release_key(i);	}
    }

    // ================================================================
    // private methods

    // one time initialization
    fun Oxygen8 init() { return init(DEFAULT_MIDI_DEVICE); }
    fun Oxygen8 init(int midi_device) { 
	for (0 => int i; i<MIDI_KEY_COUNT; i++ ) {
	    key_dispatcher(i).set_channel(i + KEY_CHANNEL_BASE);
	}
	for (0 => int i; i<KNOB_COUNT; i++ ) {
	    knob_dispatcher(i).set_channel(i + KNOB_CHANNEL_BASE);
	}
	pitchwheel_dispatcher().set_channel(PITCHWHEEL_CHANNEL);
	modwheel_dispatcher().set_channel(MODWHEEL_CHANNEL);
	dataentry_dispatcher().set_channel(DATAENTRY_CHANNEL);
	sustain_pedal_dispatcher().set_channel(SUSTAIN_PEDAL_CHANNEL);

	spork ~ _process(midi_device); 
	me.yield();

	return this;
    }

    fun int get_key_state(int midikey) { return _key_state[midikey]; }

    fun void set_key_state(int midikey, int state) {
	state => _key_state[midikey];
    }

    // ================ 
    // This is the main processing loop for midi events arriving from
    // the Oxygen8.  It loops continually in its own thread.
    //
    fun void _process(int midi_device) {
	while (!this.open(midi_device)) {
	    <<< now, me, this, "can't open midi device", midi_device, "...waiting 10 seconds" >>>;
	    10::second => now;
	}
	
	MidiMsg msg;
	<<< now, me, this, "reading midi from port ", midi_device, "->", this.name() >>>;
	while (true) {
	    // wait for a MIDI event and dispatch on its contents
	    this => now;
	    while (this.recv(msg)) {
		if (is_key_press(msg)) { 
		    do_key_press(msg);
		} else if (is_pitchwheel(msg)) { 
		    do_pitchwheel(msg);
		} else if (is_control_change(msg)) {
		    do_control_change(msg);
		} else {
		    <<< now, me, this, "unknown midi event", msg.data1, msg.data2, msg.data3 >>>;
		} // if
	    } // while (me.recv(msg))
	} // while (true)
    } // fun process

    // Handle a key press.  The only complexity here is accounting for
    // the state of the sustain pedal when a key is released.
    //
    fun void do_key_press(MidiMsg msg) {
	if (msg.data3 > 0) {	
	    // key pressed
	    _press_key(msg.data2, mv_to_f(msg.data3)); 

	} else if (sustain_pedal_dispatcher().get_value() != 0.0) {
	    // key released with sustain pedal
	    _sustain_key(msg.data2); 

	} else {
	    // key released w/o sustain pedal
	    _release_key(msg.data2);
	}
    }

    fun void do_pitchwheel(MidiMsg msg) {
	pitchwheel_dispatcher().set_value(mv_to_f(msg.data2, msg.data3));
    }

    fun void do_control_change(MidiMsg msg) {
	msg.data2 => int data2;

	if (is_modwheel(data2)) {
	    modwheel_dispatcher().set_value(mv_to_f(msg.data3));

	} else if (is_data_entry(data2)) {
	    dataentry_dispatcher().set_value(mv_to_f(msg.data3));

	} else if (is_sustain_pedal(data2)) {
	    sustain_pedal_dispatcher().set_value(mv_to_f(msg.data3));
	    // When releasing the pedal, send key change events on all
	    // sustained notes
	    if (msg.data3 == 0) _release_sustain();
	    
	} else if (is_knob_1(data2)) {
	    knob_dispatcher(KNOB_1).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_2(data2)) {
	    knob_dispatcher(KNOB_2).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_3(data2)) {
	    knob_dispatcher(KNOB_3).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_4(data2)) {
	    knob_dispatcher(KNOB_4).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_5(data2)) {
	    knob_dispatcher(KNOB_5).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_6(data2)) {
	    knob_dispatcher(KNOB_6).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_7(data2)) {
	    knob_dispatcher(KNOB_7).set_value(mv_to_f(msg.data3));
            
	} else if (is_knob_8(data2)) {
	    Util.trace(this, "is_knob_8()[1]");
	    knob_dispatcher(KNOB_8).set_value(mv_to_f(msg.data3));
	    Util.trace(this, "is_knob_8()[2]");

	} else {
	    <<< now, me, this, "unknown control change event", msg.data1, msg.data2, msg.data3 >>>;
	}
    }

    // Arrive here on key press: update key state and send a note_on
    // message
    fun void _press_key(int midikey, float velocity) {
	Util.trace(this, "press_key()[1]");
	set_key_state(midikey, KEY_ON);
	key_dispatcher(midikey).set_value(velocity);
	Util.trace(this, "press_key()[2]");
    }

    // Arrive here on key released with sustain pedal: update key
    // state but don't send a message.
    fun void _sustain_key(int midikey) {
	set_key_state(midikey, KEY_SUS);
    }

    // Arrive here on key released w/o sustain pedal: update key state
    // and send note off message
    fun void _release_key(int midikey) {
	set_key_state(midikey, KEY_OFF);
	key_dispatcher(midikey).set_value(0.0);
    }

    // Arrive here when sustain pedal released: release any sustained
    // keys.
    fun void _release_sustain() {
	for (0 => int midikey; midikey<MIDI_KEY_COUNT; midikey++) {
	    if (get_key_state(midikey) == KEY_SUS) {
		_release_key(midikey);
	    }
	}
    }



} // class Oxygen8