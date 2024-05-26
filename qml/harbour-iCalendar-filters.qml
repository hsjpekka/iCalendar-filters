import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "utils/globals.js" as Globals

ApplicationWindow {
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        var i
        setFiltersFile()
        i = readFilters()
        if (i > 0) {
            cleanUpFiltersFile()
        }
        initialPage = pageStack.push(Qt.resolvedUrl("pages/FirstPage.qml"), {
                                         "filtersObj": filtersObj
                                     } )
    }

    property var filtersObj: { "calendars": [] };

    function cleanUpFiltersFile() {
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
        var filtersStr, i, cal, adv, time, d=[];

        filtersStr = icsFilter.readFiltersFile();
        //viewFiltersFile.text = filtersFile;
        console.log(filtersStr);

        if (filtersStr.length > 1){
            filtersObj = JSON.parse(filtersStr);
        }
        if (!filtersObj || !filtersObj.calendars) {
            return -1;
        }

        return filtersObj.calendars.length;
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

    function storeFilters() {
        var filtersFile, result;
        filtersFile = JSON.stringify(filtersObj, null, 2);
        result = icsFilter.overWriteFiltersFile(filtersFile);

        return result;
    }
}
