// FarfisaVoxController: manage FarfisaVox objects
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091203_131731: Initial Version
// ====


public class FarfisaVoxController extends VoxController {

    // The only method that needs to be shadowed...
    fun Vox allocate_vox() { return new FarfisaVox; }

}
