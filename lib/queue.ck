// Queue: general implementation of variable size collection.
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// ====

public class Queue {

    -1 => static int NOT_FOUND;

    // ================================================================
    // instance variables

    Object @ _elements[0];

    // ================================================================
    // public methods

    // Remove all objects from the Queue
    fun void clear() { _elements.size(0); }

    // Return the number of objects in the Queue
    fun int size() { return _elements.size(); }

    // Return an array reference to the obects (use with caution)
    fun Object[] elements() { return _elements; }

    // Return the index of Object o the in the Queue, or NOT_FOUND if
    // o is not in the Queue.  If there are multiple identical
    // objects, returns the index of the first.
    fun int index_of(Object o) {
        for (0=>int i; i<_elements.size(); i++) {
            if (_elements[i] == o) return i;
        }
        return NOT_FOUND;
    }
       
    // Returns true if the object is in the Queue.
    fun int is_member(Object o) { return (index_of(o) != NOT_FOUND); }

    // Fetch the nth object in the Queue, silently returning null if
    // index is out of range.
    fun Object ref(int index) {
	if ((index < 0) || (index >= _elements.size())) return null;
	return _elements[index];
    }
	
    // Add an object at the end of the Queue.
    fun Object push(Object o) {
	// Implementation note: ChucK release notes suggests that the
	// << operator is buggy, so we push an object "the hard way"
	_elements.size() => int size;
	_elements.size(size+1);
	o @=> _elements[size];
	return o;
    }

    // Remove the last object from the queue.  Silently returns 
    // null if the queue is empty at the time of the call.
    fun Object pop() {
	_elements.size() - 1 => int last;
	if (last < 0) return null;
	_elements[last] @=> Object @ o;
	_elements.size(last);
	return o;
    }

    // Remove the object from the Queue with the given index.
    // Silently returns null if index is out of range.
    fun Object remove_at(int index) {
	ref(index) @=> Object @ o;
	if (o == null) return null;
	for (index+1 => int i; i<_elements.size(); i++) {
	    _elements[i] @=> _elements[i-1];
	}
	_elements.size(_elements.size()-1);
	return o;
    }

    // Insert an object at the index'th slot in the Queue, returning
    // null if the index is out of range.
    fun Object insert_at(Object o, int index) {
	_elements.size() => int size;
	if ((index < 0) || (index > size))  return null;
	// expand array, open a hole at index, insert object
	_elements.size(size+1);
	for (size => int i; i>index; i--) { 
	    _elements[i-1] @=> _elements[i]; 
	}
	o @=> _elements[index];
	return o;
    }

    // Return the index of the first match, or - insertion_point - 1
    // if the object is not in the queue.  You can use insertion_point
    // to insert the object as follows:
    //    queue.search(obj, cmp) => int i;
    //    if (i >= 0) {
    //      // obj found at i
    //    } else {
    //      // obj not found...insert
    //      queue.insert_at(o, -i-1)
    //    }
    fun int search(Object o, Comparison comparison) {
	0 => int lo;		    // inclusive low bound
	_elements.size() => int hi; // exclusive high bound
	while (lo < hi) {
	    (lo + hi) / 2 => int mid;
	    comparison.compare(o, _elements[mid]) => int cmp;
	    if (cmp < 0) {
		mid => hi;
	    } else if (cmp > 0) {
		mid + 1 => lo;
	    } else {
		return mid;
	    }
	}
	return -(lo + 1);
    }

    // Call op.apply() on each element of the queue.  If op returns a
    // non-null value, cease iteration and return that value.
    fun Object apply(Operation op) { return apply(op, null); }
    fun Object apply(Operation op, Object argument) {
	for (0=>int i; i<_elements.size(); i++) {
	    if (Util.is_tracing()) Util.trace(this, ".apply(" + i + ")");
	    op.apply(_elements[i], argument) @=> Object o;
	    if (o != null) return o;
	}
	return null;
    }


}