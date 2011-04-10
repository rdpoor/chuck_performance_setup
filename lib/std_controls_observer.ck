// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091203_163130: Initial Version
// 100116_180642: Upgrade to Msg/Evt/ChannelEvt class structure.
// ====

public class StdControlsObserver {
    // methods called by StdControls to receive control inputs
    fun void handle_key_press(ChannelEvt msg) { }
    fun void handle_pitchwheel(ChannelEvt msg) { }
    fun void handle_modwheel(ChannelEvt msg) { }
    fun void handle_dataentry(ChannelEvt msg) { }
    fun void handle_knob_05(ChannelEvt msg) { }
    fun void handle_knob_06(ChannelEvt msg) { }
    fun void handle_knob_07(ChannelEvt msg) { }
    fun void handle_keyboard_pedal(ChannelEvt msg) { }
    fun void handle_game_trak_left_x(ChannelEvt msg) { }
    fun void handle_game_trak_left_y(ChannelEvt msg) { }
    fun void handle_game_trak_left_z(ChannelEvt msg) { }
    fun void handle_game_trak_right_x(ChannelEvt msg) { }
    fun void handle_game_trak_right_y(ChannelEvt msg) { }
    fun void handle_game_trak_right_z(ChannelEvt msg) { }
    fun void handle_game_trak_footswitch(ChannelEvt msg) { }
    fun void handle_game_trak_left_squelched(ChannelEvt msg) { }
    fun void handle_game_trak_right_squelched(ChannelEvt msg) { }
}
