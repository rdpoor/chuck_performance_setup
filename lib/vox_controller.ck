// VoxController: manage Vox objects
//
// VoxController maintains a resource pool of Vox objects and doles
// out calls to note_on() and note_off() in order to implement several
// flavors of polyphony.  The effect of calling note_on():
//
// MONOPHONIC_STRICT: Commandeers any existing Vox (or creates a new
// one if needed) regardless of its state.
// MONOPHONIC: Stops any Vox already playing (giving it time to fade
// out) while a new voice starts.
// POLYPHONIC_STRICT: Commanders any Vox with a matching tag (or
// creates a new one if needed) regardless of its state.
// POLYPHONIC: Stops any Vox with matching tag already playing (giving
// it time to fade out) while a new voice starts.
// MULTIPHONIC: Starts a new Vox without stopping any other Vox.
// Only a note_off() will stop the voices.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_125100: Moved static initializers to end of file
// 100110_211355: Rename of QueueOp to Operation
// ====

// ================================================================
// But first, some specialized iterators for the voice pool

class TaggedOp extends Operation {
    int _tag;
    fun TaggedOp set_tag(int tag) { tag=>_tag; return this; }
}
// send stop() to every Vox in the note pool
class AllNotesOffOp extends Operation {
    fun Object apply(Object o, Object arg) { (o $ Vox).stop(); return null; }
}
// send stop() to each vox with matching tag
class NoteOffOp extends TaggedOp {
    fun Object apply(Object o, Object arg) {
        if ((o $ Vox).get_tag() == _tag) (o $ Vox).stop();
        return null;
    }
}
// send silence() to every Vox in the note pool
class AllNotesSilentOp extends Operation {
    fun Object apply(Object o, Object arg) { (o $ Vox).silence(); return null; }
}
// send note_silent() to every Vox with matching tag
class NoteSilentOp extends TaggedOp {
    fun Object apply(Object o, Object arg) {
        if ((o $ Vox).get_tag() == _tag) (o $ Vox).silence();
        return null;
    }
}
// find the first non-null Vox in the note pool (i.e. the first one)
class FindAnyOp extends Operation {
    fun Object apply(Object o, Object arg) { return o; }
}
// find the first idle Vox in the note pool
class FindAvailableOp extends Operation {
    fun Object apply(Object o, Object arg) { 
        return ((o $ Vox).is_idle())?o:(null $ Object); 
    }
}
// find the first Vox with matching tag
class FindTaggedOp extends TaggedOp {
    fun Object apply(Object o, Object arg) { 
        return ((o $ Vox).get_tag() == _tag)?o:(null $ Object);
    }
}

// ================================================================
// Manage a pool of Vox objects.
public class VoxController {

    0 => static int MONOPHONIC_STRICT;
    1 => static int MONOPHONIC;       
    2 => static int POLYPHONIC_STRICT;
    3 => static int POLYPHONIC;       
    4 => static int MULTIPHONIC;      

    static AllNotesOffOp @ ALL_NOTES_OFF_OP; 
    static NoteOffOp @ NOTE_OFF_OP; 
    static AllNotesSilentOp @ ALL_NOTES_SILENT_OP; 
    static NoteSilentOp @ NOTE_SILENT_OP; 
    static FindAnyOp @ FIND_ANY_OP; 
    static FindAvailableOp @ FIND_AVAILABLE_OP; 
    static FindTaggedOp @ FIND_TAGGED_OP; 

    // ================================================================
    // instance variables

    int _mode;
    Queue _vox_pool;
    
    // ================================================================
    // methods to be overridden in a subclass

    // Shadow this method in your subclass of VoxController to return
    // an instance of your Vox subclass.
    fun Vox allocate_vox() { return new Vox; }

    // ================================================================
    // instance methods

    fun VoxController init() {
        // <<< now, me, this.toString(), ".init()" >>>;
        return set_mode(POLYPHONIC);
    }

    fun Queue get_voices() { return _vox_pool; }

    // Set the polyphonic mode of this VoxController.
    fun int get_mode() { return _mode; }
    fun VoxController set_mode(int mode) { mode => _mode; return this; }
    
    fun Vox note_on(int tag) {
	if (Util.is_tracing()) Util.trace(this, "note_on[1](" + tag + ")");
        // <<< now, me, this.toString(), ".note_on[0](", tag, ")" >>>;
        // find a Vox, allocating if needed, and note_on() on it.
        null => Vox @ v;
        // find a Vox according to mode
        if (_mode == MONOPHONIC_STRICT) {
            // <<< now, me, this.toString(), ".note_on[1](", tag, ")" >>>;
            _find_or_allocate(FIND_ANY_OP) @=> v;

        } else if (_mode == MONOPHONIC) {
            // <<< now, me, this.toString(), ".note_on[2](", tag, ")" >>>;
            all_notes_off();
            _find_or_allocate(FIND_AVAILABLE_OP) @=> v;

        } else if (_mode == POLYPHONIC_STRICT) {
            // <<< now, me, this.toString(), ".note_on[3](", tag, ")" >>>;
            (get_voices().apply(FIND_TAGGED_OP.set_tag(tag)) $ Vox) @=> v;
            if (v == null) _find_or_allocate(FIND_AVAILABLE_OP) @=> v;

        } else if (_mode == POLYPHONIC) {
            // <<< now, me, this.toString(), ".note_on[4](", tag, ")" >>>;
            note_off(tag);
            _find_or_allocate(FIND_AVAILABLE_OP) @=> v;

        } else if (_mode == MULTIPHONIC) {
            // <<< now, me, this.toString(), ".note_on[5](", tag, ")" >>>;
            _find_or_allocate(FIND_AVAILABLE_OP) @=> v;

        }
        // now that we've got our note, play it...
        // <<< now, me, this.toString(), ".note_on[6](", tag, "), v=", v >>>;
        return v.start(tag);
    }            
    
    fun VoxController all_notes_off() { 
        get_voices().apply(ALL_NOTES_OFF_OP);
        return this;
    }

    fun VoxController note_off(int tag) {
        get_voices().apply(NOTE_OFF_OP.set_tag(tag));
        return this;
    }

    fun VoxController all_notes_silent() { 
        get_voices().apply(ALL_NOTES_SILENT_OP);
        return this;
    }

    fun VoxController note_silent(int tag) {
        get_voices().apply(NOTE_SILENT_OP.set_tag(tag));
        return this;
    }

    // ================================================================
    // private methods

    fun Vox _find_or_allocate(Operation op) {
        (get_voices().apply(op) $ Vox) @=> Vox @ v;
        return ((v != null)?v:(get_voices().push(allocate_vox().init()) $ Vox));
    }
        

}

// load-time initialization
(new AllNotesOffOp) @=> VoxController.ALL_NOTES_OFF_OP;
(new NoteOffOp) @=> VoxController.NOTE_OFF_OP;
(new AllNotesSilentOp) @=> VoxController.ALL_NOTES_SILENT_OP;
(new NoteSilentOp) @=> VoxController.NOTE_SILENT_OP;
(new FindAnyOp) @=> VoxController.FIND_ANY_OP;
(new FindAvailableOp) @=> VoxController.FIND_AVAILABLE_OP;
(new FindTaggedOp) @=> VoxController.FIND_TAGGED_OP;
