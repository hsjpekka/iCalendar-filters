import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import "../components"
import "../utils/globals.js" as Globals

Page {
    id: page

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        readCalendars()

        if (calendarList.count > 0) {
            iCurrent = 0
            updateView()
        }
        settingUp = false
    }

    signal filtersChanged()
    signal storeFilters()

    property alias iCurrent: calendarSelector.currentIndex
    property var filtersObj: emptyJson
    property var settingsObj
    property bool settingUp: true
    property string shortLabel: ""

    readonly property var emptyJson: JSON.parse(Globals.emptyJson)
    readonly property string version: "1.2.1"

    onFiltersChanged: {
        if (!settingUp) {
            storeFilters()
        }
    }

    // page seems to reset the current index of the combobox
    // some time after page becomes on top, i.e. after
    // the modify dalendars dialog closes.
    Timer {
        id: timerSelectLast
        repeat: false
        interval: 100
        running: false
        onTriggered: {
            calendarSelector.currentIndex = calendarList.count - 1
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("manage calendars")
                onClicked: {
                    var labelCurrent = calendarSelector.value
                    var urlCurrent = iCurrent >= 0? filtersObj.calendars[iCurrent].url : ""
                    var dialog = pageStack.push(
                                Qt.resolvedUrl("NewCalendar.qml"),
                                {   "oldLabel": labelCurrent,
                                    "oldUrl": urlCurrent,
                                    "oldFilters": filtersObj
                                })
                    dialog.accepted.connect( function () {
                        filtersObj = dialog.newFilters;
                        if (dialog.action === dialog.acCreate) {
                            newCal(dialog.newLabel, dialog.newUrl);
                        } else if (dialog.action === dialog.acDelete) {
                            removeCal(dialog.newLabel);
                        } else {
                            modifyCal(labelCurrent, dialog.newLabel, dialog.newUrl);
                        }
                        page.filtersChanged();
                    })
                }

                function modifyCal(oLbl, nLbl, nUrl) {
                    calendarList.modifyCalendar(oLbl, nLbl, nUrl);
                    calendarSelector.setCurrent(nLbl);
                    return;
                }

                function newCal(labelNew, urlNew) {
                    var result = calendarList.addCalendar(labelNew);
                    if (result > 0) {
                        timerSelectLast.start()
                    }
                    return;
                }

                function removeCal(labelRemoved) {
                    calendarSelector.currentIndex = -1;
                    calendarList.removeCalendar(labelRemoved);
                    useBoth.checked = false;
                    addReminderAdvance.checked = false;
                    addReminderTime.checked = false;
                    timerSelectLast.start();
                    return;
                }
            }

            MenuItem {
                text: qsTr("export to calendar")
                onClicked: {
                    var result
                    var regUnix = /\n/g, regWin = /\r\n/
                    fileOp.setFileName("temporal.ics", "Downloads");
                    if (!regWin.test(eventsView.icsModified)) {
                        result = fileOp.writeTxt( eventsView.icsModified.replace(regUnix, "\r\n") )
                    } else {
                        result = fileOp.writeTxt( eventsView.icsModified )
                    }
                    if (result === undefined || result.length < 1) {
                        note.body = fileOp.error()
                        note.summary = qsTr("File write error.")
                    } else {
                        Qt.openUrlExternally(result)
                        exported = true
                    }
                }
                Notification {
                    id: note
                }
            }

            MenuItem {
                text: qsTr("set up filter")
                enabled: calendarList.count > 0 && iCurrent >= 0
                onClicked: {
                    var dialog, i, cal
                    i = findCalendarIndex()
                    if (i >= 0) {
                        cal = filtersObj.calendars[i]
                        dialog = pageStack.push(Qt.resolvedUrl("Filters.qml"), {
                                            "oldFiltersObj": filtersObj,
                                            "calId": i,
                                            //"calendarLbl": cal.label,
                                            //"calendarUrl": cal.url,
                                            "icsFile": eventsView.icsOriginal,
                                            "settingsObj": settingsObj
                                        } )
                        dialog.accepted.connect( function() {
                            if (dialog.filtersModified) {
                                filtersObj = dialog.newFiltersObj
                                page.filtersChanged()
                                updateView()
                            }
                        } )
                    }
                }
            }
        }

        Label {
            text: version
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
            y: column.y + header.y + header.height - height
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: qsTr("iCalendars")
            }

            ListModel {
                id: calendarList
                // { calendarLabel: "", alarmAdvance: "120", alarmTime: "18:10", both: "yes" }
                // advance & time: "" = not set, > 0 = before (previous day), < 0 = after

                // adds or modifies calendar <label>
                // returns the count if adding, or the index if modifying
                function addCalendar(label, advance, time, both) {
                    var i;
                    if (label === "" || label === undefined) {
                        return -1;
                    }

                    if (advance === undefined) {
                        advance = "";
                    }
                    if (time === undefined) {
                        time = "";
                    }
                    if (both === undefined) {
                        both = "";
                    }

                    i = findCalendar(label);
                    if (i >= 0) {
                        setCalendarAdvance(label, advance + "", i);
                        setCalendarTime(label, time, i);
                    } else {
                        calendarList.append({"calendarLabel":label,
                                "alarmAdvance":advance + "", "alarmTime":time,
                                "both": both});
                        i = calendarList.count;
                    }
                    return i;
                }

                function alarmAdvance(label) {
                    var i, result;
                    result = "";
                    i = findCalendar(label);
                    if (i >= 0) {
                        result = calendarList.get(i).alarmAdvance * 1.0;
                    }
                    return result;
                }

                function alarmTime(label) {
                    var i, result;
                    result = "";
                    i = findCalendar(label);
                    if (i >= 0) {
                        result = calendarList.get(i).alarmTime;
                    }
                    return result;
                }

                function areBothUsed(label) {
                    var i, result;
                    result = false;
                    i = findCalendar(label);
                    if (i >= 0 && calendarList.get(i).both.toLowerCase() === "yes" ) {
                        result = true;
                    }

                    return result;
                }

                function findCalendar(label) {
                    var i, N;
                    i = 0;
                    N = -1;
                    while(i < calendarList.count) {
                        if (calendarList.get(i).calendarLabel === label) {
                            N = i;
                            i = calendarList.count;
                        }
                        i++;
                    }
                    return N;
                }

                function isAdvanceSet(label) {
                    var i, result;
                    result = false;
                    i = findCalendar(label);
                    if (i >= 0 && calendarList.get(i).alarmAdvance > "") {
                        result = true;
                    }
                    return result;
                }

                function isTimeSet(label) {
                    var i, result;
                    result = false;
                    i = findCalendar(label);
                    if (i >= 0 && calendarList.get(i).alarmTime > "") {
                        result = true;
                    }
                    return result;
                }

                function modifyCalendar(currentLabel, newLabel, newUrl) {
                    var i = findCalendar(currentLabel);
                    if (i < 0 || i >= count) {
                        return -1;
                    }
                    set(i, {calendarLabel: newLabel});
                    filtersObj.calendars[iCurrent].label = newLabel;
                    filtersObj.calendars[iCurrent].url = newUrl;
                    return i;
                }

                function removeCalendar(label) {
                    var i;
                    i = calendarList.findCalendar(label);
                    if (i >= 0) {
                        calendarList.remove(i);
                    }
                    return i;
                }

                function setBothAlarms(label, both, i) {
                    if (i === undefined || i < 0 || i >= calendarList.count) {
                        i = findCalendar(label);
                    }
                    if (i >= 0) {
                        calendarList.set(i, {"both": both + "" })
                    } else {
                        console.log("set advance error: calendar", label, "not found")
                    }

                    return i;
                }

                function setCalendarAdvance(label, advance, i) {
                    if (i === undefined || i < 0 || i >= calendarList.count) {
                        i = findCalendar(label);
                    }
                    if (i >= 0) {
                        calendarList.set(i, {"alarmAdvance": advance + "" })
                    } else {
                        console.log("set advance error: calendar", label, "not found")
                    }

                    return i;
                }

                function setCalendarTime(label, time, i) {
                    if (i === undefined || i < 0 || i >= calendarList.count) {
                        i = findCalendar(label);
                    }
                    if (i >= 0) {
                        calendarList.set(i, {"alarmTime":time})
                    } else {
                        console.log("set time error: calendar", label, "not found")
                    }

                    return i;
                }
            }

            ComboBox {
                id: calendarSelector
                width: parent.width
                enabled: calendarList.count > 0
                label: enabled ? qsTr("calendar") : qsTr("no calendars")
                menu: ContextMenu {
                    Repeater {
                        model: calendarList
                        MenuItem {
                            text: calendarLabel
                        }
                    }
                }

                onCurrentIndexChanged: {
                    updateView()
                }

                function setCurrent(lbl) {
                    var i;
                    i = calendarList.findCalendar(lbl);
                    if (i < 0) {
                        return i;
                    }

                    currentIndex = i;
                    return currentIndex;
                }
            }

            SectionHeader {
                text: qsTr("alarms")
            }

            TextSwitch {
                id: addReminderAdvance
                text: checked? qsTr("add a relative reminder") : qsTr("no relative reminders")
                onCheckedChanged: {
                    if (!settingUp) {
                        if (checked) {
                            reminderAdvance.focus = true
                        }
                        modifyReminderAdvance()
                    }
                }
            }

            TextField {
                id: reminderAdvance
                placeholderText: qsTr("remind NN min before the event, after if negative")
                label: text*1.0 > 0? qsTr("remind %1 min before each event").arg(text) : qsTr("remind %1 min after the start").arg(-1.0*text)
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator{}
                visible: addReminderAdvance.checked
                EnterKey.onClicked: focus = false
                onTextChanged: {
                    // check if +/- has been pressed
                    changeSign()
                }
                onFocusChanged: {
                    if (!focus) {
                        modifyReminderAdvance()
                    }
                }

                function changeSign() {
                    // without changeSign(), pressing +/- adds the sign,
                    // but does not put it as the first character
                    // move '-' to the beginning of the string and remove '+'
                    // if the only +/- is '-' as the first character, don't do anything
                    var nbr, sign, str, strs, txt;
                    if (text.indexOf("+") >= 0 ||
                            text.indexOf("-", 1) >= 0) {
                        // the sign after the latest pressing of +/-
                        if (text.charAt(0) === "-") {
                            sign = 1 // -NNNN and '+/-'
                            txt = text.substring(1)
                        } else {
                            sign = -1
                            if (text.charAt(0) === "+") {
                                txt = text.substring(1)
                            } else {
                                txt = text
                            }
                        }

                        if (txt.indexOf("+") > 0) {
                            strs = txt.split("+")
                        } else {
                            strs = txt.split("-")
                        }

                        for (str in strs) {
                            nbr += str + "";
                        }

                        if (strs.length >= 2) {
                            txt = strs[0] + strs[1]
                        } else if (strs.length === 1) {
                            txt = strs[0]
                        }
                        if (!isNaN(nbr*1.0)) {
                            _editor.text = sign*nbr*1.0
                        } else {
                            if (sign < 0) {
                                _editor.text = "-"
                            } else {
                                _editor.text = ""
                            }
                        }
                    }
                    return;
                }
            } // reminderAdvance

            TextSwitch {
                id: addReminderTime
                text: checked? ((useBoth.checked && useBoth.visible)? addBoth : addFullTime) :
                               qsTr("no absolute time reminders")
                onCheckedChanged: {
                    if (!settingUp) {
                        if (checked) {
                            reminderTime.focus = true
                        }
                        modifyReminderTime()
                    }
                }

                property string addBoth: qsTr("adding an absolute time reminder")
                property string addFullTime: qsTr("adding an absolute time reminder on full time events")
            }

            TextField {
                id: reminderTime
                width: parent.width
                placeholderText: qsTr("remind at hh:mm on the previous day, -hh:mm at the same day")
                label: text.charAt(0) == "-" ? qsTr("remind at %1 at the event day").arg(text) : qsTr("remind at %1 at the previous day").arg(text)
                validator: RegExpValidator {
                    regExp: /-?[0-2]?[0-9]:[0-5][0-9]/
                }
                visible: addReminderTime.checked
                EnterKey.onClicked: focus = false
                onFocusChanged: {
                    if (!focus && acceptableInput) {
                        modifyReminderTime()
                    }
                }

                property string time: text.charAt(0) == "-" ? text : text.substring(1)
            }

            TextSwitch {
                id: useBoth
                checked: false
                text: checked? qsTr("adding both reminder types on normal events") :
                               qsTr("adding only relative reminder on normal events")
                onCheckedChanged: {
                    modifyUseBoth()
                }
                visible: addReminderTime.checked && addReminderAdvance.checked
            }

            SectionHeader{
                text: qsTr("components")
            }

            IcalEventsView {
                id: eventsView
                x: Theme.horizontalPageMargin
                width: parent.width - 1.5*x
                //icsOriginal: icsFile
                height: contentHeight
                onCalendarFetched: {
                    filterIcs(filtersObj)
                }

                function fetchCalendar(url) {
                    if (url === undefined || url === "") {
                        console.log("no calendar url");
                        return -1;
                    }

                    fetchIcalFile(url, function (url, icalFile) {
                        icsOriginalChange(icalFile);
                        console.log(url, "\n", icsOriginal.substring(0,20), " ...")
                        calendarFetched();
                        return;
                    });

                    return 0;
                }

                function fetchIcalFile(url, whenReady){
                    var xhttp = new XMLHttpRequest();
                    if (url.charAt(0) === '/') {
                        url = "file://" + url;
                    }

                    xhttp.onerror = function () {
                        console.log("error in fetching", url)
                    }

                    xhttp.onreadystatechange = function () {
                        var str = ""
                        if (xhttp.readyState) {
                            str += " " + xhttp.readyState;
                            if (xhttp.status)
                                str += " ~ " + xhttp.status;
                            if (xhttp.statusText)
                                str += ", " + xhttp.statusText;
                        }

                        if (xhttp.readyState === 4) {
                            if (xhttp.status === 200) {
                                whenReady(url, xhttp.responseText);
                            } else {
                                str += " ! unsuccessfull !"
                            }
                        }

                        if (str !== "") {
                            console.log(str);
                        }

                        return;
                    }

                    console.log(url);
                    xhttp.open("GET", url, true);
                    xhttp.send();

                    return;
                }

                function filterIcs(filterJson) {
                    if (filterJson) {
                        icsModifiedChange(icsFilter.filterIcs(calendarSelector.value, icsOriginal, JSON.stringify(filterJson)));
                    } else {
                        icsModifiedChange(icsFilter.filterIcs(calendarSelector.value, icsOriginal));
                    }

                    return;
                }

                function setFilterType(cal) {
                    var cmp, i, isReject, nfltrs;
                    if (cal.filters) {
                        if (cal.filters.count) {
                            nfltrs = cal.filters.count;
                        } else {
                            nfltrs = 0;
                        }
                        i = 0;
                        while (i < nfltrs) {
                            isReject = "";
                            if (cal.filters[i].component) {
                                cmp = cal.filters[i].component;
                                if (cal.filters[i].action) {
                                    isReject = cal.filters[i].action;
                                }
                                setActionDefault(cmp, isReject);
                            }
                            i++;
                        }
                    }

                    return;
                }
            }

        }

        VerticalScrollDecorator{}
    }

    function findCalendarIndex(label) {
        var i, k;
        if (label === undefined || label === "") {
            label = calendarSelector.value
        }

        k = -1;
        i = 0;
        while (i < filtersObj.calendars.length) {
            if (filtersObj.calendars[i].label === label) {
                k = i;
                i = filtersObj.calendars.length;
            }
            i++;
        }
        return k;
    }

    function modifyReminderAdvance() {
        var i, key, modCal, oldCal;
        modCal = {"label": ""};
        i = findCalendarIndex();
        if (i >= 0) {
            // don't copy dayreminder
            oldCal = filtersObj.calendars[i];
            for (key in oldCal) {
                if (key !== "reminder") {
                    modCal[key] = oldCal[key];
                }
            }
            if (addReminderAdvance.checked) {
                if (reminderAdvance.text > "") {
                    modCal["reminder"] = reminderAdvance.text*1.0;
                } else {
                    i = -1;
                }
            }
            if (i >= 0) {
                filtersObj.calendars[i] = modCal;
                filtersChanged();
            }
        }

        return i;
    }

    function modifyReminderTime() {
        var i, key, modCal, oldCal;
        modCal = {"label": ""};
        i = findCalendarIndex();
        if (i >= 0) {
            // don't copy dayreminder
            oldCal = filtersObj.calendars[i];
            for (key in oldCal) {
                if (key !== "dayreminder") {
                    modCal[key] = oldCal[key];
                }
            }
            if (addReminderTime.checked) {
                if (reminderTime.acceptableInput) {
                    modCal["dayreminder"] = reminderTime.text;
                } else {
                    i = -1;
                }
            }
            if (i >= 0) {
                filtersObj.calendars[i] = modCal;
                filtersChanged();
            }
        }

        return i;
    }

    function modifyUseBoth() {
        var i;

        i = findCalendarIndex();
        if (i >= 0) {
            if (useBoth.checked) {
                filtersObj.calendars[i]["bothReminders"] = "yes";
            } else {
                filtersObj.calendars[i]["bothReminders"] = "no";
            }
            filtersChanged();
        }

        return i;
    }

    function readCalendars() {
        // return -1 = no filters-file, 0 = no json-file, >0 = calendars
        var filtersFile, i, cal, adv, time, d=[];
        if (!filtersObj.calendars) {
            console.log("<-------->");
            console.log("tyhjä suodatintiedosto");
            console.log("<-------->");
            filtersObj = emptyJson;
        }

        i = 0;
        while (i < filtersObj.calendars.length) {
            cal = filtersObj.calendars[i];
            calendarList.addCalendar(cal.label, cal.reminder,
                                     cal.dayreminder, cal.bothReminders);
            i++;
        }

        return filtersObj.calendars.length;
    }

    function updateView() {
        var cal, calLbl, cmp, i, isReject, nftrs, regExp;

        if (filtersObj.calendars.length > 0 && iCurrent >= 0) {
            cal = filtersObj.calendars[iCurrent];
            calLbl = cal.label;
            if (calLbl.length > 15) {
                shortLabel = calLbl.substring(0,12) + "...";
            } else {
                shortLabel = calLbl;
            }

            if (cal.bothReminders && cal.bothReminders.toLowerCase() === "yes") {
                useBoth.checked = true;
            } else {
                useBoth.checked = false;
            }

            if (cal.reminder && cal.reminder !== "") {
                addReminderAdvance.checked = true;
                reminderAdvance.text = cal.reminder;
                reminderAdvance.focus = false;
            } else {
                addReminderAdvance.checked = false;
            }

            if (cal.dayreminder && cal.dayreminder !== "") {
                addReminderTime.checked = true;
                reminderTime.text = cal.dayreminder;
                reminderTime.focus = false;
            } else {
                addReminderTime.checked = false;
            }

            eventsView.clear();
            if (cal.url > "") {
                eventsView.setFilterType(cal);
                eventsView.fetchCalendar(cal.url);
            }
        } else {
            eventsView.clear();
        }

        return;
    }

}
