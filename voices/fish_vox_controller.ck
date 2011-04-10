// FishVoxController: manage FishVox objects
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 100318_221250: Initial Version
// ====


public class FishVoxController extends VoxController {

    // The only method that needs to be shadowed...
    fun Vox allocate_vox() { return new FishVox; }

}
