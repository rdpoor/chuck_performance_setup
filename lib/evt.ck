public class Evt extends Msg {

    (null $ Evt) @=> static Evt @ NULL_EVT;
    Util.TIME_ZERO => static time TIME_ZERO;

    time _time;

    fun time get_time() { return _time; }

}
