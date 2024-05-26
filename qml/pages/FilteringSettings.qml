import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/globals.js" as Globals

/*
 *     "filters": [ // only one item per component type - uses only one if multiple found
 *     	 { "component": "vevent",
 *         "properties": [ // only one item per property - uses only one if multiple found
 *         { "property": "categories",
 *           "values": [
 *           { "criteria": "s", // =, !=, <>, <, >, <=, >=, s, !s (substring)
 *             "value": "ottelu"
 *           }]
 *         },
 *         { "property": "dtstart",
 *           "values": [
 *           { "criteria": "<",
 *             "value": "31.5."
 *           }]
 *         }]
 *       }
 *     ]
// */
Dialog {
    id: page
    Component.onCompleted: {
        console.log("isoin", Theme.opacityOverlay, "suuri", Theme.opacityHigh, "pieni", Theme.opacityLow, "olematon", Theme.opacityFaint)
        console.log(JSON.stringify(settingsObj))
        if (settingsObj && settingsObj.filteringProperties) {
            filterProps = settingsObj.filteringProperties
            //var i=0, cArr
            //cArr = filterProps.keys()
            //while (i < cArr.length) {
            //    cmpList.addComponent(cArr[i])
            //    i++
            //}

            var i
            for (i in filterProps) {
                cmpList.addComponent(i)
            }
            //settingUp = false
            newFilterProps = filterProps
            cmpView.currentIndex = 0
        } else {
            console.log("miksei asetuksia")
            console.log(JSON.stringify(settingsObj))
        }
    }
    onAccepted: {
        if (JSON.stringify(filterProps) === JSON.stringify(newFilterProps)) {
            isModified = false
        } else {
            isModified = true
        }

        settingsObj.filteringProperties = newFilterProps
    }

    property var filterProps//: Globals.settingsObj.filteringProperties
    //  { "vevent": ["dtstart", "summary", "categories"],
    //    "vtodo": [-"-], "vfreetime": [-"-], "vjournal": [-"-]
    //  }
    //property bool settingUp: true
    property bool isModified: false
    property var newFilterProps
    property var settingsObj

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Filtering Settings")
            }

            SectionHeader {
                text: qsTr("Calendar components")
            }

            ListModel {
                id: cmpList

                function addComponent(cmp) {
                    var i;
                    i = find(cmp);
                    if (i < 0) {
                        cmpList.append({"cmp": cmp});
                    }
                    return i;
                }

                function find(cmp) {
                    var i, n;
                    i = 0;
                    n = -1;
                    while (i < cmpList.count) {
                        if (cmpList.get(i).cmp === cmp) {
                            n = i;
                        }
                        i++;
                    }

                    return n;
                }

                function getValue(i) {
                    var result;
                    if (i>=0 && i < count) {
                        result = get(i).cmp;
                    }
                    return result;
                }

                function removeComponent(cmp) {
                    var i;
                    i = find(cmp);
                    if (i >= 0) {
                        cmpList.remove(i);
                    }
                    return i;
                }

                function setComponent(ind, cmp) {
                    var i;
                    i = find(cmp);
                    if (i >= 0) {
                        cmpList.set(ind, {"cmp": cmp});
                    }
                    return i;
                }
            }

            SilicaListView {
                id: cmpView
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: 3*Theme.itemSizeSmall
                spacing: 0// Theme.paddingSmall
                clip: true//

                model: cmpList
                footer: Component {
                    Label {
                        //anchors.centerIn: parent
                        text: "-"
                        visible: cmpList.count < 1
                        color: Theme.secondaryColor
                    }
                }

                delegate: Component {
                    id: cmpDelegate
                    ListItem {
                        contentHeight: Theme.itemSizeSmall
                        menu: ContextMenu {
                            MenuItem {
                                text: qsTr("delete")
                                onClicked: {
                                    if (cmpList.count > 0) {
                                        if (index > 0) {
                                            cmpView.currentIndex = index -1
                                        } else {
                                            cmpView.currentIndex = index
                                        }
                                    }
                                    cmpList.remove(index)
                                    composeFilteringProps()
                                }
                            }
                            MenuItem {
                                text: qsTr("modify")
                                onClicked: {
                                    cmpList.set(index, txtComponent.text)
                                }
                            }
                        }
                        onClicked: {
                            cmpView.currentIndex = index
                        }

                        Label {
                            anchors.centerIn: parent
                            text: cmp
                            color: Theme.secondaryColor
                        }
                    }
                }

                highlight: Rectangle {
                    color: Theme.highlightBackgroundColor
                    height: cmpView.currentItem? cmpView.currentItem.height : 0
                    width: cmpView.width
                    radius: Theme.paddingMedium
                    opacity: Theme.opacityLow
                }

                highlightFollowsCurrentItem: true

                onCurrentIndexChanged: {
                    console.log("valittu vaihtui", currentIndex)
                    prpList.clear()
                    var selectedComponent = cmpList.getValue(currentIndex)
                    var pArr
                    pArr = newFilterProps[selectedComponent]
                    if (pArr) {
                        var i = 0;
                        while(i < pArr.length) {
                            prpList.addProperty(pArr[i])
                            i++
                        }
                    }
                }
            }

            TextField {
                id: txtComponent
                placeholderText: qsTr("component name")
                label: qsTr("component name")
                EnterKey.onClicked: {
                    focus = false
                }
            }

            ComboBox {
                id: cbCmpAction
                label: qsTr("action")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                opacity: txtComponent.text > ""? 1.0 : Theme.opacityOverlay
                //labelColor: txtComponent.text > ""? Theme.primaryColor : Theme.secondaryColor
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("add")
                        enabled: txtComponent.text > ""
                        onClicked: {
                            cmpList.addProperty(txtComponent.text)
                            txtComponent.text = ""
                            cmpView.currentIndex = -1
                            cbCmpAction.currentIndex = -1
                            cbCmpAction.value = ""
                            composeFilteringProps()
                        }
                    }
                    MenuItem {
                        text: qsTr("modify")
                        enabled: txtComponent.text > "" && cmpView.currentIndex >= 0
                        onClicked: {
                            cmpList.set(cmpView.currentIndex, txtComponent.text)
                            txtComponent.text = ""
                            //cmpView.currentIndex = -1
                            cbCmpAction.currentIndex = -1
                            cbCmpAction.value = ""
                            composeFilteringProps()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.backgroundGlowColor//Theme.secondaryColor
                    radius: Theme.paddingMedium
                }
            }

            //Button {
            //    text: qsTr("add component")
            //    enabled: txtComponent.text > ""
            //    x: Theme.horizontalPageMargin
            //    width: parent.width - 2*x
            //    onClicked: {
            //        cmpList.addComponent(txtComponent.text)
            //    }
            //}

            SectionHeader {
                text: qsTr("Component properties")
            }

            ListModel {
                id: prpList

                function addProperty(prop) {
                    var i;
                    i = find(prop);
                    if (i < 0) {
                        prpList.append({"prop": prop});
                    }
                    return i;
                }

                function getValue(i) {
                    if (i < count && i >= 0) {
                        return get(i).prop;
                    }
                    return;
                }

                function find(prop) {
                    var i, n;
                    i = 0;
                    n = -1;
                    while (i < prpList.count) {
                        if (prpList.get(i).prop === prop) {
                            n = i;
                        }
                        i++;
                    }

                    return n;
                }

                function removeProperty(prop) {
                    var i;
                    i = find(prop);
                    if (i >= 0) {
                        prpList.remove(i);
                    }
                    return i;
                }
            }

            SilicaListView {
                id: prpView
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: 3*Theme.itemSizeSmall
                spacing: 0// Theme.paddingSmall
                clip: true//

                model: prpList
                footer: Component {
                    Label {
                        //anchors.centerIn: parent
                        text: "-"
                        visible: prpList.count < 1
                        color: Theme.secondaryColor
                    }
                }

                delegate: Component {
                    id: propertyDelegate
                    ListItem {
                        contentHeight: Theme.itemSizeSmall
                        menu: ContextMenu {
                            MenuItem {
                                text: qsTr("delete")
                                onClicked: {
                                    if (prpList.count > 0) {
                                        if (index > 0) {
                                            prpView.currentIndex = index -1
                                        } else {
                                            prpView.currentIndex = index
                                        }
                                    }
                                    prpList.remove(index)
                                    composeFilteringProps()
                                }
                            }
                            //MenuItem {
                            //    text: qsTr("modify")
                            //    onClicked: {
                            //        prpList.set(index, txtProperty.text)
                            //    }
                            //}
                        }
                        onClicked: {
                            prpView.currentIndex = index
                        }

                        Label {
                            anchors.centerIn: parent
                            text: prop
                            color: Theme.secondaryColor
                        }
                    }
                }

                highlight: Rectangle {
                    color: Theme.highlightBackgroundColor
                    height: prpView.currentItem? prpView.currentItem.height : 0
                    width: prpView.width
                    radius: Theme.paddingMedium
                    opacity: Theme.opacityLow
                }

                highlightFollowsCurrentItem: true

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < count) {
                        txtProperty.text = prpList.getValue(currentIndex)
                    }

                }
            }

            TextField {
                id: txtProperty
                placeholderText: qsTr("property name")
                label: qsTr("property name")
                EnterKey.onClicked: {
                    focus = false
                }
            }

            ComboBox {
                id: cbPrpAction
                label: qsTr("modify") + " | " + qsTr("add")
                opacity: txtProperty.text > ""? 1 : 0.5*(Theme.opacityHigh + Theme.opacityOverlay)
                //enabled: txtProperty.text > ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("add")
                        enabled: txtProperty.text > ""
                        onClicked: {
                            prpList.addProperty(txtProperty.text)
                            txtProperty.text = ""
                            prpView.currentIndex = -1
                            cbPrpAction.currentIndex = -1
                            cbPrpAction.value = ""
                            composeFilteringProps()
                        }
                    }
                    MenuItem {
                        text: qsTr("modify")
                        enabled: txtProperty.text > "" && prpView.currentIndex >= 0
                        onClicked: {
                            prpList.set(prpView.currentIndex, txtProperty.text)
                            txtProperty.text = ""
                            //prpView.currentIndex = -1
                            cbPrpAction.currentIndex = -1
                            cbPrpAction.value = ""
                            composeFilteringProps()
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.backgroundGlowColor //Theme.secondaryColor
                    radius: 0.5*Theme.fontSizeTiny
                }
            }

            Rectangle {
                color: "transparent"
                height: Theme.paddingMedium
                width: 1
            }

        }
    }

    function addToCPList(cmp, prp) {
        var arr, c, ic, isCmp, isProp, p;
        isCmp = false;
        isProp = false;
        for (c in newFilterProps) {
            if (c === cmp) {
                isCmp = true;
                ic = c;
            }
        }
        if (!isCmp) {
            newFilterProps[cmp] = [];
        }

        if (prp) {
            for (p in newFilterProps[ic]) {
                if (newFilterProps[ic][p] === prp) {
                    isProp = true;
                }
            }
            if (!isProp) {
                arr = newFilterProps[c];
                if (Array.isArray(arr)) {
                    if (arr.length === 0) {
                        arr = [];
                    }
                    arr.push(prp);
                }
                newFilterProps[c][p] = arr;
            }
        }

        return;
    }

    function composeFilteringProps() {
        var cmp, fProps, ic, ip, pArr;
        fProps = {};
        ic = 0;
        while (ic < cmpList.count) {
            cmp = cmpList.getValue(ic);
            if (ic === cmpView.currentIndex) {
                pArr = [];
                ip = 0;
                while (ip < prpList.count) {
                    pArr.push(prpList.getValue(ip));
                    ip++;
                }
                fProps[cmp] = pArr;
            } else {
                fProps[cmp] = newFilterProps[cmp];
            }
            ic++;
        }
        console.log(JSON.stringify(newFilterProps), "  >>>  ", JSON.stringify(fProps))
        newFilterProps = fProps;

        return;
    }
}
