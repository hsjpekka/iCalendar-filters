import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    Component.onCompleted: {
        var i = findCalendarIndex(calendar)
        eventsView.setFilterType(jsonFilters.calendars[i])
        eventsView.filterIcs(jsonFilters)
    }

    property string calendar: ""
    property string icsFile: ""
    property var jsonFilters: {"calendars": [] }

    Column {
        width: parent.width

        PageHeader{
            title: qsTr("%1, testing filter").arg(calendar)
        }

        IcalEventsView {
            id: eventsView
            x: 2*Theme.horizontalPageMargin
            width: parent.width - 1.5*x
            height: page.height - y
            icsOriginal: icsFile
            //settingUp: true

            function filterIcs(filterJson) {
                if (filterJson) {
                    icsModified = icsFilter.filterIcs(calendar, icsOriginal, JSON.stringify(filterJson));
                } else {
                    icsModified = icsFilter.filterIcs(calendar, icsOriginal);
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
        return k;
    }
}
