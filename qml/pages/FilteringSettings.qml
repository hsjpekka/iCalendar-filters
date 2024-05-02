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
        if (settingsObj && settingsObj.filteringProperties) {
            filterProps = settingsObj.filteringProperties
            for (let i in filterProps) {
                cmpList.addComponent(i)
            }
            //settingUp = false
            cmpView.currentIndex = 0
        }
    }

    property var filterProps//: Globals.settingsObj.filteringProperties
    //  { "vevent": ["dtstart", "summary", "categories"],
    //    "vtodo": [-"-], "vfreetime": [-"-], "vjournal": [-"-]
    //  }
    //property bool settingUp: true
    property var settingsObj

    Column {
        id: column
        width: parent.width

        PageHeader {
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
            height: 4*Theme.itemSizeSmall
            spacing: 0// Theme.paddingSmall
            clip: false//

            model: cmpList
            footer: Component {
                Label {
                    anchors.centerIn: parent
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
                for (let i in filterProps) {
                    if (filterProps[i].component === selectedComponent) {
                        for (let k in filterProps[i].properties) {
                            prpList.addProperty(filterProps[i].properties[k].property)
                        }
                    }
                }
            }
        }

        TextField {
            id: txtComponent
            placeholderText: qsTr("component name")
            label: qsTr("component name")
        }

        Button {
            text: qsTr("add component")
            enabled: txtComponent.text > ""
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            onClicked: {
                cmpList.addComponent(txtComponent.text)

            }
        }

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
            height: 4*Theme.itemSizeSmall
            spacing: 0// Theme.paddingSmall
            clip: false//

            model: prpList
            footer: Component {
                Label {
                    anchors.centerIn: parent
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
                            }
                        }
                        MenuItem {
                            text: qsTr("modify")
                            onClicked: {
                                prpList.set(index, txtProperty.text)
                            }
                        }
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

        Button {
            text: qsTr("add property")
            enabled: txtProperty.text > ""
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            onClicked: {
                prpList.addProperty(txtProperty.text)
            }
        }

    }

    function addToCPList(cmp, prp) {
        var arr, ic, isCmp, isProp;
        isCmp = false;
        isProp = false;
        for (let c in filterProps) {
            if (c === cmp) {
                isCmp = true;
                ic = c;
            }
        }
        if (!isCmp) {
            filterProps[cmp] = [];
        }

        if (prp) {
            for (let p in filterProps[ic]) {
                if (filterProps[ic][p] === prp) {
                    isProp = true;
                }
            }
            if (!isProp) {
                arr = filterProps[c];
                if (Array.isArray(arr)) {
                    if (arr.length === 0) {
                        arr = [];
                    }
                    arr.push(prp);
                }
                filterProps[c][p] = arr;
            }
        }

        return;
    }
}
