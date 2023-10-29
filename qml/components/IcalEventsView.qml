import QtQuick 2.0
import Sailfish.Silica 1.0

// {"year", "day", "clock", "type", "location", "description", "include"}
SilicaListView{
    id: icalEventView
    width: parent? parent.width : Screen.width
    height: Theme.fontSizeMedium*4

    signal calendarFetched()

    property color leaveOutColor: Theme.secondaryColor
    property color readInColor: Theme.highlightColor
    property string icsOriginal: ""
    property string icsModified: ""
    readonly property bool filterDefault: false // by default rejects events that match filters

    onIcsOriginalChanged: {
        console.log("taas lähtee")
        refresh(true) // unfiltered file
        refresh(false) // filtered file
    }

    onIcsModifiedChanged: {
        refresh(false)
    }

    ListModel {
        id: filterActionList
        ListElement {
            vcomponent: "vevent"
            isReject: true
        }
        ListElement {
            vcomponent: "vtodo"
            isReject: true
        }
        ListElement {
            vcomponent: "vfreebusy"
            isReject: true
        }

        function add(vcomp, action) {
            var j, isR;
            j = getIndex(vcomp);
            isR = toRejectValue(action);
            if (j < 0) {
                append({ "vcomponent": vcomp.toLowerCase(), "isReject": isR})
            } else {
                set(i, { "isReject": isR });
            }
            return i;
        }

        function getIndex(vcomp) {
            var i, N, result;
            i = 0;
            result = -1;
            N = count;
            while (i < N) {
                if (get(i).vcomponent === vcomp.toLowerCase()) {
                    result = i;
                    i = N;
                }
                i++;
            }
            return result;
        }

        function isReject(vcomp) {
            var i, result;
            result = filterDefault;
            i = getIndex(vcomp);
            if (i >= 0) {
                result = get(i).isReject;
            } else {
                console.log(vcomp, "not found");
            }

            return result;
        }

        function modify(vcomp, action) {
            var i, isR, result;
            i = getIndex(vcomp);
            isR = toRejectValue(action);
            if (i < 0) {
                console.log(vcomp, "not found");
                result = -1;
            } else {
                set(i, { "isReject": isR });
                result = 0;
            }
            return result;
        }

        function toRejectValue(txt) {
            var result;
            if (typeof txt === typeof " ") {
                if (txt.toLowerCase() === "accept") {
                    result = filterDefault;
                } else {
                    result = !filterDefault;
                }
            } else if (typeof txt === typeof true) {
                result = txt;
            } else {
                console.log("no string:", txt);
                result = true;
            }
            return result;
        }
    }

    Component {
        id: eventListDelegate
        ListItem {
            id: eventsListItem
            width: parent.width
            height: eventDay.height

            property bool accept: include

            Row {
                width: parent.width
                spacing: Theme.paddingSmall

                Icon {
                    id: acceptIcon
                    source: eventsListItem.accept? "image://theme/icon-s-checkmark" :
                                                   "image://theme/icon-s-decline"
                    color: eventsListItem.accept? readInColor: leaveOutColor
                }

                Label {
                    id: eventDay
                    text: day
                    color: eventsListItem.accept ? Theme.highlightColor : Theme.secondaryHighlightColor
                }

                Label {
                    id: eventClock
                    text: clock
                    color: eventDay.color
                }

                Label {
                    id: eventName
                    text: txt
                    color: eventDay.color
                }

            }
        }

    }

    ListModel{
        id: calendarData
        ListElement {
            include: false
            vcomp: "vevent"
            day: "date"
            clock: "time"
            txt: "txt"
        }
        property bool firstTime: true

        function add(comp, d, t, txt) {
            var isReject;
            if (firstTime) {
                clear();
                firstTime = false;
            }
            isReject = filterActionList.isReject(comp);

            return append({"vcomp": comp, "include": isReject, "day" : d,
                              "clock": t, "txt": txt});
        }

        function check(comp, d, t, txt) {
            var i, cmp, cDate = "", cTime = "", cTxt = "", isReject;
            i=0;
            while (i < count) {
                cmp = get(i).vcomp.toLowerCase();
                cDate = get(i).day;
                cTime = get(i).clock;
                cTxt = get(i).txt;

                if (comp.toLowerCase() === cmp && cDate === d && cTime === t &&
                        cTxt.toLowerCase() === txt.toLowerCase()) {
                    isReject = filterActionList.isReject(comp);
                    setProperty(i, "include", isReject);
                    i = count;
                }

                i++;
            }
            return (i > count);
        }

        function resetCheck() {
            var cmp, i, N, isReject;
            i = 0;
            N = calendarData.count;
            while (i < N) {
                cmp = get(i).vcomp;
                isReject = filterActionList.isReject(cmp);
                setProperty(i, "include", !isReject);
                i++;
            }
            return;
        }
    }

    spacing: Theme.paddingMedium
    clip: true

    model: calendarData//isCppModel? eventsListModelcpp : eventsListModelJS
    delegate: eventListDelegate

    VerticalScrollDecorator{}

    function clear() {
        return calendarData.clear();
    }

    // finds the next component, returns the line number
    // returns -line numbe''''r if end of calendar reached
    function componentSearch(lineArray, i0) {
        var i, N, reCalBegin, reCalEnd, reCmp;
        N = -1;
        i = (i0 >= 0)? i0 : 0;
        reCmp = /^begin\s*:\s*/i;
        reCalBegin = /^begin\s*:\s*[v]*calendar/i;
        reCalEnd = /^end\s*:\s*[v]*calendar/i;
        while (i < lineArray.length) {
            N = i;
            if (reCalEnd.test(lineArray[i])) { //if there is more than one calendar in the file
                N = -i;
                i = lineArray.length;
            } else if (reCmp.test(lineArray[i]) &&
                       !reCalBegin.test(lineArray[i])) {
                i = lineArray.length;
            }
            i++;
        }
        return N;
    }

    // stores the component in the listmodel
    // returns the line number of <end:vcomponent>
    function componentStore(lineArray, i0, isOrig) {
        var cmp, edate, edesc, etime, eventDate, i, iN, isReject, keyValue, p, props, endExp, s, strs;
        isReject = true;
        if (i0 >= lineArray.length) {
            return -1;
        }
        // set the end of the component
        strs = lineArray[i0].split(":");//begin:vcomponent
        if (strs.length < 2) {
            console.log("rivi = " + lineArray[i0]);
            return i0;
        }
        cmp = strs[1].trim();
        endExp = new RegExp("^end\\s*:\\s*" + cmp,"i");
        // read component properties
        i = i0;
        props = [];
        while (i < lineArray.length) {
            if (endExp.test(lineArray[i])) { // end of component
                iN = i;
                i = lineArray.length;
            } else {
                keyValue = keyAndValue(lineArray[i]);
                props.push({"key": keyValue[0], "value": keyValue[1]});
            }
            i++;
        }

        // select the properties to store in the list
        // date, time, title
        // title = description || summary || categories
        for (i in props) {
            p = props[i].key.toLowerCase();
            if (p === "dtstart") {
                strs = props[i].value.split("T"); // strs[0] = 20230429, strs[1] = hhmmss(Z)
                // 20230415T073416Z => 2023-04-15T07:34:16Z
                s = strs[0].substr(0,strs[0].length - 4) + "-" +
                        strs[0].substr(-4, 2) + "-" + strs[0].substr(-2);
                if (strs.length > 1) {
                    s += "T" + strs[1].substr(0,2) + ":"
                            + strs[1].substr(2,2) + ":"
                            + strs[1].substr(4);
                }
                eventDate = new Date(s);
                edate = eventDate.getDate() + "." + (eventDate.getMonth() + 1) + ".";
                if (strs.length > 1) {
                    etime = eventDate.getHours() + ":";
                    if (eventDate.getMinutes() < 10) {
                        etime += "0" + eventDate.getMinutes();
                    } else {
                        etime += eventDate.getMinutes();
                    }
                } else {
                    etime = "";
                }
            } else if (p === "summary" ||
                       (p === "description" && edesc === "")) {
                edesc = props[i].value;
            }
        }
        // if description and summary are not given
        if (edesc === "") {
            for (i in props) {
                if (props[i].key.toLocaleLowerCase() === "category") {
                    edesc = props[i].value;
                }
            }
        }

        if (isOrig) {
            calendarData.add(cmp, edate, etime, edesc);
        } else {
            calendarData.check(cmp, edate, etime, edesc);
        }

        return iN;
    }

    function fetchCalendar(url) {
        if (url === undefined || url === "") {
            console.log("no calendar url");
            return -1;
        }

        fetchIcalFile(url, function (url, icalFile) {
            icsOriginal = icalFile; // stores the latest file
            console.log(url, "\n", icsOriginal.substring(0,20), " ...")
            calendarFetched();
            return;
        });

        return 0;
    }

    function fetchIcalFile(url, whenReady){
        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {
            console.log(" " + xhttp.readyState + " ~ " + xhttp.status + ", " + xhttp.statusText);
            if (xhttp.readyState === 4) {
                if (xhttp.status === 200) {
                    whenReady(url, xhttp.responseText);
                }
            }
            return;
        }

        console.log(url);
        xhttp.open("GET", url, true);
        xhttp.send();

        return;
    }

    function keyAndValue(line) {
        var i, j, key, value;
        key = readKey(line);
        value = readValue(line);
        return [key, value];
    }

    function processIcs(fileStr, isOrig) {
        var cmp, i, lines, N, newLines, qq;

        lines = fileStr.split("\r\n");
        if (lines.length < 2) {
            lines = fileStr.split("\n");
            if (lines.lenght > 1) {
                if (isOrig) {
                    console.log("iCalendar-file has wrong end of lines.");
                } else {
                    console.log("Modified iCalendar-file has wrong end of lines.");
                }
            }
        }

        newLines = unFoldLines(lines);
        N = newLines.length;
        if (newLines === undefined || newLines.length === undefined || N < 1) {
            if (isOrig) {
                console.log("Error when unfolding the iCalendar-file.");
            } else {
                console.log("Error when unfolding the modified iCalendar-file.");
            }

            return -1;
        }

        if (!isOrig) {
            calendarData.resetCheck()
        }

        i = 0;
        while (i < N) {
            i = componentSearch(newLines, i);
            if (i < 0) { // end of vcalendar
                i = N;
            } else {
                i = componentStore(newLines, i, isOrig);
            }
            i++;
        }

        return;
    }

    function readKey(line) {
        var i, j, result = line;
        i = line.indexOf(":");
        j = line.indexOf(";");
        if (j < 0 && i > 0) {
            result = line.substring(0, i);
        } else if (j > 0 && (j < i || i < 0)) {
            result = line.substring(0, j);
        }
        return result;
    }

    function readValue(line) {
        var i, j, k, result;
        i = line.indexOf(":");
        j = line.indexOf(";");
        if (i < 0) {
            result = "";
        } else if ((j < 0 && i > 0) || (j > i && i > 0)) { // no ; or ; is part of the value
            result = line.substring(i + 1);
        } else { // some property parameters found
            k = line.indexOf('"'); // is there dquoted parameters
            while (k < i && k > 0) { // a dquoted parameter value found
                k = line.indexOf('"', k + 1); // end of dquote
                if (k > 0) {
                    i = line.indexOf(':', k + 1); // first : after the dquote
                    k = line.indexOf('"', k + 1); // next dquote?
                }
            }
            if (i > 0) {
                result = line.substring(i);
            }
        }
        return result;
    }

    function refresh(isOrig) {
        var result = -1;
        if (icsOriginal === undefined || icsOriginal.length === 0 ||
                (!isOrig && (icsModified === undefined ||
                                  icsModified.length === 0))) {
            console.log(isOrig,"tyhjä tiedosto");
        } else {
            if (isOrig) {
                calendarData.clear();
                processIcs(icsOriginal, true);
            } else {
                processIcs(icsModified, false);
            }
            result = 2;
        }
        return result;
    }

    function setActionDefault(cmp, isReject) {
        return filterActionList.add(cmp, isReject);
    }

    //if a line starts with a white space, combine the line and the previous line
    function unFoldLines(lineArray) {
        var cmbLine, i, line0, line1, newArray = [];
        i = lineArray.length - 1;
        while (i > 0) {
            line1 = lineArray[i];
            if (line1.charAt(0) === " ") { // || chr === "\t") {
                line0 = lineArray[i-1];
                cmbLine = line0.concat(line1.substring(1));
                lineArray[i-1] = cmbLine;
                lineArray[i] = "";
            }
            i--;
        }
        i=0;
        while (i < lineArray.length - 1) {
            if (lineArray[i] !== "") {
                newArray.push(lineArray[i]);
            }
            i++;
        }

    return newArray;
    }
}
