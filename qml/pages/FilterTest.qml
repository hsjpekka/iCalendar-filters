import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import "../components"

Page {
    id: page
    Component.onCompleted: {
        var i = findCalendarIndex(calendar)
        eventsView.icsOriginalChange(icsFile)
        eventsView.setFilterType(jsonFilters.calendars[i])
        eventsView.filterIcs(jsonFilters)
    }
    Component.onDestruction: {
        if (exported) {
            fileOp.removeFile("temporal.ics", "Downloads")
        }
    }

    property string calendar: ""
    property string icsFile: ""
    property var jsonFilters: {"calendars": [] }
    property bool exported: false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
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
        }

        Column {
            id: column
            width: parent.width

            PageHeader{
                title: qsTr("%1, testing filter").arg(calendar)
            }

            IcalEventsView {
                id: eventsView
                x: Theme.horizontalPageMargin
                width: parent.width - 1.5*x
                height: page.height - y

                function filterIcs(filterJson) {
                    console.log(JSON.stringify(filterJson))
                    if (filterJson) {
                        //icsModified = icsFilter.filterIcs(calendar, icsOriginal, JSON.stringify(filterJson));
                        icsModifiedChange(icsFilter.filterIcs(calendar, icsOriginal, JSON.stringify(filterJson)));
                    } else {
                        //icsModified = icsFilter.filterIcs(calendar, icsOriginal);
                        icsModifiedChange(icsFilter.filterIcs(calendar, icsOriginal));
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

    function findCalendarIndex(label) {
        var i, k;
        k = -1;
        i = 0;
        while (i < jsonFilters.calendars.length) {
            if (jsonFilters.calendars[i].label === label) {
                k = i;
            }
            i++;
        }
        if (k < 0) {
            console.log("calendar", label, "not found");
        }

        return k;
    }
}
