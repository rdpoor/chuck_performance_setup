// NoseVoxController: manage NoseVox objects
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091208_205659: Initial Version
// ====

public class NoseVoxController extends VoxController {
    fun Vox allocate_vox() { return new NoseVox; }
}
