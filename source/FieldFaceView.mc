import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Inverted classic field-watch face for the Garmin Venu 4 (45mm, 454x454).
// WITH_WIDGET (set per build in source-widget/ or source-plain/Config.mc):
//   true  -> dial has no "3"; live day/date wheel drawn at 3 o'clock.
//   false -> dial shows the "3" numeral; no widget.
// All widget glyphs are pre-rotated, black-background bitmaps drawn with plain drawBitmap
// (Connect IQ transparency is 1-bit and runtime bitmap rotation is unreliable, so both are baked).
class FieldFaceView extends WatchUi.WatchFace {

    private const HAND_HOUR = [[0.0, -42.39535], [-2.11666, -39.54282], [-2.64583, 7.24865],
                              [0.0, 9.47022], [2.64584, 7.24865], [2.11667, -39.54282]];
    private const HAND_MIN  = [[0.0, -60.46246], [-1.608669, -57.29831], [-2.010831, 7.88272],
                              [0.0, 9.47022], [2.010831, 7.88272], [1.608669, -57.29831]];  // 0.76x
    private const MM = 71.650894;

    // widget geometry (native 454 px; device is 454x454)
    private const RDAY  = 0.4592;
    private const RDATE = 0.6409;
    private const DANG  = 0.1753;     // rad
    private const ROT   = 10.04;      // deg
    private const GAP   = 1.0;
    private const UPW = [13.00, 3.00, 10.50, 10.25, 12.00, 11.00, 11.25, 10.25, 11.50, 11.25];  // upright digit widths (original glyphs)

