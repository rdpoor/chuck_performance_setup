// Util: a collection of utility functions
// 
// ==== Authors:
// Robert Poor <r@alum.mit.edu>
// ==== Revision History:
// 091202_191949: Initial Version
// 100110_011440: Added lerp(dur ...)
// ====

public class Util {

    false => static int IS_TRACING;

    // we assume that util.ck is loaded first thing, so we are
    // able to capture now == 0.
    now => static time TIME_ZERO;

    // linear interpolation: as x ranges from x0 to x1, f(x) ranges
    // from y0 to y1.
    fun static float lerp(float x, float x0, float x1, float y0, float y1) {
	return y0 + (x - x0) * (y1 - y0) / (x1 - x0);
    }

    // Same thing, but assumes x has the range of 0.0 ... 1.0
    fun static float lerp(float x, float y0, float y1) {
	// return lerp(x, 0.0, 1.0, y0, y1);
	return y0 + x * (y1 - y0);
    }

    // same thing, but X is time
    fun static float lerp(time t, time t0, time t1, float y0, float y1) {
	return y0 + (t - t0) * (y1 - y0) / (t1 - t0);
    }

    // same thing, but X is duration
    fun static float lerp(dur d, dur d0, dur d1, float y0, float y1) {
	return y0 + (d - d0) * (y1 - y0) / (d1 - d0);
    }

    // positive modulo: result is in the range of 0 ... y-1
    fun static int mod(int x, int y) {
	x % y => x;
	if (x < 0) { y +=> x; }
	return x;
    }

    // ...because I don't agree with ChucK's MIDI-centric version
    fun static float db_to_ratio(float db) { return Math.pow(10.0, db * 0.1); }
    fun static float ratio_to_db(float ratio) {	return 10 * Math.log10(ratio); }

    fun static float quantize(float x, float strength) {
	return x + strength * (Math.round(x) - x);
    }

    fun static string to_s(dur d) {
	d / 1::samp => float samples;
	return "" + samples;
    }

    fun static string to_s(time t) { return to_s(t - TIME_ZERO); }

    fun static int is_tracing() { return IS_TRACING; }

    fun static void trace(string msg) {
	if (IS_TRACING) {
	    <<< now, me, "[toplevel]", msg >>>;
	}
    }

    fun static void trace(Object o, string msg) {
	if (IS_TRACING) {
	    <<< now, me, o.toString(), msg >>>;
	}
    }

}

