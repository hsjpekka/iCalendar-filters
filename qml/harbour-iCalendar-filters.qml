import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "utils/globals.js" as Globals

ApplicationWindow {
    //initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        var i
        setFiltersFile()
        i = readFilters()
        console.log("kalentereita", i)
        if (i > 0) {
            cleanUpFilters()
        }
        readSettings()
        initialPage = pageStack.push(Qt.resolvedUrl("FirstPage.qml"), {
                                         "filtersObj": filtersObj,
                                         "settingsObj": settingsObj
                                     } )
    }

    property var filtersObj
    property var settingsObj

    function cleanUpFilters() {
        var i, k, fltrs, lbl, unclean, cleared;
        var emptyArray = [], emptyJson = { "calendars": emptyArray };

        i = 0;
        cleared = 0;
        fltrs = emptyJson;
        while (i < filtersObj.calendars.length - 1) {
            lbl = filtersObj.calendars[i].label;
            k = i - 1;
            unclean = 0;
            while (k > 0) {
                if (filtersObj.calendars[k].label === lbl) {
                    unclean++;
                    cleared++;
                }
                k--;
            }
            if (unclean === 0) {
                fltrs.calendars.push(filtersObj.calendars[i]);
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
        var filtersFile, i, cal, adv, time, d=[];

        filtersFile = icsFilter.readFiltersFile();
        //viewFiltersFile.text = filtersFile;

        if (filtersFile.length > 1){
            filtersObj = JSON.parse(filtersFile);
        }
        if (!filtersObj || ! filtersObj.calendars) {
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
        fileOp.setFileName(Globals.settingsFileName, Globals.settingsFilePath);
        jsonStr = fileOp.readTxt();
        jsonObj = JSON.parse(jsonStr);

        console.log("settings:", jsonStr)

        setUpLists(jsonObj);

        return;
    }

    function setFiltersFile() {
        var configPath, i;
        configPath = icsFilter.setFiltersFile();
        i = configPath.indexOf("/", 2); // /home/
        i = configPath.indexOf("/", i+1); // /home/nemo || defaultuser
        configPath = configPath.substring(0, i+1);
        configPath += Globals.settingsFilePath;
        return icsFilter.setFiltersFile(Globals.filtersFileName, configPath);
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

        if (!settingsObj || !settingsObj.filteringProperties
                || settingsObj.filteringProperties.keys().length === 0) {
            filterSettings = {
                "vevent": ["dtstart", "summary", "categories"],
                "vtodo": ["dtstart", "summary", "categories"],
                "vfreetime": ["dtstart", "summary", "categories"],
                "vjournal": ["dtstart", "summary", "categories"]
            }
        } else {
            filterSettings = settingsObj.filteringProperties;
        }

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

            //Globals.settingsObj.filteringProperties = filterSettings;
            settingsObj.filteringProperties = filterSettings;
        }
        return;
    }

    function storeFilters() {
        var filtersFile, result;
        filtersFile = JSON.stringify(filtersObj, null, 2);
        result = icsFilter.overWriteFiltersFile(filtersFile);

        return result;
    }
}