    private var _bg as BitmapResource?;
    private var _days as Array<BitmapResource>?;
    private var _digC as Array<BitmapResource>?;
    private var _digT as Array<BitmapResource>?;
    private var _digB as Array<BitmapResource>?;
    private var _lowPower as Boolean = false;

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc as Dc) as Void {
        _bg = WatchUi.loadResource(Rez.Drawables.DialBackground) as BitmapResource;
        if (WITH_WIDGET) {
            _days = [ WatchUi.loadResource(Rez.Drawables.day_mon), WatchUi.loadResource(Rez.Drawables.day_tue),
                      WatchUi.loadResource(Rez.Drawables.day_wed), WatchUi.loadResource(Rez.Drawables.day_thu),
                      WatchUi.loadResource(Rez.Drawables.day_fri), WatchUi.loadResource(Rez.Drawables.day_sat),
                      WatchUi.loadResource(Rez.Drawables.day_sun) ] as Array<BitmapResource>;
            _digC = [ WatchUi.loadResource(Rez.Drawables.dig_c_0), WatchUi.loadResource(Rez.Drawables.dig_c_1),
                      WatchUi.loadResource(Rez.Drawables.dig_c_2), WatchUi.loadResource(Rez.Drawables.dig_c_3),
                      WatchUi.loadResource(Rez.Drawables.dig_c_4), WatchUi.loadResource(Rez.Drawables.dig_c_5),
                      WatchUi.loadResource(Rez.Drawables.dig_c_6), WatchUi.loadResource(Rez.Drawables.dig_c_7),
                      WatchUi.loadResource(Rez.Drawables.dig_c_8), WatchUi.loadResource(Rez.Drawables.dig_c_9) ] as Array<BitmapResource>;
            _digT = [ WatchUi.loadResource(Rez.Drawables.dig_t_0), WatchUi.loadResource(Rez.Drawables.dig_t_1),
                      WatchUi.loadResource(Rez.Drawables.dig_t_2), WatchUi.loadResource(Rez.Drawables.dig_t_3),
                      WatchUi.loadResource(Rez.Drawables.dig_t_4), WatchUi.loadResource(Rez.Drawables.dig_t_5),
                      WatchUi.loadResource(Rez.Drawables.dig_t_6), WatchUi.loadResource(Rez.Drawables.dig_t_7),
                      WatchUi.loadResource(Rez.Drawables.dig_t_8), WatchUi.loadResource(Rez.Drawables.dig_t_9) ] as Array<BitmapResource>;
            _digB = [ WatchUi.loadResource(Rez.Drawables.dig_b_0), WatchUi.loadResource(Rez.Drawables.dig_b_1),
                      WatchUi.loadResource(Rez.Drawables.dig_b_2), WatchUi.loadResource(Rez.Drawables.dig_b_3),
                      WatchUi.loadResource(Rez.Drawables.dig_b_4), WatchUi.loadResource(Rez.Drawables.dig_b_5),
                      WatchUi.loadResource(Rez.Drawables.dig_b_6), WatchUi.loadResource(Rez.Drawables.dig_b_7),
                      WatchUi.loadResource(Rez.Drawables.dig_b_8), WatchUi.loadResource(Rez.Drawables.dig_b_9) ] as Array<BitmapResource>;
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        var w = dc.getWidth();
        var cx = w / 2.0;
        var cy = w / 2.0;
        var rs = w / 2.0;
        var k  = rs / MM;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (_bg != null) { dc.drawBitmap(0, 0, _bg); }

        if (WITH_WIDGET) { drawDayDate(dc, cx, cy, rs); }

        var clock = System.getClockTime();
        var hour = clock.hour % 12;
        var min  = clock.min;
        var sec  = clock.sec;
        drawHand(dc, HAND_HOUR, Math.toRadians((hour + min / 60.0) * 30.0), cx, cy, k);
        drawHand(dc, HAND_MIN,  Math.toRadians((min + sec / 60.0) * 6.0),  cx, cy, k);
        if (!_lowPower) { drawSecondHand(dc, Math.toRadians(sec * 6.0), cx, cy, rs); }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, rs * 0.029);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, rs * 0.011);
    }

    function drawDayDate(dc as Dc, cx as Float, cy as Float, rs as Float) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var dow = info.day_of_week;                          // 1=Sun .. 7=Sat
        var today = info.day;
        var tomorrow  = Gregorian.info(now.add(new Time.Duration(86400)),      Time.FORMAT_SHORT).day;
        var yesterday = Gregorian.info(now.subtract(new Time.Duration(86400)), Time.FORMAT_SHORT).day;

        var days = _days as Array<BitmapResource>;
        var dayBmp = days[(dow + 5) % 7];
        dc.drawBitmap(cx + RDAY * rs - dayBmp.getWidth() / 2.0, cy - dayBmp.getHeight() / 2.0, dayBmp);

        var rd = RDATE * rs;
        drawNumber(dc, tomorrow,  cx + rd * Math.sin(Math.PI/2 - DANG), cy - rd * Math.cos(Math.PI/2 - DANG),  ROT, _digT as Array<BitmapResource>);
        drawNumber(dc, today,     cx + rd,                              cy,                                     0.0, _digC as Array<BitmapResource>);
        drawNumber(dc, yesterday, cx + rd * Math.sin(Math.PI/2 + DANG), cy - rd * Math.cos(Math.PI/2 + DANG), -ROT, _digB as Array<BitmapResource>);
    }

    // place a date value from pre-rotated per-digit bitmaps along the (rotated) baseline
    function drawNumber(dc as Dc, value as Number, ncx as Float, ncy as Float, deg as Float, bmps as Array<BitmapResource>) as Void {
        var s = value.toString();
        var n = s.length();
        var total = GAP * (n - 1);
        for (var i = 0; i < n; i++) { total += UPW[s.substring(i, i + 1).toNumber()]; }
        var th = -Math.toRadians(deg);
        var cs = Math.cos(th); var sn = Math.sin(th);
        var run = 0.0;
        for (var i = 0; i < n; i++) {
            var dgt = s.substring(i, i + 1).toNumber();
            var wd = UPW[dgt];
            var rel = (run + wd / 2.0) - total / 2.0;
            run += wd + GAP;
            var wx = ncx + rel * cs;
            var wy = ncy + rel * sn;
            var b = bmps[dgt];
            dc.drawBitmap(wx - b.getWidth() / 2.0, wy - b.getHeight() / 2.0, b);
        }
    }

    function drawHand(dc as Dc, pts as Array, ang as Float, cx as Float, cy as Float, k as Float) as Void {
        var c = Math.cos(ang); var s = Math.sin(ang);
        var poly = new Array<[Numeric, Numeric]>[pts.size()];
        for (var i = 0; i < pts.size(); i++) {
            var mx = pts[i][0] * k; var my = pts[i][1] * k;
            poly[i] = [cx + mx * c - my * s, cy + mx * s + my * c];
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(poly);
    }

    function drawSecondHand(dc as Dc, ang as Float, cx as Float, cy as Float, rs as Float) as Void {
        var ux = Math.sin(ang); var uy = -Math.cos(ang);
        var vx = -uy; var vy = ux;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx, cy, cx + ux * 0.817 * rs, cy + uy * 0.817 * rs);
        var d  = 0.21821 * rs; var rc = 0.0504 * rs;
        var pcx = cx - ux * d; var pcy = cy - uy * d;
        dc.drawLine(cx, cy, pcx, pcy);
        dc.drawCircle(pcx, pcy, rc);
        var tTop = -0.10 * rc; var tBot = 1.00 * rc;
        var innerR = rc - 1.0;                                          // pen width = 2
        var cbHalf = Math.sqrt(innerR * innerR - (0.10 * rc + 1.0) * (0.10 * rc + 1.0));
        var bx = pcx + ux * tTop; var by = pcy + uy * tTop;
        dc.drawLine(bx + vx * cbHalf, by + vy * cbHalf, bx - vx * cbHalf, by - vy * cbHalf);
        dc.drawLine(bx, by, pcx + ux * tBot, pcy + uy * tBot);
    }

    function onEnterSleep() as Void { _lowPower = true; WatchUi.requestUpdate(); }
    function onExitSleep() as Void { _lowPower = false; WatchUi.requestUpdate(); }
}
