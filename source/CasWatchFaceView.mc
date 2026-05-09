import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class CasWatchFaceView extends WatchUi.WatchFace {
    hidden var lastSlowUpdate as Number? = null;
    hidden var weather as Dictionary = {};

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
            res = (nbr / 1000).toString() + "." + ((nbr % 1000) / 100).toString() + "k";
        } else {
            res = nbr.toString();
        }
        return res;
    }

    function padNumber(nbr as String) {
        return nbr.length() < 2 ? "0" + nbr : nbr;
    } 
    
    function writeToLED(fieldId as String, value as String) {
        var mask = "";
        for (var i = 0; i < value.length(); i++) { mask += "$"; }
        (View.findDrawableById(fieldId + "Bg") as Text).setText(mask);
        (View.findDrawableById(fieldId) as Text).setText(value);
    }

    function getWeekDayPosition() as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var pos = [77, 113, 140, 175, 204, 233, 258];
        return pos[today.day_of_week - 1];
    }
    
    function updateWeather() {
        var cc = Weather.getCurrentConditions();
        var loc = cc.observationLocationPosition;
        if (cc != null) {
            var now = Time.now();
            weather["Temp"] = cc.temperature as Number;
            weather["WindBear"] = cc.windBearing as Number;
            weather["WindSpeed"] = cc.windSpeed as Number;
            weather["Rain"] = cc.precipitationChance as Number;
            weather["Night"] = false;
            if (loc != null) {
                var sunrise = Weather.getSunrise(loc, now);
                var sunset = Weather.getSunset(loc, now);
                if (sunrise.lessThan(now)) { 
                    //if sunrise was already, take tomorrows
                    sunrise = Weather.getSunrise(loc, Time.today().add(new Time.Duration(86401)));
                } else {
                    weather["Night"] = true;
                }
                if (sunset.lessThan(now)) { 
                    //if sunset was already, take tomorrows
                    weather["Night"] = true;
                    sunset = Weather.getSunset(loc, Time.today().add(new Time.Duration(86401)));
                }
                weather["Sunrise"] = sunrise;
                weather["Sunset"] = sunset;
            } else {
                weather["Sunrise"] = null;
                weather["Sunset"] = null;
            }
        }
    }

    function getWindChar(windBear as Number) as String {
        var aux = (windBear + 23) % 360;
        if (aux < 45) { return "e"; }
        if (aux >= 45 && aux < 90) { return "f"; }
        if (aux >= 90 && aux < 135) { return "g"; }
        if (aux >= 135 && aux < 180) { return "h"; }
        if (aux >= 180 && aux < 225) { return "a"; }
        if (aux >= 225 && aux < 270) { return "b"; }
        if (aux >= 270 && aux < 315) { return "c"; }
        if (aux >= 315 && aux < 360) { return "d"; }
        return "-";
    }

    function formatSunTime(moment as Time.Moment?) as String {
        if (moment == null) { return "--:--"; }
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var hh = info.hour < 10 ? "0" + info.hour.toString() : info.hour.toString();
        var mm = info.min < 10 ? "0" + info.min.toString() : info.min.toString();
        return hh + ":" + mm;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var unix_timestamp = Time.now().value();

        if(clockTime.sec % 60 == 0 or lastSlowUpdate == null or unix_timestamp - lastSlowUpdate >= 60) {
            lastSlowUpdate = unix_timestamp;
            updateWeather();
        }

        var colorTheme = Application.Properties.getValue("ColorTheme") as Number?;
        var isNight;
        if (colorTheme == 1) {
            isNight = false;
        } else if (colorTheme == 2) {
            isNight = true;
        } else {
            isNight = weather["Night"] as Boolean?;
        }
        if (isNight != null) {
            var textColor = isNight ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_BLACK;
            (View.findDrawableById("Background") as Bitmap).setVisible(!isNight);
            (View.findDrawableById("BackgroundDark") as Bitmap).setVisible(isNight);
            (View.findDrawableById("WeekDayLabel") as Text).setColor(textColor);
            (View.findDrawableById("DateLabel") as Text).setColor(textColor);
            (View.findDrawableById("TimeLabel") as Text).setColor(textColor);
        }

        if (weather["Temp"] != null) {
            var tempData = weather["Temp"].format("%d") + "ª";
            if (weather["WindSpeed"] != null && weather["WindBear"] != null) {
                tempData += weather["WindSpeed"].format("%d") + getWindChar(weather["WindBear"]) ;
            }
            if (weather["Rain"] != null) {
                tempData += weather["Rain"] + "%";
            }
            writeToLED("WeatherLabel",tempData);
        }

        var altOffset = Application.Properties.getValue("AltTimezoneOffset") as Number?;

        if (altOffset != null && altOffset != -9999) {
            (View.findDrawableById("AltTimeLabel") as Text).setText("TIME");
            writeToLED("AltTime",formatAltTimezone(altOffset));    
        } else {
            if (weather["Sunrise"].lessThan(weather["Sunset"])) {
                (View.findDrawableById("AltTimeLabel") as Text).setText("SUNRISE");
                writeToLED("AltTime",formatSunTime(weather["Sunrise"]));
            } else {
                (View.findDrawableById("AltTimeLabel") as Text).setText("SUNSET");
                writeToLED("AltTime",formatSunTime(weather["Sunset"]));
            }
        }

        (View.findDrawableById("DateLabel") as Text).setText(formatDate());

        var wdText = (View.findDrawableById("WeekDayLabel") as Text);
        wdText.setLocation(getWeekDayPosition(), wdText.locY);

        // Format time as HH:MM
        var timeStr = (hour / 10).toString() + (hour % 10).toString() + ":" +
                      (minute / 10).toString() + (minute % 10).toString();
        (View.findDrawableById("TimeLabel") as Text).setText(timeStr);

        var info = ActivityMonitor.getInfo();
        writeToLED("StepsValLabel",padNumber(toThousands(info.steps)));
        writeToLED("FloorsValLabel",padNumber(toThousands(info.floorsClimbed)));

        var notifications = System.getDeviceSettings().notificationCount;
        var notifStr = (notifications > 0) 
            ? toThousands(notifications)
            : "--";
        writeToLED("NotifsValLabel",padNumber(notifStr));
        
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
