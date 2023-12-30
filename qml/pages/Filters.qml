import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        console.log("calendar", calendarLbl, ", url", calendarUrl)
        readCalendarFilters()
        settingUp = false
    }
    Component.onDestruction: {
        closing()
    }

    signal closing()

    property string calendarLbl: ""//calendarName.text
    property string calendarUrl: ""
    property int calId
    property string icsFile: ""
    property var jsonFilters: {"calendars": [] }
    property bool filtersModified: false
    property string reminderFullDay: ""
    property string reminderMinutes: ""
    property bool settingUp: true

    readonly property bool isAccept: true

    ListModel {
        id: filterModel
        //{"icsComponent", "icsProperty", "icsPropType",
        //"icsValMatches", "icsCriteria", "icsValue"}

        function addFilter(comp, prop, propType,//, reject, propMatches, prop, propType,
                           valMatches, crit, val) {
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

            append({"icsComponent": comp,
                       "icsProperty": prop,
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

        function modifyFilter(i, comp, prop, //reject, propMatches, prop,
                              propType, valMatches, crit, val) {
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

    Component {
        id: filterDelegate
        ListItem {
            contentHeight: Theme.itemSizeSmall
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("delete")
                    onClicked: {
                        filterModel.remove(index)
                        composeJson()
                    }
                }
                MenuItem {
                    text: qsTr("modify")
                    onClicked: {
                        addFilter(index)
                        composeJson()
                    }
                }
            }
            onClicked: {
                // click to select and unselect the item
                settingUp = true
                cbFilterComponent.setValue(icsComponent) //currentIndex = calendarComponents.getIndex(icsComponent)
                cbFilterProperty.setValue(icsProperty) //cbFilterProperty.currentIndex = eventProperties.getIndex(icsProperty)
                cbPropertyType.setValue(icsPropType)
                allOrAnyValue.setValue(icsValMatches) //allOrAnyValue.checked = icsValMatches > 0.5
                cbFilteringCriteria.setValue(icsCriteria)//cbFilteringCriteria.selectedComparison = icsCriteria
                filterValueTF.text = icsValue
                settingUp = false
                if (listViewFilters.currentIndex === index) {
                    listViewFilters.currentIndex = -1
                } else {
                    listViewFilters.currentIndex = index
                }
            }

            Label {
                anchors.centerIn: parent
                text: icsComponent + "." + icsProperty + " " +
                      icsCriteria + " " + icsValue
                color: Theme.secondaryColor
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("reset")
                onClicked: {
                    filterModel.clear()
                    readCalendarFilters()
                }
            }

            MenuItem {
                text: qsTr("test")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("FilterTest.qml"), {
                                "jsonFilters": jsonFilters,
                                "calendar": calendarLbl,
                                "icsFile": icsFile } )
                }
            }

            MenuItem {
                text: qsTr("add")
                enabled: filterValueTF.text != ""
                onClicked: {
                    newFilter()
                }
            }

        }

        Column {
            id: column
            width: parent.width
            spacing: 0//Theme.paddingSmall

            PageHeader {
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

            }

            ComboBox {
                id: cbFilterComponent
                label: qsTr("filters for")
                menu: ContextMenu {
                    Repeater {
                        model: calendarComponents
                        MenuItem {
                            text: icalComponent
                        }
                    }
                }

                function setValue(str) {
                    currentIndex = calendarComponents.getIndex(str);
                    return currentIndex;
                }
            }

            TextSwitch {
                id: blockOrPass
                text: checked? qsTr("read in matching components") :
                               qsTr("leave out matching components")
                onClicked: {
                    calendarComponents.modifyAction(cbFilterComponent.value, checked)
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
                text: checked? qsTr("all filters have to match") :
                               qsTr("a single matching property is enough")
                onClicked: {
                    var limit
                    if (checked) {
                        limit = 100
                    } else {
                        limit = 0
                    }
                    calendarComponents.modifyLimit(cbFilterComponent.value, limit)
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

            SectionHeader{
                id: shFilters
                text: qsTr("filters")
            }

            SilicaListView {
                id: listViewFilters
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: count > 3 ? 4*Theme.itemSizeSmall : count > 1?
                                        count*Theme.itemSizeSmall : 2*Theme.itemSizeSmall
                spacing: 0// Theme.paddingSmall
                clip: false//

                model: filterModel
                footer: Component {
                    Label {
                        text: "-"
                        width: listViewFilters.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: filterModel.count == 0
                        color: Theme.secondaryHighlightColor
                    }
                }

                delegate: filterDelegate

                highlight: Rectangle {
                    color: Theme.highlightBackgroundColor
                    height: listViewFilters.currentItem? listViewFilters.currentItem.height : 0
                    width: listViewFilters.width
                    radius: Theme.paddingMedium
                    opacity: Theme.opacityLow
                }

                highlightFollowsCurrentItem: true

                property int lastClicked: -1
            }

            ListModel {
                id: eventProperties
                // class / created / description / geo /
                // last-mod / location / organizer / priority /
                // seq / status / summary / transp /
                // url / recurid /dtend / duration /
                // attach / attendee / categories / comment /
                // contact / exdate / rstatus / related /
                // resources / rdate / x-prop / iana-prop
                ListElement {
                    prop: "categories"
                }
                ListElement {
                    prop: "dtstart"
                }
                ListElement {
                    prop: "summary"
                }

                function addProperty(prop) {
                    return append({"prop": prop});
                }

                function getIndex(name) {
                    var i, N;
                    N = -1;
                    i = 0;
                    while (i < eventProperties.count && name !== undefined) {
                        if (eventProperties.get(i).prop === name) {
                            N = i;
                            i = eventProperties.count;
                        }
                        i++;
                    }

                    console.log("järjestysnumero", N)

                    return N;
                }
            }

            ComboBox {
                id: cbFilterProperty
                label: qsTr("filtering property")
                enabled: eventProperties.count > 0
                menu: ContextMenu {
                    Repeater {
                        model: eventProperties
                        MenuItem {
                            text: prop
                        }
                    }
                }
                onCurrentIndexChanged: {
                    if (!settingUp && currentIndex >= 0) {
                        if (value === "dtstart") {
                            cbPropertyType.setValue(cbPropertyType.ptime)
                        } else {
                            cbPropertyType.setValue(cbPropertyType.pstring)
                        }
                    }
                }

                function setValue(str) {
                    currentIndex = eventProperties.getIndex(str);
                    return currentIndex;
                }
            }

            ComboBox {
                id: cbPropertyType
                label: qsTr("type of property")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("string")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.pstring
                            console.log("nyt tyyppi:", cbPropertyType.ptype, cbPropertyType.pTypeToString(cbPropertyType.ptype))
                        }
                    }
                    MenuItem {
                        text: qsTr("date")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.pdate
                            console.log("nyt tyyppi:", cbPropertyType.ptype, cbPropertyType.pTypeToString(cbPropertyType.ptype))
                        }
                    }
                    MenuItem {
                        text: qsTr("time")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.ptime
                            console.log("nyt tyyppi:", cbPropertyType.ptype, cbPropertyType.pTypeToString(cbPropertyType.ptype))
                        }
                    }
                    MenuItem {
                        text: qsTr("number")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.pnumber
                            console.log("nyt tyyppi:", cbPropertyType.ptype, cbPropertyType.pTypeToString(cbPropertyType.ptype))
                        }
                    }
                }

                property int ptype: pstring
                readonly property int pstring: 1
                readonly property int pdate: 2
                readonly property int ptime: 3
                readonly property int pnumber: 4

                function getIndex(nro) {
                    var result;
                    result = -1;
                    if (nro === pstring) {
                        result = pstring - 1;
                    } else if (nro === pdate) {
                        result = pdate - 1;
                    } else if (nro === ptime) {
                        result = ptime - 1;
                    } else if (nro === pnumber){
                        result = pnumber - 1;
                    }

                    return result;
                }

                function pTypeToString(typeNr) {
                    var result;
                    if (typeNr === pstring) {
                        result = "string";
                    } else if (typeNr === pdate) {
                        result = "date";
                    } else if (typeNr === ptime) {
                        result = "time";
                    } else if (typeNr === pnumber) {
                        result = "number";
                    }

                    return result;
                }

                function setValue(str) {
                    var result;
                    result = -1;
                    if (str === undefined) {
                        str = "string";
                    }
                    if (typeof str === typeof "aa") {
                        if (str.toLowerCase() === "string") {
                            result = pstring - 1;
                            ptype = pstring;
                        } else if (str.toLowerCase() === "date") {
                            result = pdate - 1;
                            ptype = pdate;
                        } else if (str.toLowerCase() === "time") {
                            result = ptime - 1;
                            ptype = ptime;
                        } else if (str.toLowerCase() === "number"){
                            result = pnumber - 1;
                            ptype = pnumber;
                        }
                    } else {
                        result = getIndex(str);
                        ptype = result + 1;
                    }

                    currentIndex = result;

                    return result;
                }
            }

            TextSwitch {
                id: allOrAnyValue
                text: checked? qsTr("value has to match all filters") :
                               qsTr("a single matching filter is enough")

                function setValue(fraction) {
                    if (fraction*1.0 > 0.5) {
                        checked = true;
                    } else {
                        checked = false;
                    }
                    return checked;
                }
            }

            ListModel {
                id: criteriaStrings
                ListElement {
                    description: qsTr("equal to")
                    comparison: "="
                }
                ListElement {
                    description: qsTr("not equal to")
                    comparison: "!="
                }
                ListElement {
                    description: qsTr("contains")
                    comparison: "s"
                }
                ListElement {
                    description: qsTr("doesn't contain")
                    comparison: "!s"
                }

                function getIndex(str) {
                    var i, N;
                    N = -1;
                    i = 0;
                    while (i < criteriaStrings.count && str !== undefined) {
                        if (criteriaStrings.get(i).comparison === str) {
                            N = i;
                            i = criteriaStrings.count;
                        }
                        i++;
                    }
                    return N;
                }
            }

            ListModel {
                id: criteriaTime
                ListElement {
                    description: qsTr("equal to")
                    comparison: "="
                }
                ListElement {
                    description: qsTr("not equal to")
                    comparison: "!="
                }
                ListElement {
                    description: qsTr("earliest at")
                    comparison: ">="
                }
                ListElement {
                    description: qsTr("latest at")
                    comparison: "<="
                }

                function getIndex(str) {
                    var i, N;
                    N = -1;
                    i = 0;
                    while (i < criteriaTime.count && str !== undefined) {
                        if (criteriaTime.get(i).comparison === str) {
                            N = i;
                            i = criteriaTime.count;
                        }
                        i++;
                    }
                    return N;
                }
            }

            ListModel {
                id: criteriaNumber
                ListElement {
                    description: qsTr("equal to")
                    comparison: "="
                }
                ListElement {
                    description: qsTr("not equal to")
                    comparison: "!="
                }
                ListElement {
                    description: qsTr("larger than or equal to")
                    comparison: ">="
                }
                ListElement {
                    description: qsTr("smaller than or equal to")
                    comparison: "<="
                }

                function getIndex(str) {
                    var i, N;
                    N = -1;
                    i = 0;
                    while (i < criteriaNumber.count && str !== undefined) {
                        if (criteriaNumber.get(i).comparison === str) {
                            N = i;
                            i = criteriaNumber.count;
                        }
                        i++;
                    }
                    return N;
                }
            }

            ComboBox {
                id: cbFilteringCriteria
                enabled: cbPropertyType.ptype >= 0
                label: qsTr("criteria")
                menu: ContextMenu {
                    id: criteriaMenu3
                    Repeater {
                        model: cbPropertyType.ptype == cbPropertyType.pstring? criteriaStrings :
                                    (cbPropertyType.ptype == cbPropertyType.pnumber?
                                         criteriaNumber : criteriaTime)
                        MenuItem {
                            text: description
                            onClicked: {
                                cbFilteringCriteria.setValue(comparison)
                                console.log(cbFilteringCriteria.selectedComparison() + ", " + description + ", " + comparison)
                            }
                        }
                    }
                }

                function selectedComparison() {
                    var result;
                    if (currentIndex >= 0) {
                        if (cbPropertyType.ptype == cbPropertyType.pnumber) {
                            result = criteriaNumber.get(currentIndex).comparison
                        } else if (cbPropertyType.ptype == cbPropertyType.pstring) {
                            result = criteriaStrings.get(currentIndex).comparison
                        } else if (cbPropertyType.ptype == cbPropertyType.ptime ||
                                   cbPropertyType.ptype == cbPropertyType.pdate) {
                            result = criteriaTime.get(currentIndex).comparison
                        }
                    }
                    return result;
                }

                function setValue(str) {
                    var result, tp = "";
                    result = -1;
                    console.log(str, "type", cbPropertyType.ptype)
                    if (cbPropertyType.ptype === cbPropertyType.pstring) {
                        result = criteriaStrings.getIndex(str);
                    } else if (cbPropertyType.ptype === cbPropertyType.ptime ||
                               cbPropertyType.ptype === cbPropertyType.pdate) {
                        result = criteriaTime.getIndex(str);
                    } else if (cbPropertyType.ptype === cbPropertyType.pnumber) {
                        result = criteriaNumber.getIndex(str);
                    }
                    currentIndex = result;
                    return result;
                }
            }

            TextField {
                id: filterValueTF
                label: cbPropertyType.pdate == cbPropertyType.ptype? "dd.mm. || mm/dd"
                            : cbPropertyType.ptime == cbPropertyType.ptype? "hh:mm"
                            : qsTr("value")
                placeholderText: qsTr("filtering value")
                width: parent.width
                EnterKey.onClicked: {
                    focus = false
                    if (filterModel.count == 0) {
                        newFilter()
                    }
                }

                hideLabelOnEmptyField: false
            }

            SectionHeader{
                text: viewFiltersFile.i === 0 ? qsTr("<b>ics-file</b> <i>filter</i>")
                                              : qsTr("<i>ics-file</i> <b>filter</b>")
                textFormat: Text.StyledText
            }

            TextArea {
                id: viewFiltersFile
                width: parent.width
                font.pixelSize: Theme.fontSizeMedium
                readOnly: true
                text: icsFile
                onClicked: {
                    if (i === 0) {
                        text = JSON.stringify(jsonFilters, null, 2)
                    } else {
                        text = icsFile
                        i = -1
                    }

                    i++
                }

                property int i: 0
            }

            VerticalScrollDecorator {}
        }

    }

    // adds propertydata to the list
    function addFilter(filterNr) { // if filterNr >= 0, modifies a filter
        var action, propMatches, valMatches, vcomponent;

        if (allOrAnyValue.checked) {
            valMatches = 100;
        } else {
            valMatches = 0.0;
        }

        vcomponent = cbFilterComponent.value;
        console.log("vcomponent " + vcomponent);

        if (filterNr >= 0) {
            filterModel.modifyFilter(filterNr, vcomponent, //action, propMatches,
                                  cbFilterProperty.value, cbPropertyType.pTypeToString(cbPropertyType.ptype),
                                  valMatches, cbFilteringCriteria.selectedComparison(),
                                  filterValueTF.text);
        } else {
            filterModel.addFilter(vcomponent, //action, propMatches,
                                  cbFilterProperty.value, cbPropertyType.pTypeToString(cbPropertyType.ptype),
                                  valMatches, cbFilteringCriteria.selectedComparison(),
                                  filterValueTF.text);
            listViewFilters.currentIndex = filterModel.count - 1;
        }

        return;
    }

    function composeJson() {
        var calN, cals, cmponent, crtr, flters, ic, ifl, ip, n, nc, prop, prperties, vals;
        calN = {"label": calendarLbl, "filters": [] };
        cmponent = {"component": "", "properties": []};
        prop = {"property": "", "values": []};
        crtr = {"criteria": "", "value": ""};

        cals = jsonFilters.calendars;
        nc = cals.length;
        n = 0;
        while (n < nc) {
            if (cals[n].label > "" && calendarLbl.toLocaleLowerCase().match(cals[n].label.toLocaleLowerCase())) {
                //calN = cals[n];
                nc = n;
                n = cals.length;
            }
            n++;
        }

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

            ip = isPropertyIncluded(prperties, filterModel.get(ic).icsProperty);
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

        calN["filters"] = flters;

        if (nc < cals.length) {
            if (cals[nc].url > "") {
                calN["url"] = cals[nc].url;
            }

            cals[nc] = calN;
        } else {
            cals.push(calN);
        }

        jsonFilters.calendars = cals;
        viewFiltersFile.text = JSON.stringify(jsonFilters);
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

    function isPropertyIncluded(propertyList, prName) {
        var i, result;
        result = -1;
        i = 0;
        while (i < propertyList.length) {
            if (propertyList[i].property.toLowerCase() === prName.toLowerCase()){
                result = i;
            }
            i++;
        }

        return result;
    }

    function newFilter() {
        addFilter();
        composeJson();
        return;
    }

    function readCalendarFilters(label) {
        var i, N, calN, fltr0, prop0;

        if (label === undefined || label === "") {
            label = calendarLbl
        }

        N = -1;
        i = 0;
        while (i < jsonFilters.calendars.length) {
            calN = jsonFilters.calendars[i];
            if (calN["label"] === label) {
                N = i;
                i = jsonFilters.calendars.length;
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

    function setUpFields(filters) {
        var fltr0, prop0;
        if (filters === undefined) {
            cbFilteringCriteria.currentIndex = 0
            //cbFilteringCriteria.selectedComparison = criteriaStrings.get(cbFilteringCriteria.currentIndex).comparison
            cbPropertyType.setValue(cbPropertyType.pstring)
            cbFilterComponent.currentIndex = 0
            cbFilterProperty.currentIndex = 0
        } else if (filters[0] && filters[0].component) {
            fltr0 = filters[0];
            cbFilterComponent.setValue(fltr0.component);
            blockOrPass.setValue(fltr0.action);
            allOrAnyProperty.setValue(fltr0.propMatches);
            readFilters(filters);
            prop0 = fltr0.properties[0];
            cbFilterProperty.setValue(prop0.property);
            cbPropertyType.setValue(prop0.type);
            allOrAnyValue.setValue(prop0.valueMatches);
            cbFilteringCriteria.setValue(prop0.values[0].criteria);
            filterValueTF.text = prop0.values[0].value;
        } else {
            setUpFields();
        }
        return;
    }

}
