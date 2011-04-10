// PatchManager: manage a set of Patches
//
// PatchManager provides methods for loading, starting and stopping
// Patch objects.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class PatchManager {

    // ================================================================
    // singleton instance

    static PatchManager @ _patch_manager;

    fun static PatchManager patch_manager() {
	if (_patch_manager == null) new PatchManager @=> _patch_manager;
	return _patch_manager;
    }

    fun static void load_patch(string patch_name) {
	Machine.add(patch_name);
    }

    fun static void register_patch(Patch patch) {
	patch.init();
	PatchManager.patch_manager().get_patches() << patch;
    }

    // ================================================================

    Patch @ _patches[];		// a list of all registered patches
    Patch @ _current_patch;	// active patch

    fun PatchManager init() {
	// nothing required at present...
	return this;
    }

    fun Patch[] get_patches() {
	if (_patches == null) { new Patch[0] @=> _patches; }
	return _patches;
    }

    fun Patch get_current_patch() {
	return _current_patch;
    }

    fun void select_patch(float v) {
	(v * (127.0 / 128.0) * get_patches().size()) $ int => int i;
	if ((i >= 0) && (i < get_patches().size())) {
	    set_current_patch(get_patches()[i]);
	}
    }

    fun void set_current_patch(Patch p) {
	if (p == _current_patch) return;
	if (_current_patch != null) _current_patch.stop(); 
	if ((p @=> _current_patch) == null) return;
	<<< "selecting", _current_patch.get_name() >>>;
	_current_patch.start();
    }

    fun void silence_all() {
	for (0 => int i; i < get_patches().size(); i++) {
	    get_patches()[i].stop();
	}
    }

}
