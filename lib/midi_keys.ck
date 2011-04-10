// MIDIKeys: gather all Oxygen8 MIDI keys into one Dispatcher
//
// Perhaps it was a bad design decision, but each MIDI key on the
// Oxygen8 has its own Dispatcher.  This makes it difficult to connect
// (and disconnect) all of the MIDI keys in a single operation.
//
// This MIDIKeys attaches to all 128 MIDI Key dispatchers in
// the Oxygen8 interface and presents them as a single Dispatcher.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 091210_002741: extends Observer rather than Dispatcher
// 091210_003622: singleton MIDI_KEYS initialized at file-load time
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

public class MIDIKeys extends Observer {

    // ================================================================
    // singleton instance

    static MIDIKeys @ MIDI_KEYS;

    fun static MIDIKeys midi_keys() { return MIDI_KEYS; }

    fun static Dispatcher midi_key_dispatcher() {
	return MIDI_KEYS.get_dispatcher();
    }

    fun static Observer midi_key_observer() {
	return MIDI_KEYS.get_observer();
    }

    // ================================================================
    // instance variables

    Dispatcher _dispatcher;

    fun Observer get_observer() { return this; }
    fun Dispatcher get_dispatcher() { return _dispatcher; }

    // one-time initialization
    fun MIDIKeys init() { return init(Oxygen8.oxygen8()); }
    fun MIDIKeys init(Oxygen8 o8) {
	for (0 => int key; key < Oxygen8.MIDI_KEY_COUNT; key++) {
	    o8.key_dispatcher(key).attach(get_observer());
	}
    }

    // simply forward any incoming message to our dispatcher
    fun void update(Observable o, Msg message) { _dispatcher.set_state(message); }

}

// one-time initialization
new MIDIKeys @=> MIDIKeys.MIDI_KEYS;
