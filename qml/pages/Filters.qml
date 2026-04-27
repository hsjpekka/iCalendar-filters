import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import "../components"
import "../utils/globals.js" as Globals

Dialog {
    id: page

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        readComponentList()
        cmpProperties.setDefaults()
        readPropertyList()
        calendarLbl = filtersObj.calendars[calId].label
        calendarUrl = filtersObj.calendars[calId].url
        newFiltersObj = JSON.parse(JSON.stringify(oldFiltersObj))
        settingUp = false
        readCalendarFilters()
    }

    onDone: {
        if (result === DialogResult.Accepted) {
            composeFilter()
            if (JSON.stringify(newFiltersObj) === JSON.stringify(oldFiltersObj)) {
                filtersModified = false
            } else {
                filtersModified = true
            }
        }
    }

    property string calendarLbl: ""//calendarName.text
    property string calendarUrl: ""
    property int calId
    property bool filtersModified: false
    property string icsFile: ""
    property var newFiltersObj: emptyJson
    property var oldFiltersObj: emptyJson
    property var settingsObj
    property bool settingUp: true

    readonly property bool isAccept: true
    readonly property var emptyJson: JSON.parse(Globals.emptyJson)
    readonly property var emptyCalendar: JSON.parse(Globals.emptyCalendar)
    readonly property var emptyComponent: {"component": "", "properties": []}
    readonly property var emptyProperty: {"property": "", "values": []}
    readonly property var emptyCriteria: {"criteria": "", "value": ""}


    Notification {
        id: nPopUp
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("settings")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("FilteringSettings.qml"), {
                                                    "settingsObj": settingsObj
                                                } )
                    dialog.accepted.connect( function() {
                        var result
                        if (dialog.isModified) {
                            page.settingsObj = JSON.parse(JSON.stringify(dialog.settingsObj))
                            readComponentList()
                            if (cbFilterComponent.currentIndex >= 0) {
                                readPropertyList(cbFilterComponent.value)
                            }
                            fileOp.setFileName(Globals.settingsFileName, Globals.settingsFilePath);
                            result = fileOp.writeTxt(JSON.stringify(page.settingsObj, undefined, 2));
                            if (result === undefined || result === "") {
                                nPopUp.body = fileOp.error();
                                nPopUp.summary = qsTr("Config-file write error.")
                            }
                        }
                    } )
                }
            }

            MenuItem {
                text: qsTr("show files")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("FileContents.qml"), {
                                                    "filtersObj": newFiltersObj,
                                                    "calendarLbl": calendarLbl,
                                                    "origIcsFile": icsFile
                                                } )
                }
            }

            MenuItem {
                text: qsTr("test")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("FilterTest.qml"), {
                                "jsonFilters": newFiltersObj,
                                "calendar": calendarLbl,
                                "origIcsFile": icsFile
                            } )
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: 0//Theme.paddingSmall

            DialogHeader {
                id: header
                title: qsTr("filters for %1").arg(calendarLbl)
            }

            ListModel {
                id: calendarComponents
                ListElement {
                    icalComponent: "vevent"
                    isPass: false
                    limit: 0
                }
                ListElement {
                    icalComponent: "vtodo"
                    isPass: false
                    limit: 0
                }
                ListElement {
                    icalComponent: "vfreebusy"
                    isPass: false
                    limit: 0
                }

                function addComponent(cmp, passOrBlock, percent) {
                    var result;
                    if (getIndex(cmp) < 0) {
                        append({"icalComponent": cmp,
                                   "isPass": passOrBlock,
                                   "limit": percent});
                        result = 0;
                    } else {
                        console.log("component " + cmp + " exists, not added");
                        result = -1;
                    }
                    return result;
                }

                function getIndex(cmp) {
                    var i=0, result = -1, str="";

                    while (i < count && cmp !== undefined) {
                        if (get(i).icalComponent === cmp.toLowerCase()) {
                            result = i;
                            i = count + 1;
                        }
                        i++;
                    }
                    return result;
                }

                function getLimit(cmp) {
                    var i, result;
                    i = getIndex(cmp);
                    if (i >= 0 && i < count) {
                        result = get(i).limit;
                    }
                    return result;
                }

                function getPassOrBlock(cmp) {
                    var i, result;
                    i = getIndex(cmp);
                    if (i >= 0 && i < count) {
                        result = get(i).isPass;
                    }

                    return result;
                }

                function modifyAction(cmp, passBlock) {
                    var i = 0;
                    if (passBlock === true || passBlock === false) {
                        i = getIndex(cmp);
                        if (i >= 0) {
                            set(i, {"isPass": passBlock})
                        } else {
                            console.log("component " + cmp +
                                        " not modified: unknown type")
                        }
                    } else if (passBlock === "accept" || passBlock === "reject") {
                        var pbValue;
                        pbValue = passBlock === "accept";
                        i = getIndex(cmp);
                        if (i >= 0) {
                            set(i, {"isPass": pbValue})
                        } else {
                            console.log("component " + cmp +
                                        " not modified: unknown type")
                        }
                    } else {
                        console.log("component " + cmp +
                                    " not modified: bad parameters - true/false = "
                                    + passBlock)
                    }
                    return;
                }

                function modifyLimit(cmp, percent) {
                    var i = 0;
                    if (percent >= 0 && percent <= 100) {
                        i = getIndex(cmp);
                        if (i >= 0) {
                            set(i, {"limit": percent})
                        } else {
                            console.log("component " + cmp +
                                        " not modified: unknown type")
                        }
                    } else {
                        console.log("component " + cmp +
                                    " not modified: bad parameters - 0-100 = "
                                    + percent)
                    }
                    return;
                }

                function removeComponent(cmp) {
                    var i;
                    i = getIndex(cmp);
                    if (i >= 0 && i < calendarComponents.count) {
                        calendarComponents.remove(i);
                    }
                    return i;
                }
            }

            ComboBox {
                id: cbFilterComponent
                label: qsTr("filter for component") // vevent, vfreebusy, vjournal, vtodo
                menu: ContextMenu {
                    Repeater {
                        model: calendarComponents
                        MenuItem {
                            text: icalComponent
                        }
                    }
                }
                onValueChanged: {
                    if (value != "" && !settingUp) {
                        readPropertyList(value)
                    }
                }

                function setValue(str) {
                    currentIndex = calendarComponents.getIndex(str);
                    return currentIndex;
                }
            }

            TextSwitch {
                id: blockOrPass
                text: checked? qsTr("reading in matching components") :
                               qsTr("leaving out matching components")
                onClicked: {
                    calendarComponents.modifyAction(cbFilterComponent.value, checked)
                    composeFilter()
                }

                function setValue(str) {
                    if (str.toLowerCase() === "accept") {
                        checked = true;
                    } else {
                        checked = false;
                    }
                    return checked;
                }
            }

            TextSwitch {
                id: allOrAnyProperty
                text: checked? qsTr("all properties have to match") :
                               qsTr("a single matching property is enough")
                onClicked: {
                    var limit
                    if (checked) {
                        limit = 100
                    } else {
                        limit = 0
                    }
                    calendarComponents.modifyLimit(cbFilterComponent.value, limit)
                    composeFilter()
                }

                function setValue(str) {
                    if (str*1.0 > 0.5) {
                        checked = true;
                    } else {
                        checked = false;
                    }
                    return checked;
                }
            }

            Item {
                height: Theme.paddingMedium
            }

            ListModel {
                id: cmpProperties

                property var defaultItems: ["dtstart", "summary", "categories"]
                /*
                // class / created / description / geo / last-mod / location / organizer / priority /
                // seq / status / summary / transp / url / recurid /dtend / duration /
                // attach / attendee / categories / comment / contact / exdate / rstatus / related /
                // resources / rdate / x-prop / iana-prop
                */
                /*ListElement {
                    prop: "categories"
                }
                ListElement {
                    prop: "dtstart"
                }
                ListElement {
                    prop: "summary"
                }
                //*/

                function addProperty(prop) {
                    return append({"prop": prop});
                }

                function getIndex(name) {
                    var i, N;
                    N = -1;
                    i = 0;
                    while (i < count && name !== undefined) {
                        if (get(i).prop === name) {
                            N = i;
                            i = count;
                        }
                        i++;
                    }

                    return N;
                }

                function removeProperty(prop) {
                    var i;
                    i = getIndex(prop);
                    if (i >= 0 && i < cmpProperties.count) {
                        cmpProperties.remove(i);
                    }
                    return i;
                }

                function setDefaults() {
                    var i;
                    cmpProperties.clear();
                    i = 0;
                    while (i < defaultItems.length) {
                        addProperty(defaultItems[i]);
                        i++;
                    }
                    return;
                }

                function getPropertyList() {
                    var i, propList;
                    propList = [];
                    i = 0;
                    while (i < count) {
                        propList[i] = get(i).prop;
                        i++;
                    }
                    return propList;
                }
            }

            ComboBox {
                id: cbFilteringProperty
                label: qsTr("filtering property")
                enabled: cmpProperties.count > 0
                menu: ContextMenu {
                    Repeater {
                        model: cmpProperties
                        MenuItem {
                            text: prop
                        }
                    }
                }

                function setValue(str) {
                    currentIndex = cmpProperties.getIndex(str);
                    return currentIndex;
                }
            }

            TextSwitch {
                id: allOrAnyValue
                text: checked? qsTr("all criteria have to match") :
                               qsTr("a single matching criteria is enough")
                onCheckedChanged: {
                    var perCent
                    if (checked) {
                        perCent = 100
                    } else {
                        perCent = 0
                    }

                    filterModel.checkPropertyChanges(cbFilterComponent.value, cbFilteringProperty.value, perCent)
                    composeFilter()
                }

                function setValue(fraction) {
                    if (fraction*1.0 > 0.5) {
                        checked = true;
                    } else {
                        checked = false;
                    }
                    return checked;
                }
            }

            SectionHeader{
                id: shFilters
                text: qsTr("filters")
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 3*Theme.horizontalPageMargin
                text: qsTr("Create a filter")
                onClicked: {
                    var dialog = pageStack.push(
                                Qt.resolvedUrl("PropertyFilter.qml"),
                                {   "isAdd": true,
                                    "filteredCmp": cbFilterComponent.value,
                                    "filteringProp": cbFilteringProperty.value,
                                    "propertyList": cmpProperties.getPropertyList()
                                })
                    dialog.accepted.connect( function () {
                        var percnt;
                        percnt = allOrAnyProperty.checked? 100 : 0
                        filterModel.addFilter(cbFilterComponent.value,
                                              dialog.filteringProp,
                                              dialog.propertyType,
                                              percnt, dialog.criteria,
                                              dialog.filterValue);
                        composeFilter();
                    })

                }
            }

            /*TextSwitch {
                id: tsShowOnlyCurrent
                text: qsTr("only %1.%2-filters").arg(cbFilterComponent.value).arg(cbFilteringProperty.value)
            }//*/

            Item {
                width: parent.width
                height: Theme.paddingMedium
            }

            ListModel {
                id: filterModel
                //{"icsComponent", "icsProperty", "icsPropType",
                //"icsValMatches", "icsCriteria", "icsValue"}

                function addFilter(comp, prop, propType, valMatches, crit, val) {
                    checkPropertyChanges(comp, prop, valMatches);
                    if (comp === undefined || prop === undefined ||
                            crit === undefined || val === undefined ) {
                        return;
                    }
                    if (propType === undefined) {
                        propType = "string";
                    }
                    if (valMatches === undefined) {
                        valMatches = 0;
                    }

                    append({"icsComponent": comp, "icsProperty": prop,
                               "icsPropType": propType, "icsValMatches": valMatches,
                               "icsCriteria": crit, "icsValue": val
                           });
                    return;
                }

                function checkPropertyChanges(comp, prop, valMatches){
                    var i=0, current;
                    while (i < count) {
                        current = get(i);
                        if (comp === current.icsComponent && prop === current.icsProperty) {
                            if (current.icsValMatches !== valMatches){
                                setProperty(i, "icsValMatches", valMatches);
                            }
                        }
                        i++;
                    }
                    return;
                }

                function modifyFilter(i, comp, prop, propType, valMatches,
                                      crit, val) {
                    checkPropertyChanges(comp, prop, valMatches);
                    if (i >= 0 && i < count) {
                        set(i, {"icsComponent": comp,
                                "icsProperty": prop, "icsPropType": propType,
                                "icsValMatches": valMatches,
                                "icsCriteria": crit, "icsValue": val
                            });
                    } else {
                        console.log("index out of filterModel range");
                    }

                }
            }

            SilicaListView {
                id: listViewFilters
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: count < 2 ? Theme.itemSizeSmall + extraSpace:
                                    count*Theme.itemSizeSmall +
                                    (count-1)*spacing + extraSpace
                spacing: Theme.paddingSmall
                clip: false

                model: filterModel
                delegate: filterDelegate

                highlightFollowsCurrentItem: true

                property int lastClicked: -1
                property int extraSpace: 0

                Component {
                    id: filterDelegate
                    ListItem {
                        id: filterListItem
                        visible: !isCmpProp? // && tsShowOnlyCurrent.checked
                                     0 : Theme.itemSizeSmall
                        enabled: delegateLabel.visible
                        contentHeight: delegateLabel.visible?
                                           Theme.itemSizeSmall : 0
                        menu: ContextMenu {
                            onActiveChanged: {
                                if (active) {
                                    listViewFilters.extraSpace = 2*Theme.itemSizeSmall
                                } else {
                                    listViewFilters.extraSpace = 0
                                }
                            }

                            MenuItem {
                                text: qsTr("modify")
                                onClicked: {
                                    filterListItem.modifySelected()
                                }

                            }

                            MenuItem {
                                text: qsTr("delete")
                                onClicked: {
                                    filterListItem.remorseDelete(function () {
                                        filterModel.remove(index)
                                        listViewFilters.currentIndex = -1
                                        page.composeFilter()
                                    } )
                                }
                            }
                        }
                        //*
                        onClicked: {
                            cbFilterComponent.setValue(icsComponent)
                            cbFilteringProperty.setValue(icsProperty)
                        }//*/

                        Label {
                            id: delegateLabel
                            anchors.centerIn: parent
                            text: icsComponent + "." + icsProperty + " " +
                                  icsCriteria + " " + icsValue
                            color: Theme.secondaryColor
                        }

                        property bool isCmpProp: icsComponent === cbFilterComponent.value// && icsProperty === cbFilteringProperty.value

                        function modifySelected() {
                            var dialog = pageStack.push(
                                        Qt.resolvedUrl("PropertyFilter.qml"),
                                        {   "isAdd": false,
                                            "filteredCmp": icsComponent,
                                            "filteringProp": icsProperty,
                                            "propertyType": icsPropType,
                                            "filterValue": icsValue,
                                            "criteria": icsCriteria,
                                            "propertyList": cmpProperties.getPropertyList()
                                        });
                                dialog.accepted.connect( function () {
                                    var percnt;
                                    percnt = allOrAnyProperty.checked? 1 : 0;
                                    filterModel.modifyFilter(
                                                index, cbFilterComponent.value,
                                                dialog.filteringProp,
                                                dialog.propertyType,
                                                percnt, dialog.criteria,
                                                dialog.filterValue);
                                    composeFilter();
                                    return;
                                });
                            return;
                        }
                    }
                }
            }

            VerticalScrollDecorator {}
        }

    }

    // adds propertydata to the list
    function addFilter(filterNr, cmp, prop, type, percnt, crit, value) {
        // if filterNr >= 0, modifies filter filterNr, else adds a filter
        // 0 <= percnt <= 100, 0 == one hit is enough
        var action, propMatches, valMatches, vcomponent;

        if (value === "") {
            return;
        }

        if (filterNr < 0) {
            filterModel.addFilter(cmp, prop, type, percnt, crit, value);
            listViewFilters.currentIndex = filterModel.count - 1;
        } else if (filterNr < filterModel.count) {
            filterModel.modifyFilter(filterNr, cmp, prop, type, percnt, crit, value);
        }

        return;
    }

    function composeFilter() {
        // updating the contents of a json-object is not working
        // a new json-component is created and the old one is removed
        var calN, cals, cmponent, crtr, flters, ic, ifl, ip, n, nc, prop, prperties, vals;
        //calN = {"label": calendarLbl, "filters": [] };
        cmponent = {"component": "", "properties": []};
        prop = {"property": "", "values": []};
        crtr = {"criteria": "", "value": ""};

        //make a new json-object containing the filters for the current component
        flters = [];
        prperties = [];
        ic = 0;
        while (ic < filterModel.count) {
            //{"icsComponent", "icsProperty", "icsPropType",
            //"icsValMatches", "icsCriteria", "icsValue"}
            ifl = isComponentIncluded(flters, filterModel.get(ic).icsComponent);
            if (ifl >= 0) { // rewrite the component
                cmponent = flters[ifl];
                prperties = cmponent.properties;
            } else { // new component
                cmponent["component"] = filterModel.get(ic).icsComponent;
                prperties = [];
            }

            if (calendarComponents.getPassOrBlock(cmponent["component"]) === isAccept) {
                cmponent["action"] = "accept";
            } else {
                cmponent["action"] = "reject";
            }
            cmponent["propMatches"] = calendarComponents.getLimit(cmponent["component"]);

            ip = isPropertyIncluded(prperties, filterModel.get(ic).icsProperty, filterModel.get(ic).icsPropType);
            if (ip >= 0) { // rewrite filters for the property
                prop = prperties[ip];
                vals = prop.values;
            } else { // new property
                prop["property"] = filterModel.get(ic).icsProperty;
                vals = [];
            }

            prop["type"] = filterModel.get(ic).icsPropType;
            prop["valueMatches"] = filterModel.get(ic).icsValMatches;

            crtr["criteria"] = filterModel.get(ic).icsCriteria;
            crtr["value"] = filterModel.get(ic).icsValue;
            vals.push(crtr);
            prop["values"] = vals;

            if (ip >= 0) {
                prperties[ip] = prop;
            } else {
                prperties.push(prop);
            }
            cmponent["properties"] = prperties;

            if (ifl >= 0) {
                flters[ifl] = cmponent;
            } else {
                flters.push(cmponent);
                ifl = flters.length - 1;
            }
            ic++;
            // without parse(stringify()) new array items overwrite existing ones
            cmponent = JSON.parse(JSON.stringify(cmponent));
            flters = JSON.parse(JSON.stringify(flters));
        }

        newFiltersObj.calendars[calId]["filters"] = flters;

        return;
    }

    function isComponentIncluded(filters, comp) {
        var i, result;
        result = -1;
        i = 0;
        while (i < filters.length) {
            if (filters[i].component.toLowerCase() === comp.toLowerCase()) {
                result = i;
                i = filters.length;
            }
            i++;
        }

        return result;
    }

    function isPropertyIncluded(propertyList, prName, prType) {
        var i, result;
        result = -1;
        i = 0;
        while (i < propertyList.length) {
            if (propertyList[i].property.toLowerCase() === prName.toLowerCase() &&
                    propertyList[i].type.toLowerCase() === prType.toLowerCase() ){
                result = i;
            }
            i++;
        }

        return result;
    }

    function readCalendarFilters(label) {
        var i, N, calN, fltr0, prop0;

        if (label === undefined || label === "") {
            label = calendarLbl
        }

        N = -1;
        i = 0;
        while (i < newFiltersObj.calendars.length) {
            calN = newFiltersObj.calendars[i];
            if (calN["label"] === label) {
                N = i;
                i = newFiltersObj.calendars.length;
            }
            i++;
        }

        if (N >= 0) {
            setUpFields(calN.filters);
        } else {
            setUpFields();
        }

        return;
    }

    function readComponentList() {
        var cbValue, currentCmp, i, k, kArr, result = -1;
        if (cbFilterComponent.currentIndex >= 0) {
            currentCmp = cbFilterComponent.value;
        }

        calendarComponents.clear();
        if (settingsObj === undefined) {
            calendarComponents.addComponent("vevent", false, 0);
            calendarComponents.addComponent("vtodo", false, 0);
            calendarComponents.addComponent("vfreebusy", false, 0);
            result = 0;
        } else {
            for (k in settingsObj.filteringProperties) {
                calendarComponents.addComponent(k, false, 0);
                result++;
            }
            if (result >= 0) {
                result++;
            }
        }

        if (currentCmp) {
            i = 0;
            while (i < calendarComponents.count) {
                if (calendarComponents.get(i).icalComponent === currentCmp) {
                    cbFilterComponent.currentIndex = i;
                    i = calendarComponents.count;
                }
                i++;
            }
        } else {
            if (calendarComponents.count > 0) {
                cbFilterComponent.currentIndex = 0;
            }
        }

        return result;
    }

    function readFilters(fltrs) {
        var ic, ip, iprop, iv, ivals, n;
        ic=0;
        n=0;
        while (ic < fltrs.length) {
            ip = 0;
            calendarComponents.modifyAction(fltrs[ic].component, fltrs[ic].action);
            calendarComponents.modifyLimit(fltrs[ic].component, fltrs[ic].propMatches);
            while (ip < fltrs[ic].properties.length) {
                iprop = fltrs[ic].properties[ip];
                iv = 0;
                while (iv < iprop.values.length) {
                    ivals = iprop.values[iv];
                    filterModel.addFilter(fltrs[ic].component, iprop.property,
                                          iprop.type, iprop.valueMatches,
                                          ivals.criteria, ivals.value);
                    iv++;
                    n++;
                }
                ip++;
            }
            ic++;
        }
        return n;
    }

    function readPropertyList(cmp) {
        // read iCalendar component properties to fill cbFilteringProperty
        // defaults
        // { "vevent": ["dtstart", "summary", "categories"],
        //   "vtodo": -"-, "vfreetime": -"-, "vjournal": -"- }
        //
        var cArr, i, j, pArr, nr=-1;

        if (settingsObj === undefined) {
            console.log("no settingsObj");
            return 0;
        }

        cArr = Object.keys(settingsObj.filteringProperties);
        if (cmp === undefined) {
            if (cbFilterComponent.value > "") {
                cmp = cbFilterComponent.value;
            } else if ( cArr.length > 0) {
                cmp = cArr[0];
            } else {
                console.log("no cmp, no cArr[]", cArr);
                return 0;
            }
        }

        for (i in settingsObj.filteringProperties) {
            if (i === cmp) {
                nr = 0;
                pArr = settingsObj.filteringProperties[i];
                //console.log(cmp, ":", pArr);
                if (Array.isArray(pArr)) {
                    cmpProperties.clear();
                    j = 0;
                    while (j < pArr.length) {
                        cmpProperties.addProperty(pArr[j]);
                        nr++;
                        j++;
                    }

                } else {
                    cmpProperties.setDefaults();
                }
            }
        }

        return nr;
    }

    function setUpFields(filters) {
        var fltr0, prop0;
        if (filters === undefined) {
            cbFilterComponent.currentIndex = 0
            cbFilteringProperty.currentIndex = 0
        } else if (filters[0] && filters[0].component) {
            fltr0 = filters[0];
            cbFilterComponent.setValue(fltr0.component);
            blockOrPass.setValue(fltr0.action);
            allOrAnyProperty.setValue(fltr0.propMatches);
            readFilters(filters);
            prop0 = fltr0.properties[0];
            cbFilteringProperty.setValue(prop0.property);
            allOrAnyValue.setValue(prop0.valueMatches);
        } else {
            setUpFields();
        }
        return;
    }

}
