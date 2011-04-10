// Operation -- generalized function.
//
// Robert Poor <r@alum.mit.edu>
// ==== Revision History
// 091202_191427:	Created
// 100110_210744:	Renamed from QueueOp to Operation
// ====

public class Operation {
    // Operation is an object passed to the Queue.apply() method.
    // Operation.apply(element, argument) is called repeatedly for
    // each element of the Queue.  If the method returns a non-null
    // value, iteration stops and Queue.apply() returns that value.
    fun Object apply(Object element, Object argument) { return null; }
}
