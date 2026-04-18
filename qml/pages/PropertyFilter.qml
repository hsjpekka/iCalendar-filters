import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    allowedOrientations: Orientation.All
    onDone: {
        filteringProp = cbFilteringProperty.value
        propertyType = cbPropertyType.pTypeToString()
        filterValue = filterValueTF.text
        criteria = cbFilteringCriteria.criteria
    }
    Component.onCompleted: {
        console.log("alussa", criteria)
        cmpProperties.setUp()
        cbFilteringProperty.setValue(filteringProp)
        if (propertyType > "") {
            cbPropertyType.setValue(propertyType)
        } else {
            cbPropertyType.setDefaultType(filteringProp)
        }
        cbFilteringCriteria.setValue(criteria)
        filterValueTF.text = filterValue
        console.log("asetettu ", filteredCmp, filteringProp, propertyType, filterValue, criteria)
    }

    property string criteria//: cbFilteringCriteria.criteria
    property string filteredCmp
    property string filteringProp
    property string propertyType
    property string filterValue
    property bool isAdd: true
    property var propertyList

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                title: isAdd? qsTr("Add %1-filter").arg(filteredCmp) : qsTr("Modify %1-filter").arg(filteredCmp)
            }

            ListModel {
                id: cmpProperties

                property var defaultItems: ["summary"]//["dtstart", "summary", "categories"]

                function getIndex(str) {
                    var i, k;
                    i = 0;
                    k = -1;
                    while (i < count) {
                        if (get(i).prop === str) {
                            k = i;
                            i = count;
                        }
                        i++;
                    }
                    return k;
                }

                function setUp() {
                    var i;
                    i = 0;
                    while (i < propertyList.length) {
                        append( { "prop": propertyList[i] } );
                        i++;
                    }
                    return i;
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
                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        cbPropertyType.setDefaultType()
                    }
                }

                function setValue(str) {
                    currentIndex = cmpProperties.getIndex(str);
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
                        }
                    }
                    MenuItem {
                        text: qsTr("date")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.pdate
                        }
                    }
                    MenuItem {
                        text: qsTr("time")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.ptime
                        }
                    }
                    MenuItem {
                        text: qsTr("number")
                        onClicked: {
                            cbPropertyType.ptype = cbPropertyType.pnumber
                        }
                    }
                }

                property int ptype: pstring
                readonly property int pstring: 1
                readonly property int pdate: 2
                readonly property int ptime: 3
                readonly property int pnumber: 4
                onPtypeChanged: {
                    filterValueTF.text = ""
                    if (ptype === pstring) {
                        cbFilteringCriteria.setValue("s")
                    } else if (ptype === pdate || ptype === ptime) {
                        cbFilteringCriteria.setValue(">=")
                    } else if (ptype === pnumber) {
                        cbFilteringCriteria.setValue("=")
                    }
                }

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
                    if (typeNr === undefined) {
                        typeNr = ptype;
                    }
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

                function setDefaultType(str) {
                    var prp;
                    if (str > "" ) {
                        prp = str;
                    } else {
                        prp = cbFilteringProperty.value;
                    }

                    if (prp === "dtstart") {
                        setValue(ptime)
                    } else {
                        setValue(pstring)
                    }
                    return;
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
                    console.log("merkit", str, N);
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
                                criteria = comparison
                            }
                        }
                    }
                }

                property string criteria: ""

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
                    if (cbPropertyType.ptype === cbPropertyType.pstring) {
                        result = criteriaStrings.getIndex(str);
                    } else if (cbPropertyType.ptype === cbPropertyType.ptime ||
                               cbPropertyType.ptype === cbPropertyType.pdate) {
                        result = criteriaTime.getIndex(str);
                    } else if (cbPropertyType.ptype === cbPropertyType.pnumber) {
                        result = criteriaNumber.getIndex(str);
                    }
                    currentIndex = result;
                    criteria = str;
                    return result;
                }
            }

            TextField {
                id: filterValueTF
                label: cbPropertyType.pdate == cbPropertyType.ptype? "dd.mm. || mm/dd"
                            : cbPropertyType.ptime == cbPropertyType.ptype? "hh:mm"
                            : qsTr("value")
                placeholderText: qsTr("set filtering value")
                width: parent.width
                EnterKey.onClicked: {
                    focus = false
                }

                hideLabelOnEmptyField: false
            }

        }

    }

}
