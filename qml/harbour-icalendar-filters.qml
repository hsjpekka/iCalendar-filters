import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "utils/globals.js" as Globals

ApplicationWindow {
    id: application
    //initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        var i
        i = readFilters()
        if (i > 0) {
            cleanUpFiltersFile()
        }
        readSettings()
        initialPage = pageStack.push(Qt.resolvedUrl("pages/FirstPage.qml"), {
                                         "filtersObj": filtersObj,
                                         "settingsObj": settingsObj
                                     } )
        initialPage.storeFilters.connect( function(){
            filtersObj = initialPage.filtersObj
            storeFilters()
        })
    }

    readonly property var emptyJson: JSON.parse(Globals.emptyJson)
    readonly property var emptyCalendar: JSON.parse(Globals.emptyCalendar)

    property var filtersObj: emptyJson;
    property var settingsObj: { "filteringProperties": {
        "vevent": ["dtstart", "summary", "categories"],
        "vtodo": ["dtstart", "summary", "categories"],
        "vjournal": ["dtstart", "summary", "categories"],
        "vfreebusy": ["dtstart", "summary", "categories"]
        } };

    function cleanUpFiltersFile() {
        var i, k, fltrs, lbl, unclean, cleared;

        i = 0;
        cleared = 0;
        unclean = 0;
        fltrs = emptyJson;
        while (i < filtersObj.calendars.length) {
            if (!filtersObj.calendars[i].label) {
                unclean++;
                cleared++;
            } else {
                lbl = filtersObj.calendars[i].label;
                k = i - 1;
                while (k >= 0) {
                    if (filtersObj.calendars[k].label === lbl) {
                        unclean++;
                        cleared++;
                    }
                    k--;
                }
            }

            if (unclean === 0) {
                fltrs.calendars.push(filtersObj.calendars[i]);
            } else {
                unclean = 0;
            }

            i++;

        }
        if (cleared > 0) {
            filtersObj = JSON.parse(JSON.stringify(fltrs));
            console.log("multiple entries for a calendar found (" + unclean + ")");
            storeFilters();
        }

        return cleared;
    }

    function readFilters() {
        // return -1 = no filters-file, 0 = no json-file, >0 = calendars
        var filtersStr, i, cal, adv, time, d=[];

        Globals.settingsFilePath = fileOp.getConfigPath();
        fileOp.setFileName(Globals.filtersFileName, Globals.settingsFilePath);
        filtersStr = fileOp.readTxt();

        if (!filtersStr || filtersStr.length < 1) {
            console.log("empty filtersStr");
        }

        if (filtersStr.length > 1){
            filtersObj = JSON.parse(filtersStr);
        }
        if (!filtersObj || !filtersObj.calendars) {
            return -1;
        }

        return filtersObj.calendars.length;
    }

    function readSettings() {
        // defaults
        // { "filteringProperties": {
        //     "vevent": ["dtstart", "summary", "categories"],
        //     "vtodo": [-"-], "vfreetime": [-"-], "vjournal": [-"-]
        //   }
        // }
        //
        var jsonStr, jsonObj;
        //console.log(icsFilter.setFiltersFile())
        Globals.settingsFilePath = fileOp.getConfigPath();
        fileOp.setFileName(Globals.settingsFileName, Globals.settingsFilePath);
        jsonStr = fileOp.readTxt();
        if (jsonStr > "") {
            jsonObj = JSON.parse(jsonStr);
        }

        setUpLists(jsonObj);

        return;
    }

    function setUpLists(fObj) {
        // defaults
        // { "filteringProperties": {
        //     "vevent": ["dtstart", "summary", "categories"],
        //     "vtodo": [-"-], "vfreetime": [-"-], "vjournal": [-"-]
        //   }
        // }
        //
        var cName, filters, filterSettings, pName, ic;
        var cal, c, sc, p, sp;

        if (!fObj) {
            fObj = settingsObj;
        } else if (!fObj.filteringProperties
                || Object.keys(fObj.filteringProperties).length === 0) {
            fObj["filteringProperties"] = settingsObj.filteringProperties;
        }

        filterSettings = fObj.filteringProperties;

        // add properties from the existing filter
        for (cal in fObj) {
            filters = fObj[cal].filters;
            for (c in filters) {
                var isCmp = false;
                cName = filters[c].component;
                // is the component in the list
                for (sc in filterSettings) {
                    if (sc === cName) {
                        isCmp = true;
                        ic = sc;
                    }
                }
                if (!isCmp) {
                    filterSettings[cName] = [];
                }

                // are the filter properties in the list
                for (p in filters[c].properties) {
                    var isPrp = false;
                    pName = filters[c].properties[p].property;
                    for (sp in filterSettings[cName]) {
                        if (filterSettings[cName][sp] === pName) {
                            isPrp = true;
                        }
                    }
                    if (!isPrp) {
                        filterSettings[cName].append(pName);
                    }
                }
            }

            settingsObj.filteringProperties = filterSettings;
        }
        return;
    }

    function storeFilters() {
        var filtersFile, result;
        if (filtersObj.calendars) {
            filtersFile = JSON.stringify(filtersObj, null, 2);
            result = fileOp.writeTxt(filtersFile, Globals.filtersFileName, Globals.settingsFilePath);
        } else {
            console.log(qsTr("Bad filters-file format:"), JSON.stringify(filtersObj, null, 2));
        }

        return result;
    }
}
