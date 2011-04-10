// Dispatcher: the sending part of Dispatcher/Msg/Observer pattern.
// 
// Dispatcher is a transmitter of messages: dispatcher.notify(msg)
// will generate a call to observer.update(msg) on all attached
// observers.
//
// TODO: Add a method (for subclassing) that gets called when the
// observer count changes.  This would allow a subclass to (e.g.)
// disconnect its source when there are no observers left.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_125100: Moved static initializers to end of file
// 100110_211355: Rename of QueueOp to Operation
// 100117_050231: partitioned Observable and Dispatcher classes, added 
//		  Observable arg to notify(observable, msg)
// 100118_003531: Added observer_count_changed() method.
// ====

public class Dispatcher extends Observable {
    // ================================================================
    // Class constants

    // ================================================================
    // Instance variables

    Queue _observers;
    
    // ================================================================
    // Instance methods
    
    fun int count() { return _observers.size(); }

    fun int is_attached(Observer observer) {
	return _observers.is_member(observer);
    }

    fun Observer attach(Observer observer) {
        if (is_attached(observer)) return null;
	(_observers.push(observer) $ Observer) @=> Observer @ o;
	observer_count_changed(_observers.size());
	return o;
    }

    fun Observer detach(Observer observer) {
	_observers.index_of(observer) => int index;
	if (index == Queue.NOT_FOUND) return null;
	(_observers.remove_at(index) $ Observer) @=> Observer @ o;
	observer_count_changed(_observers.size());
	return o;
    }

    fun Dispatcher detach_all() { 
	_observers.clear(); 
	return observer_count_changed(_observers.size());
    }

    // Call observer.update(this, message) on each attached observer
    fun Observable notify(Msg msg) {
	Util.trace(this, "notify("+msg.toString()+")[1]");
	for (0=>int i; i<_observers.size(); i++) {
	    (_observers.ref(i) $ Observer) @=> Observer @ o;
	    Util.trace(this, "notify("+o.toString()+","+msg.toString()+")[2_"+i+"]");
	    o.update(this, msg);
	}
	Util.trace(this, "notify("+msg.toString()+")[3]");
	return this;
    }

    // To be subclassed.  Called when observer count changes.
    fun Dispatcher observer_count_changed(int new_count) { return this; }
	
}
