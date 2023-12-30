import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        console.log("nyt", Theme.opacityHigh)
        setFiltersFile()
        readFilters()

        if (calendarList.count > 0) {
            console.log("valittuna", calendarSelector.currentIndex)
            calendarSelector.currentIndex = 0
            eventsView.setFilterType(filtersJson.calendars[0])
            if (filtersJson.calendars[0].url > "") {
                eventsView.fetchCalendar(filtersJson.calendars[0].url)
            }
        }
        settingUp = false
    }

    property int iCurrent: -1
    property var filtersJson: emptyJson
    property bool settingUp: true

    readonly property var emptyJson: {"calendars": [] }

    signal filtersChanged()
    onFiltersChanged: {
        //viewFiltersFile.update()
        if (!settingUp) {
            storeFilters()
        }
    }
    onICurrentChanged: {
        // show alarms
        var cal, calLbl, cmp, i, isReject, nftrs;
        settingUp = true
        console.log(iCurrent, calendarList.count, calendarSelector.currentIndex)
        if (calendarList.count > 0) {
            cal = calendarList.get(iCurrent)
            calLbl = cal.calendarLabel
            if (calendarList.isAdvanceSet(calLbl)) {
                addReminderAdvance.checked = true
                reminderAdvance.text = calendarList.alarmAdvance(calLbl)
            } else {
                addReminderAdvance.checked = false
            }

            if (calendarList.isTimeSet(calLbl)) {
                addReminderTime.checked = true
                reminderTime.text = calendarList.alarmTime(calLbl)
            } else {
                addReminderTime.checked = false
            }

            eventsView.clear();
            if (filtersJson.calendars[iCurrent].url > "") {
                txtUrl.text = filtersJson.calendars[iCurrent].url
                txtUrl.readOnly = true
                eventsView.fetchCalendar(filtersJson.calendars[iCurrent].url)
            } else {
                txtUrl.text = ""
                txtUrl.readOnly = false
            }
        }
        settingUp = false

    }

    ListModel {
        id: calendarList
        // { calendarLabel: "", alarmAdvance: "120", alarmTime: "18:10" }
        // advance & time: "" = not set, > 0 = before, < 0 = after

        function addCalendar(label, advance, time) {
            var i;
            console.log(label, advance, time)
            if (label === "" || label === undefined) {
                return -1;
            }

            if (advance === undefined) {
                advance = "";
            }
            if (time === undefined) {
                time = "";
            }

            i = findCalendar(label);
            if (i >= 0) {
                console.log("löytyi ", label)
                setCalendarAdvance(label, advance + "", i);
                setCalendarTime(label, time, i);
            } else {
                console.log("lisätään uusi kalenteri", label)
                calendarList.append({"calendarLabel":label,
                       "alarmAdvance":advance + "", "alarmTime":time });
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

        function removeCalendar(label) {
            var i;
            i = calendarList.findCalendar(label);
            if (i >= 0) {
                calendarList.remove(i);
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

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("remove calendar settings")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("NewCalendar.qml"),
                                                {"create" : false,
                                                 "calendarLabel": calendarSelector.value
                                                })
                    dialog.accepted.connect( function () {
                        remorse.execute(qsTr("Deleting", calendarSelector.value), function () {
                            removeCalendarFromJson(calendarSelector.value)
                            page.filtersChanged()
                        } )

                    } )
                }
            }

            MenuItem {
                text: qsTr("New calendar")
                onClicked: {
                    //var dialog = pageStack.animatorPush(Qt.resolvedUrl("NewCalendar.qml"))
                    var dialog = pageStack.push(Qt.resolvedUrl("NewCalendar.qml"))
                    dialog.accepted.connect( function () {
                        var result = calendarList.addCalendar(dialog.calendarLabel)
                        addCalendarToJson(dialog.calendarLabel, dialog.url)
                        console.log("vanha:", result, calendarSelector.currentIndex)
                        if (result > 0) {
                            page.iCurrent = result - 1
                            calendarSelector.currentIndex = result-1
                        }
                        console.log("uusi:", result, calendarSelector.currentIndex)
                        page.filtersChanged()
                    })
                }
            }

            MenuItem {
                text: qsTr("Set up filter")
                onClicked: {
                    var dialog, i, cal
                    i = findCalendarIndex()
                    if (i >= 0) {
                        cal = filtersJson.calendars[i]
                        dialog = pageStack.push(Qt.resolvedUrl("Filters.qml"), {
                                            "jsonFilters": filtersJson,
                                            "calendarLbl": cal.label,
                                            "calendarUrl": cal.url,
                                            "icsFile": eventsView.icsOriginal } )
                        dialog.closing.connect( function() {
                            //modifyCalendarFilters(calendarLbl, filters)
                            filtersJson = dialog.jsonFilters
                            page.filtersChanged()
                        } )
                    }
                }
            }
        }

        contentHeight: column.height

        RemorsePopup {
            id: remorse
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("iCalendars")
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
                    page.iCurrent = currentIndex
                }
                currentIndex: -1

            }

            TextField {
                id: txtUrl
                width: parent.width
                placeholderText: qsTr("https://address.of.the/calendar")
                label: qsTr("address of the iCalendar-file")
                readOnly: true
                opacity: readOnly? Theme.opacityOverlay : 1
                EnterKey.onClicked: {
                    addCalendarUrl(iCurrent, text)
                    focus = false
                }
                EnterKey.iconSource: "image://theme/icon-m-accept"
                onPressAndHold: {
                    readOnly = false
                }
                onFocusChanged: {
                    if (!focus) {
                        readOnly = true
                    }
                }
            }

            TextSwitch {
                id: addReminderAdvance
                text: checked? qsTr("add a reminder for normal events") : qsTr("no reminders for normal events")
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
                    // by default, pressing +/- adds the sign, but does not put it as the first character
                    if (text.indexOf("+") >= 0 ||
                            text.indexOf("-", 1) >= 0) {
                        var nbr, sign, strs, txt;

                        // the sign after the latest +/-
                        if (text.charAt(0) === "-") {
                            sign = 1
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

                        if (strs.length >= 2) {
                            txt = strs[0] + strs[1]
                        } else if (strs.length === 1) {
                            txt = strs[0]
                        }
                        if (!isNaN(txt*1.0)) {
                            _editor.text = sign*txt*1.0
                        } else {
                            if (sign < 0) {
                                _editor.text = "-"
                            } else {
                                _editor.text = ""
                            }
                        }
                    }
                }
                onFocusChanged: {
                    if (!focus) {
                        modifyReminderAdvance()
                    }
                }
            } // reminderAdvance

            TextSwitch {
                id: addReminderTime
                text: checked? qsTr("add a reminder for full day events"):
                               qsTr("no reminders for full day events")
                //property bool selected: checked
                onCheckedChanged: {
                    if (!settingUp) {
                        if (checked) {
                            reminderTime.focus = true
                        }
                        modifyReminderTime()
                    }
                }
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

            SectionHeader{
                text: qsTr("components")
            }

            IcalEventsView {
                id: eventsView
                x: 2*Theme.horizontalPageMargin
                width: parent.width - 1.5*x
                height: page.height - y > Theme.fontSizeMedium*8?
                            page.height - y : Theme.fontSizeMedium*8
                //icsOriginal: icsFile
                onCalendarFetched: {
                    filterIcs(filtersJson)
                }

                function filterIcs(filterJson) {
                    if (filterJson) {
                        icsModified = icsFilter.filterIcs(calendarSelector.value, icsOriginal, JSON.stringify(filterJson));
                    } else {
                        icsModified = icsFilter.filterIcs(calendarSelector.value, icsOriginal);
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
    }

    function addCalendarToJson(newCalendar, calendarUrl) {
        var k, record;
        if (!filtersJson.calendars) {
            filtersJson["calendars"] = [];
        }
        record = {"label": newCalendar, "url": calendarUrl };
        if (addReminderAdvance.checked && reminderAdvance.text > "") {
            record["reminder"] = reminderAdvance.text*1.0;
        }
        if (addReminderTime.checked && reminderTime.text > "") {
            record["dayreminder"] = reminderTime.text;
        }

        k = findCalendarIndex(newCalendar);
        if (k === -1) {
            filtersJson.calendars.push(record);
            k = filtersJson.calendars.length;
        } else {
            filtersJson.calendars[k] = record;
        }

        return k;
    }

    function addCalendarUrl(iCal, url) {
        filtersJson.calendars[iCal]["url"] = url;
        storeFilters();
        return;
    }

    function findCalendarIndex(label) {
        var i, k;
        if (label === undefined || label === "") {
            label = calendarSelector.value
        }

        k = -1;
        i = 0;
        while (i < filtersJson.calendars.length) {
            if (filtersJson.calendars[i].label === label) {
                k = i;
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
            if (addReminderAdvance.checked && reminderAdvance.text > "") {
                filtersJson.calendars[i]["reminder"] = reminderAdvance.text*1.0;
            } else if (!addReminderAdvance.checked) {
                // don't copy reminder
                oldCal = filtersJson.calendars[i];
                for (key in oldCal) {
                    console.log(key, oldCal.label)
                    if (key !== "reminder") {
                        modCal[key] = oldCal[key];
                    }
                }
                filtersJson.calendars[i] = modCal;
            } else {
                i = -1;
            }
            if (i >= 0) {
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
            if (addReminderTime.checked && reminderTime.acceptableInput) {
                filtersJson.calendars[i]["dayreminder"] = reminderTime.text;
            } else if (!addReminderTime.checked) {
                // don't copy dayreminder
                oldCal = filtersJson.calendars[i];
                for (key in oldCal) {
                    if (key !== "dayreminder") {
                        modCal[key] = oldCal[key];
                    }
                }
                filtersJson.calendars[i] = modCal;
            } else {
                i = -1;
            }
            if (i >= 0) {
                filtersChanged();
            }
        }

        return i;
    }

    function modifyCalendarFilters(calendarLbl, filters) {
        var i;
        i = findCalendarIndex(calendarLbl);
        if (i >= 0) {
            filtersJson.calendars[i]["filters"] = filters;
        }

        return i;
    }

    function readFilters() {
        // return -1 = no filters-file, 0 = no json-file, >0 = calendars
        var filtersFile, i, cal, adv, time, d=[];

        filtersFile = icsFilter.readFiltersFile();
        //viewFiltersFile.text = filtersFile;

        if (filtersFile.length > 1){
            filtersJson = JSON.parse(filtersFile);
            console.log("kalentereita", filtersJson.calendars.length)
        } else {
            return -1;
        }

        if (!filtersJson.calendars) {
            return 0;
        }

        i = 0;
        while (i < filtersJson.calendars.length) {
            cal = filtersJson.calendars[i];
            calendarList.addCalendar(cal.label, cal.reminder, cal.dayreminder);
            i++;
        }

        return filtersJson.calendars.length;
    }

    function removeCalendarFromJson(label) {
        var i, k, djson;
        i = findCalendarIndex(label);
        if (i >= 0) {
            djson = emptyJson;
            k = 0;
            while (k < filtersJson.calendars.length) {
                if (k !== i) {
                    djson.calendars.append(filtersJson.calendars[k]);
                }
                k++;
            }
        }
        return;
    }

    function setFiltersFile() {
        var configPath, i;
        configPath = icsFilter.setFiltersFile();
        i = configPath.indexOf("/", 2); // /home/
        i = configPath.indexOf("/", i+1); // /home/nemo || defaultuser
        configPath = configPath.substring(0, i+1);
        configPath += ".config/null.hsjpekka/webcal-filters/"
        //"iCalendarFilters.json", "/home/defauluser/.config/webcal-client/")
        console.log(configPath)
        return icsFilter.setFiltersFile("iCalendarFilters.json", configPath);
    }

    function storeFilters() {
        var filtersFile;
        filtersFile = JSON.stringify(filtersJson);
        return icsFilter.overWriteFiltersFile(filtersFile);
    }
}
