"/Users/r/Projects/DPP/perf_1.1/" => string HOME;
HOME + "lib/" => string LIB;
HOME + "patches/" => string PATCHES;
HOME + "voices/" => string VOICES;

"/Users/r/Projects/DPP/test_1.1/" => string TEST;
TEST + "lib/" => string TEST_LIB;
TEST + "patches/" => string TEST_PATCHES;
TEST + "voices/" => string TEST_VOICES;
TEST + "tests/" => string TEST_TESTS;

// foundation classes and utilities
Machine.add(LIB + "util.ck");
Machine.add(LIB + "msg.ck");
Machine.add(LIB + "evt.ck");
Machine.add(LIB + "comparison.ck");
Machine.add(LIB + "operation.ck");
Machine.add(LIB + "queue.ck");
Machine.add(LIB + "semaphore.ck");

// basic types

// The primary elements of the message passing mechanism...
Machine.add(LIB + "observable.ck");
Machine.add(LIB + "observer.ck");
Machine.add(LIB + "dispatcher.ck");

// ... and some specializations
Machine.add(LIB + "channel_evt.ck");
Machine.add(LIB + "channel_dispatcher.ck");
Machine.add(LIB + "pluck_evt.ck");

// support for input and output devices
Machine.add(LIB + "game_trak.ck");
Machine.add(LIB + "game_trak_motion_filter.ck");
Machine.add(LIB + "game_trak_pluck_detector.ck");
Machine.add(LIB + "oxygen8.ck");
Machine.add(LIB + "audio_io.ck");
Machine.add(LIB + "midi_keys.ck");
Machine.add(LIB + "std_controls_observer.ck");
Machine.add(LIB + "std_controls.ck");

// support for noisemaking
Machine.add(LIB + "vox.ck");
Machine.add(LIB + "vox_controller.ck");
Machine.add(LIB + "patch.ck");
Machine.add(LIB + "patch_manager.ck");

Machine.add(VOICES + "sproing_vox.ck");
Machine.add(VOICES + "sproing_vox_controller.ck");

Machine.add(VOICES + "babble_vox.ck");
Machine.add(VOICES + "babble_vox_controller.ck");
Machine.add(VOICES + "farfisa_vox.ck");
Machine.add(VOICES + "farfisa_vox_controller.ck");
Machine.add(VOICES + "fish_vox.ck");
Machine.add(VOICES + "fish_vox_controller.ck");
Machine.add(VOICES + "nose_vox.ck");
Machine.add(VOICES + "nose_vox_controller.ck");
Machine.add(VOICES + "pipes_vox.ck");
Machine.add(VOICES + "pipes_vox_controller.ck");
Machine.add(VOICES + "sloop_vox.ck");
Machine.add(VOICES + "sloop_vox_controller.ck");

// crank up the machine, jenks...
Machine.add(HOME + "_main.ck");
