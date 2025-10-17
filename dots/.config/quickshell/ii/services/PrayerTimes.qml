pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string city: Config.options.bar.prayerTimes.city
    property string country: Config.options.bar.prayerTimes.country
    property bool isAdhanPlaying: false
    property var filePath: `${FileUtils.trimFileProtocol(Directories.state)}/user/generated/prayertimes.json`
    property bool dataLoaded: false
    property bool isLoading: false

    property var prayerData: ({
            "nextPrayerName": null,
            "nextPrayerTime": null,
            "hijriDate": null,
            "sunrise": null,
            "sunset": null,
            "fajr": null,
            "dhuhr": null,
            "asr": null,
            "maghrib": null,
            "isha": null
        })

    signal adhanPlaying(string prayerName)

    function parseTime(timeStr) {
        if (!timeStr || timeStr.indexOf(':') < 0)
            return null;
        const parts = timeStr.split(':');
        const date = new Date();
        date.setHours(parseInt(parts[0], 10));
        date.setMinutes(parseInt(parts[1], 10));
        date.setSeconds(0);
        date.setMilliseconds(0);
        return date;
    }

    function fetchPrayerTimes() {
        root.isLoading = true;
        const now = new Date();
        const dateToday = `${String(now.getDate()).padStart(2, '0')}-${String(now.getMonth() + 1).padStart(2, '0')}-${now.getFullYear()}`;
        const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

        const apiUrl = `https://api.aladhan.com/v1/timingsByCity/${dateToday}?city=${city}&country=${country}&method=2`;

        const jqCommand = `( .data.timings | {Fajr, Dhuhr, Asr, Maghrib, Isha} | to_entries | map({name: .key, time: .value}) ) as $prayers | ( [ $prayers[] | select(.time > "${currentTime}") ] | if length > 0 then .[0] else $prayers[0] end ) as $nextPrayer | .data += {nextPrayerName: $nextPrayer.name, nextPrayerTime: $nextPrayer.time} | {data: {timings: .data.timings, date: {hijri: .data.date.hijri, gregorian: .data.date.gregorian}, nextPrayerName: .data.nextPrayerName, nextPrayerTime: .data.nextPrayerTime}}`;

        const command = `tmp_file=$(mktemp) && curl -X GET "${apiUrl}" -s | jq '${jqCommand}' > "$tmp_file" && if [ -s "$tmp_file" ]; then mv "$tmp_file" "${root.filePath}"; else rm "$tmp_file"; fi`;

        Quickshell.execDetached(["bash", "-c", command]);
    }

    // FileView to read the prayer times file
    FileView {
        id: prayerTimesFileView
        path: root.filePath

        onLoaded: {
            var textContent = "";
            try {
                textContent = text();
                if (textContent.trim() === "") {
                    fetchPrayerTimes();
                    return;
                }
                var jsonData = JSON.parse(textContent);

                if (!jsonData.data || !jsonData.data.date || !jsonData.data.date.gregorian || !jsonData.data.date.gregorian.date) {
                    fetchPrayerTimes();
                    return;
                }

                const fileDateStr = jsonData.data.date.gregorian.date; // "DD-MM-YYYY"
                const parts = fileDateStr.split('-');
                const fileDate = new Date(parseInt(parts[2], 10), parseInt(parts[1], 10) - 1, parseInt(parts[0], 10));

                const now = new Date();
                now.setHours(0, 0, 0, 0);
                fileDate.setHours(0, 0, 0, 0);

                if (fileDate.getTime() < now.getTime()) {
                    fetchPrayerTimes();
                } else {
                    processPrayerData(jsonData);
                }
            } catch (e) {
                root.isLoading = false;
                fetchPrayerTimes();
            }
        }

        onLoadFailed: error => {
            root.isLoading = false;
            fetchPrayerTimes();
        }
    }

    Timer {
        id: nextPrayerTimer
        repeat: false
        onTriggered: {
            if (Config.options.sounds.adhan && !isAdhanPlaying && dataLoaded && root.prayerData.nextPrayerTime) {
                const now = new Date();
                if (now.getTime() >= root.prayerData.nextPrayerTime.getTime() - 1000) { // 1 second buffer
                    playAdhan(root.prayerData.nextPrayerName);
                }
            }
        }
    }

    function scheduleNextPrayerCheck() {
        if (!dataLoaded || !prayerData.nextPrayerTime) {
            nextPrayerTimer.stop();
            return;
        }

        const now = new Date();
        const nextPrayerTime = prayerData.nextPrayerTime;

        if (nextPrayerTime > now) {
            const interval = nextPrayerTime.getTime() - now.getTime();
            nextPrayerTimer.interval = interval;
            nextPrayerTimer.start();
        } else {
            nextPrayerTimer.stop();
        }
    }

    function processPrayerData(data) {
        if (!data || !data.data) {
            root.isLoading = false;
            return;
        }

        if (!data.data.timings) {
            root.isLoading = false;
            return;
        }

        const timings = data.data.timings;
        const hijri = data.data.date.hijri;

        let newPrayerData = {
            "fajr": parseTime(timings.Fajr),
            "dhuhr": parseTime(timings.Dhuhr),
            "asr": parseTime(timings.Asr),
            "maghrib": parseTime(timings.Maghrib),
            "isha": parseTime(timings.Isha),
            "sunrise": parseTime(timings.Sunrise),
            "sunset": parseTime(timings.Sunset),
            "hijriDate": `${hijri.day} ${hijri.month.en} ${hijri.year}`,
            "nextPrayerName": data.data.nextPrayerName,
            "nextPrayerTime": parseTime(data.data.nextPrayerTime)
        };

        const now = new Date();
        newPrayerData.gregorianDate = `${String(now.getDate()).padStart(2, '0')} ${["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][now.getMonth()]} ${now.getFullYear()}`;

        root.prayerData = newPrayerData;
        root.dataLoaded = true;
        root.isLoading = false;
        updateNextPrayer();
        scheduleNextPrayerCheck();
    }

    function persistNextPrayer() {
        if (!root.dataLoaded || !root.prayerData.nextPrayerTime)
            return;
        const timeStr = Qt.formatTime(root.prayerData.nextPrayerTime, "hh:mm");
        const command = `tmp_file=$(mktemp) && jq '.data.nextPrayerName = "${root.prayerData.nextPrayerName}" | .data.nextPrayerTime = "${timeStr}"' "${root.filePath}" > "$tmp_file" && mv "$tmp_file" "${root.filePath}"`;
        Quickshell.execDetached(["bash", "-c", command]);
    }

    function updateNextPrayer() {
        if (!dataLoaded)
            return;
        const oldNextPrayerName = root.prayerData.nextPrayerName;
        const now = new Date();

        const prayers = [
            {
                name: "Fajr",
                time: root.prayerData.fajr
            },
            {
                name: "Dhuhr",
                time: root.prayerData.dhuhr
            },
            {
                name: "Asr",
                time: root.prayerData.asr
            },
            {
                name: "Maghrib",
                time: root.prayerData.maghrib
            },
            {
                name: "Isha",
                time: root.prayerData.isha
            }
        ].filter(p => p.time);

        // Find the next prayer
        let nextPrayer = null;
        for (let i = 0; i < prayers.length; i++) {
            if (prayers[i].time > now) {
                nextPrayer = prayers[i];
                break;
            }
        }

        // If no prayer found for today, use first prayer of next day (Fajr)
        if (!nextPrayer) {
            nextPrayer = prayers[0];
        }

        if (nextPrayer && oldNextPrayerName !== nextPrayer.name) {
            root.prayerData.nextPrayerName = nextPrayer.name;
            root.prayerData.nextPrayerTime = nextPrayer.time;
            persistNextPrayer();
            scheduleNextPrayerCheck();
        }
    }

    function playAdhan(prayerName) {
        isAdhanPlaying = true;
        adhanPlaying(prayerName);

        Audio.playSound("assets/sounds/halal/adhan.mp3");

        Qt.callLater(() => {
            isAdhanPlaying = false;
            updateNextPrayer();
            prayerTimesFileView.reload();
        }, 90000); // 90 seconds for typical adhan duration
    }

    function refresh() {
        processPrayerData();
        prayerTimesFileView.reload();
    }

    Component.onCompleted: {
        prayerTimesFileView.reload();
        scheduleNextPrayerCheck();
    }
}
