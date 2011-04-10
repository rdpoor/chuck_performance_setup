// semaphore.ck -- wait until a specific time arrives or an external
// signal is generated, whichever comes first.
//
// Sample Usage ===================================================
// class TickleSignal extends Object {}
// TickleSignal tickle_signal;
// Semaphore semaphore;
//
// repeat(10) {
//     now + 2::second => time test_end_time;
//     spork ~ tickler_proc();
//     semaphore.wait_for(1::second) @=> Object @ cause;
//     <<< "semaphore woke due to", cause.toString() >>>;
//     test_end_time => now;
// }
//
// fun void tickler_proc() { 
//     Std.rand2f(0.0, 2.0)::second => now;
//     semaphore.signal(tickle_signal);
// }
//
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100109_125100: Moved static initializers to end of file
// ====

// TimedOut is used as the <cause> argument for signal() when
// the semaphore wakes due to timeout.  While it's not neccessary to
// define a custom class -- any object can be used as the <cause>
// argument to signal() -- a custom class has the nice property that
// .toString() will print out the class name.  See Sample Usage above
// to see how a custom class may be used as the argument to signal().
class TimedOut extends Object {};

// ================================================================
// ================================================================
// The Semaphore class supports waiting for an external signal or a
// timeout.
public class Semaphore {

    // ================================================================
    // class constants

    // an "impossible" time.
    now - 1::samp => static time NEVER;

    // TIMED_OUT is the default value returned by wait() to indicate
    // that the wait() was terminated by timeout rather than by a user
    // signal.
    static TimedOut @ TIMED_OUT; 

    // ================================================================
    // class methods

    // ChucK 1.2.1.3 exhibits scheduling bugs when passed time values
    // with non-zero fractional parts.  truncate_time() removes the
    // fractional part to work around the bug.  (See set_timeout(t)
    // for usage.)
    fun static time truncate_time(time t) { return t - (t % samp); }

    // ================================================================
    // instance variables

    Object @ _signal_cause;     // argment passed to signal(), returned by wait()
    time _timeout_time;         // argument passed to most recent set_timeout()
    Event _event;               // event used for blocking in wait()

    // ================================================================
    // public instance methods

    // ================ 
    // wait() blocks until someone calls signal(cause).  It then
    // returns the cause argument.
    fun Object wait() {
        _event => now;          // wait here for call to signal()
        return _signal_cause;
    }

    // ================
    // signal(cause) signals the semaphore, allowing it to return from
    // a call to wait() with the given cause.
    fun Semaphore signal(Object cause) {
        cause @=> _signal_cause; // remember the cause of the signal
        clear_timeouts();        // inhibit pending timeouts
        _event.broadcast();      // unblock the wait()
        me.yield();              // allow wait()'ing thread to run
        return this;
    }

    // ================
    // set_timeout(time) generates a call to signal(TIMED_OUT) in the
    // future.  If <time> has already passed, no timeout is set and
    // set_timeout() returns null.
    fun Semaphore set_timeout(dur d) { return set_timeout(now + d, TIMED_OUT); }
    fun Semaphore set_timeout(dur d, Object cause) { return set_timeout(now+d, cause); }
    fun Semaphore set_timeout(time t) { return set_timeout(t, TIMED_OUT); }
    fun Semaphore set_timeout(time t, Object cause) {
        // NOTE: see comment under truncate_time() about ChucK bug workaround
        if ((truncate_time(t) => _timeout_time) <= now) return null;
        spork ~ _timeout_proc(_timeout_time, cause);
        me.yield();
        return this;
    }

    // ================
    // clear_timeouts() prevents any pending timeouts from generating
    // a signal().
    //
    // Implementation note: each call to set_timeout() spawns a new
    // _timeout_proc().  In ChucK, once a proc is spawned, it cannot
    // be killed or interrupted.  To prevent spurious calls to
    // signal(), we set _timeout_time to an "impossible" value (i.e. a
    // time in the past) to inhibit the generation of the signals --
    // see the implementation of _timeout_proc() to see why this
    // works.
    fun Semaphore clear_timeouts() {
	NEVER => _timeout_time;
        return this;
    }

    // ================
    // wait_for() and wait_until() combine a call to set_timeout()
    // followed by a wait(): they will block until the desired time
    // arrives OR until <this>.signal() is called from another thread,
    // whichever comes first.
    fun Object wait_for(dur d) { return wait_until(now + d, TIMED_OUT); }
    fun Object wait_for(dur d, Object cause) { return wait_until(now + d, cause); }
    fun Object wait_until(time t) { return wait_until(t, TIMED_OUT); }
    fun Object wait_until(time t, Object cause) { 
        if (set_timeout(t, cause) == null) {
            return cause; // don't wait() if time already passed
        } else {
            return this.wait();
        }
    }

    // ================================================================
    // private methods

    // _timeout_proc() is spawned in its own thread at each call to
    // set_timeout().  It blocks until the requested time, and if the
    // timeout is still current (i.e. now == _timeout_time), it calls
    // <this>.signal(timeout_cause) to unblock the wait().
    fun void _timeout_proc(time t, Object timeout_cause) {
	Util.trace(this, "_timeout_proc(" + timeout_cause.toString() + ")[1]");
        t => now;                     // wait until the time arrives
        // Signal the Semaphore only if this timeout is current
        if (now == _timeout_time) {
	    Util.trace(this, "_timeout_proc(" + timeout_cause.toString() + ")[2]");
	    this.signal(timeout_cause); 
	}
	Util.trace(this, "_timeout_proc(" + timeout_cause.toString() + ")[3]");
    }

}

// load-time initialization
new TimedOut @=> Semaphore.TIMED_OUT;
