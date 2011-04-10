// Observer: the receiver in the Dispatcher/Msg/Observer pattern.
// 
// The generic Observer has no effect of its own -- any functionality
// will be provided by subclasses of Observer.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100117_043711: add Observable arg to update()
// ====

public class Observer {
    fun void update(Observable o, Msg m) { 
	<<< now, me, this.toString(), ".update[generic](", o.toString(), m.toString(), ")" >>>;
    }
}

