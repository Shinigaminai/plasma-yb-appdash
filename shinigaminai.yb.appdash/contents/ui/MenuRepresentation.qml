/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

FocusScope {
    id: root

    focus: true

    Layout.minimumWidth: (sideBar.width + (sideBar.width ? mainRow.spacing : 0)
        + Math.max(units.gridUnit * 14, runnerColumns.width))
    Layout.maximumWidth: Layout.minimumWidth

    Layout.minimumHeight: Math.max(((rootModel.count - rootModel.separatorCount) * rootList.itemHeight)
        + (rootModel.separatorCount * rootList.separatorHeight)
        + searchField.height + (2 * units.smallSpacing), sideBar.margins.top + sideBar.margins.bottom
        + favoriteApps.contentHeight + favoriteSystemActions.contentHeight + sidebarSeparator.height
        + (4 * units.smallSpacing))
    Layout.maximumHeight: Layout.minimumHeight

    signal appendSearchText(string text)

    function reset() {
        plasmoid.hideOnWindowDeactivate = true;

        rootList.currentIndex = -1;

        searchField.text = "";
        searchField.focus = true;
    }

    Row {
        id: mainRow

        height: parent.height

        spacing: units.smallSpacing

        LayoutMirroring.enabled: ((plasmoid.location == PlasmaCore.Types.RightEdge)
            || (Qt.application.layoutDirection == Qt.RightToLeft && plasmoid.location != PlasmaCore.Types.LeftEdge))

        PlasmaCore.FrameSvgItem {
            id: sideBar

            visible: width > 0

            width: (globalFavorites && systemFavorites
                && (globalFavorites.count + systemFavorites.count)
                ? units.iconSizes.medium + margins.left + margins.right : 0)
            height: parent.height

            imagePath: "widgets/frame"
            prefix: "plain"

            SideBarSection {
                id: favoriteApps

                anchors.top: parent.top
                anchors.topMargin: sideBar.margins.top

                height: (sideBar.height - sideBar.margins.top - sideBar.margins.bottom
                    - favoriteSystemActions.height - sidebarSeparator.height - (4 * units.smallSpacing))

                model: globalFavorites

                states: [ State {
                    name: "top"
                    when: (plasmoid.location == PlasmaCore.Types.TopEdge)

                    AnchorChanges {
                        target: favoriteApps
                        anchors.top: undefined
                        anchors.bottom: parent.bottom
                    }

                    PropertyChanges {
                        target: favoriteApps
                        anchors.topMargin: undefined
                        anchors.bottomMargin: sideBar.margins.bottom
                    }
                }]

                Binding {
                    target: globalFavorites
                    property: "iconSize"
                    value: units.iconSizes.medium
                }
            }

            PlasmaCore.SvgItem {
                id: sidebarSeparator

                anchors.bottom: favoriteSystemActions.top
                anchors.bottomMargin: (2 * units.smallSpacing)
                anchors.horizontalCenter: parent.horizontalCenter

                width: units.iconSizes.medium
                height: lineSvg.horLineHeight

                visible: (favoriteApps.model && favoriteApps.model.count
                    && favoriteSystemActions.model && favoriteSystemActions.model.count)

                svg: lineSvg
                elementId: "horizontal-line"

                states: [ State {
                    name: "top"
                    when: (plasmoid.location == PlasmaCore.Types.TopEdge)

                    AnchorChanges {
                        target: sidebarSeparator
                        anchors.top: favoriteSystemActions.bottom
                        anchors.bottom: undefined

                    }

                    PropertyChanges {
                        target: sidebarSeparator
                        anchors.topMargin: (2 * units.smallSpacing)
                        anchors.bottomMargin: undefined
                    }
                }]
            }

            SideBarSection {
                id: favoriteSystemActions

                anchors.bottom: parent.bottom
                anchors.bottomMargin: sideBar.margins.bottom

                model: systemFavorites
                usesPlasmaTheme: true

                states: [ State {
                    name: "top"
                    when: (plasmoid.location == PlasmaCore.Types.TopEdge)

                    AnchorChanges {
                        target: favoriteSystemActions
                        anchors.top: parent.top
                        anchors.bottom: undefined
                    }

                    PropertyChanges {
                        target: favoriteSystemActions
                        anchors.topMargin: sideBar.margins.top
                        anchors.bottomMargin: undefined
                    }
                }]
            }
        }

        ItemListView {
            id: rootList

            anchors.top: parent.top

            width: root.width - sideBar.width - mainRow.spacing
            height: ((rootModel.count - rootModel.separatorCount) * itemHeight) + (rootModel.separatorCount * separatorHeight)

            visible: (searchField.text == "")

            iconsEnabled: false

            model: rootModel

            onKeyNavigationAtListEnd: {
                searchField.focus = true;
            }

            states: [ State {
                name: "top"
                when: (plasmoid.location == PlasmaCore.Types.TopEdge)

                AnchorChanges {
                    target: rootList
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                }
            }]

            Component.onCompleted: {
                rootList.exited.connect(root.reset);
            }
        }

        Row {
            id: runnerColumns

            height: parent.height

            signal focusChanged()

            visible: (searchField.text != "" && runnerModel.count > 0)

            Repeater {
                id: runnerColumnsRepeater

                model: runnerModel

                delegate: RunnerResultsList {
                    id: runnerMatches

                    onKeyNavigationAtListEnd: {
                        searchField.focus = true;
                    }

                    onContainsMouseChanged: {
                        if (containsMouse) {
                            runnerMatches.focus = true;
                        }
                    }

                    onFocusChanged: {
                        if (focus) {
                            runnerColumns.focusChanged();
                        }
                    }

                    function focusChanged() {
                        if (!runnerMatches.focus && runnerMatches.currentIndex != -1) {
                            runnerMatches.currentIndex = -1;
                        }
                    }

                    Keys.onPressed: {
                        var target = null;

                        if (event.key == Qt.Key_Right) {
                            var targets = new Array();

                            for (var i = index + 1; i < runnerModel.count; ++i) {
                                targets[targets.length] = i;
                            }

                            for (var i = 0; i < index; ++i) {
                                targets[targets.length] = i;
                            }

                            for (var i = 0; i < targets.length; ++i) {
                                if (runnerModel.modelForRow(targets[i]).count) {
                                    target = runnerColumnsRepeater.itemAt(targets[i]);
                                    break;
                                }
                            }
                        } else if (event.key == Qt.Key_Left) {
                            var targets = new Array();

                            for (var i = index - 1; i >= 0; --i) {
                                targets[targets.length] = i;
                            }

                            for (var i = runnerModel.count - 1; i > index; --i) {
                                targets[targets.length] = i;
                            }

                            for (var i = 0; i < targets.length; ++i) {
                                if (runnerModel.modelForRow(targets[i]).count) {
                                    target = runnerColumnsRepeater.itemAt(targets[i]);
                                    break;
                                }
                            }
                        }

                        if (target) {
                            event.accepted = true;
                            currentIndex = -1;
                            target.currentIndex = 0;
                            target.focus = true;
                        }
                    }

                    Component.onCompleted: {
                        runnerColumns.focusChanged.connect(focusChanged);
                    }

                    Component.onDestruction: {
                        runnerColumns.focusChanged.disconnect(focusChanged);
                    }
                }
            }
        }
    }

    PlasmaComponents.TextField {
        id: searchField

        anchors.bottom: mainRow.bottom
        anchors.left: parent.left
        anchors.leftMargin: sideBar.width + (sideBar.width ? mainRow.spacing : 0) + units.smallSpacing

        width: (units.gridUnit * 14) - (2 * units.smallSpacing)

        focus: true

        placeholderText: i18n("Search...")
        clearButtonShown: true

        onTextChanged: {
            runnerModel.query = text;
        }

        onFocusChanged: {
            if (focus) {
                // FIXME: Cleanup arbitration between rootList/runnerCols here and in Keys.
                if (rootList.visible) {
                    rootList.currentIndex = -1;
                }

                if (runnerColumns.visible) {
                    runnerColumnsRepeater.itemAt(0).currentIndex = -1;
                }
            }
        }

        states: [ State {
            name: "top"
            when: plasmoid.location == PlasmaCore.Types.TopEdge

            AnchorChanges {
                target: searchField
                anchors.top: mainRow.top
                anchors.bottom: undefined
                anchors.left: parent.left
                anchors.right: undefined
            }

            PropertyChanges {
                target: searchField
                anchors.leftMargin: sideBar.width + mainRow.spacing + units.smallSpacing
                anchors.rightMargin: undefined
            }
        },
        State {
            name: "right"
            when: (plasmoid.location == PlasmaCore.Types.RightEdge && Qt.application.layoutDirection == Qt.LeftToRight)
                || (plasmoid.location == PlasmaCore.Types.LeftEdge && Qt.application.layoutDirection == Qt.RightToLeft)

            AnchorChanges {
                target: searchField
                anchors.top: undefined
                anchors.bottom: mainRow.bottom
                anchors.left: undefined
                anchors.right: parent.right
            }

            PropertyChanges {
                target: searchField
                anchors.leftMargin: undefined
                anchors.rightMargin: sideBar.width + mainRow.spacing + units.smallSpacing
            }
        }]

        Keys.onPressed: {
            if (event.key == Qt.Key_Up) {
                if (rootList.visible) {
                    rootList.showChildDialogs = false;
                    rootList.currentIndex = rootList.model.count - 1;
                    rootList.forceActiveFocus();
                    rootList.showChildDialogs = true;
                }

                if (runnerColumns.visible) {
                    for (var i = 0; i < runnerModel.count; ++i) {
                        if (runnerModel.modelForRow(i).count) {
                            var targetList = runnerColumnsRepeater.itemAt(i);
                            targetList.currentIndex = runnerModel.modelForRow(i).count - 1;
                            targetList.forceActiveFocus();
                            break;
                        }
                    }
                }
            } else if (event.key == Qt.Key_Down) {
                if (rootList.visible) {
                    rootList.showChildDialogs = false;
                    rootList.currentIndex = 0;
                    rootList.forceActiveFocus();
                    rootList.showChildDialogs = true;
                }

                if (runnerColumns.visible) {
                    for (var i = 0; i < runnerModel.count; ++i) {
                        if (runnerModel.modelForRow(i).count) {
                            var targetList = runnerColumnsRepeater.itemAt(i);
                            targetList.currentIndex = 0;
                            targetList.forceActiveFocus();
                            break;
                        }
                    }
                }
            } else if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
                if (runnerColumns.visible && runnerModel.modelForRow(0).count) {
                    runnerModel.modelForRow(0).trigger(0, "", null);
                    plasmoid.expanded = false;
                }
            }
        }

        function appendText(newText) {
            focus = true;
            text = text + newText;
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
            plasmoid.expanded = false;
        }
    }

    Component.onCompleted: {
        appendSearchText.connect(searchField.appendText);

        kicker.reset.connect(reset);
        windowSystem.hidden.connect(reset);
    }
}
