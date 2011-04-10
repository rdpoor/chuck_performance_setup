// class Main: allocates, initializes and connects all the basic
// objects required for the system.
//
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.

class MainObserver extends Observer {
    Main @ _main;
    fun MainObserver init(Main main) { main @=> _main; return this; }
}
class DataEntryObserver extends MainObserver {
    fun void update(Observable o, Msg msg) { _main.handle_data_entry(msg $ ChannelEvt); }
}
class Knob1Observer extends MainObserver {
    fun void update(Observable o, Msg msg) { _main.handle_knob_1(msg $ ChannelEvt); }
}
class Knob2Observer extends MainObserver {
    fun void update(Observable o, Msg msg) { _main.handle_knob_2(msg $ ChannelEvt); }
}
class Knob3Observer extends MainObserver {
    fun void update(Observable o, Msg msg) { _main.handle_knob_3(msg $ ChannelEvt); }
}
class Knob4Observer extends MainObserver {
    fun void update(Observable o, Msg msg) { _main.handle_knob_4(msg $ ChannelEvt); }
}
class Knob8Observer extends MainObserver {
    fun void update(Observable o, Msg msg) { 
	Util.trace(this, "update()[1]");
	_main.handle_knob_8(msg $ ChannelEvt); 
	Util.trace(this, "update()[2]");
    }
}


public class Main {
    // ================================================================
    // allocate essential input and output objects

    // ================================================================
    // one-time initialization.  

    fun Main init() {
	// true => Util.IS_TRACING;
	Util.trace(this, "main(01)");

	AudioIO.audio_io().init();
	Oxygen8.oxygen8().init();
	GameTrak.game_trak().init();
	GameTrakMotionFilter.game_trak_motion_filter().init();
	MIDIKeys.midi_keys().init();
	PatchManager.patch_manager().init();

	Util.trace(this, "main(02)");

	Oxygen8.oxygen8() @=> Oxygen8 @ o8;
	// attach our custom Observers so we receive handle_xxx() messages from Oxygen8
	o8.dataentry_dispatcher().attach((new DataEntryObserver).init(this));
	o8.knob_dispatcher(Oxygen8.KNOB_1).attach((new Knob1Observer).init(this));
	o8.knob_dispatcher(Oxygen8.KNOB_2).attach((new Knob2Observer).init(this));
	o8.knob_dispatcher(Oxygen8.KNOB_3).attach((new Knob3Observer).init(this));
	o8.knob_dispatcher(Oxygen8.KNOB_4).attach((new Knob4Observer).init(this));
	o8.knob_dispatcher(Oxygen8.KNOB_8).attach((new Knob8Observer).init(this));
	Util.trace(this, "main(03)");

	// indicate that all's well...
	AudioIO.audio_io().boop();
	Util.trace(this, "main(04)");

	return this;
    }

    // ================================================================
    // Things controlled by Oxygen8 sliders and knobs:
    //
    // Data Entry controls audio post-gain
    // Knob 1 controls audio pre-compressor gain
    // Knob 2 controls reverb wet/dry mix
    // Knob 3 controls delay mix
    // Knob 4 controls delay time
    // Knob 8 controls patch selection

    fun void handle_data_entry(ChannelEvt m) {
	m.get_value() => float gain;
	// <<< "set_post_gain(", gain, ")" >>>;
	AudioIO.audio_io().set_post_gain(gain);
    }

    fun void handle_knob_1(ChannelEvt m) {
	4.0 * m.get_value() => float gain;
	AudioIO.audio_io().set_pre_gain(gain);
    }

    fun void handle_knob_2(ChannelEvt m) {
	m.get_value() => float mix;
	AudioIO.audio_io().set_reverb_mix(mix);
    }

    fun void handle_knob_3(ChannelEvt m) {
	0.5 * m.get_value() => float mix;
	AudioIO.audio_io().set_echo_mix(mix);
    }

    fun void handle_knob_4(ChannelEvt m) {
	m.get_value() => float delay;
	AudioIO.audio_io().set_echo_delay(delay);
    }

    fun void handle_knob_8(ChannelEvt m) {
	Util.trace(this, "handle_knob8()[1]");
	m.get_value() => float v;
	PatchManager.patch_manager().select_patch(v);
	Util.trace(this, "handle_knob8()[2]");
    }

}

// ================================================================
// top level

"/Users/r/Projects/DPP/perf_1.1/" => string HOME;
HOME + "patches/" => string PATCHES;

"/Users/r/Projects/DPP/test_1.1/" => string TEST_HOME;
TEST_HOME + "patches/" => string TEST_PATCHES;

Main main;
// true => Util.IS_TRACING;
main.init();

PatchManager.load_patch(PATCHES + "babble_patch.ck");
PatchManager.load_patch(PATCHES + "farfisa_patch.ck");
PatchManager.load_patch(PATCHES + "fish_patch");
PatchManager.load_patch(PATCHES + "nose_patch.ck");
PatchManager.load_patch(PATCHES + "pick_patch.ck");
PatchManager.load_patch(PATCHES + "pipes_patch.ck");
PatchManager.load_patch(PATCHES + "sloop_patch.ck");
PatchManager.load_patch(PATCHES + "sproing_patch.ck");
// false => Util.IS_TRACING;

<<< "ready...">>>;

1::week => now;
