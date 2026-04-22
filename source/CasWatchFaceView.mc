import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class CasWatchFaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function formatDate() as String {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dd = today.day < 10 ? "0" + today.day.toString() : today.day.toString();
        var mm = today.month < 10 ? "0" + today.month.toString() : today.month.toString();
        return dd + "-" + mm;
    }

    // Returns the HH:MM time at a given UTC offset (in minutes).
    function formatAltTimezone(offsetMinutes as Number) as String {
        var utc = Gregorian.utcInfo(Time.now(), Time.FORMAT_SHORT);
        var totalMins = ((utc.hour * 60 + utc.min + offsetMinutes) % 1440 + 1440) % 1440;
        var h = totalMins / 60;
        var m = totalMins % 60;
        var hh = h < 10 ? "0" + h.toString() : h.toString();
        var mm = m < 10 ? "0" + m.toString() : m.toString();
        return hh + ":" + mm;
    }

    function toThousands(nbr as Number?) as String {
        var res;
        if (nbr == null) {
            res = "--";
        } else if (nbr >= 1000) {
            res = (nbr / 1000).toString() + "." + ((nbr % 1000) / 100).toString() + "K";
        } else {
            res = nbr.toString();
        }
        while(res.length() < 2) {
            res = "0" + res;
        }
        return res;
    }

    function writeToLED(fieldId as String, value as String) {
        var mask = "";
        for (var i = 0; i < value.length(); i++) { mask += "$"; }
        (View.findDrawableById(fieldId + "Bg") as Text).setText(mask);
        (View.findDrawableById(fieldId) as Text).setText(value);
    }

    function getWeekDayPosition() as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var pos = [68, 100, 132, 161, 194, 221, 247];
        System.println(today.day_of_week);
        return pos[today.day_of_week - 1];
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;

        var altOffset = Application.Properties.getValue("AltTimezoneOffset") as Number?;

        var dateStr = (altOffset != null && altOffset != -9999)
            ? formatAltTimezone(altOffset)
            : formatDate();
        (View.findDrawableById("DateLabel") as Text).setText(dateStr);

        var wdText = (View.findDrawableById("WeekDayLabel") as Text);
        wdText.setLocation(getWeekDayPosition(), wdText.locY);

        var altDateStr = (altOffset != null && altOffset != -9999)
            ? formatDate()
            : "";
        (View.findDrawableById("AltDateLabel") as Text).setText(altDateStr);

        // Format time as HH:MM
        var timeStr = (hour / 10).toString() + (hour % 10).toString() + ":" +
                      (minute / 10).toString() + (minute % 10).toString();
        (View.findDrawableById("TimeLabel") as Text).setText(timeStr);

        var info = ActivityMonitor.getInfo();
        writeToLED("StepsValLabel",toThousands(info.steps));
        writeToLED("FloorsValLabel",toThousands(info.floorsClimbed));

        var notifications = System.getDeviceSettings().notificationCount;
        var notifStr = (notifications > 0) 
            ? toThousands(notifications)
            : "--";
        writeToLED("NotifsValLabel",notifStr);
        
        var battery = System.getSystemStats().battery;
        (View.findDrawableById("BatteryLabel") as Text).setVisible(battery <= 5);

        // Draw background and labels
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
