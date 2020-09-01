import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
    id: conversationPage
    anchors.fill: parent
    topPadding: mainView.innerSpacing

    property var headline
    property var textInputField
    property string textInput
    property real widthFactor: 0.9
    property int threadAge: 84000 * 7 // one week in seconds
    property int threadCount: 0

    property int currentConversationMode: 0
    property var currentId: 0
    property var currentConversationModel: personContentModel
    property var messages: new Array
    property var calls: new Array

    property string m_ID:        "id"      // the id of the message or content
    property string m_TEXT:      "text"    // large main text, regular
    property string m_STEXT:     "stext"   // small text beyond the main text, grey
    property string m_IMAGE:     "image"   // preview image
    property string m_IS_SENT:   "sent"    // true if the content was sent by user
    property string m_KIND:      "kind"    // kind of content like sms or mms
    property string m_DATE:      "date"    // date in milliseconds of the item

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    onTextInputChanged: {
        console.log("Conversation | text input changed")
        currentConversationModel.update(textInput)
    }

    Component.onCompleted: {
        textInput.text = ""
        currentConversationModel.update("")
    }

    function updateConversationPage (mode, id, name) {
        console.log("Conversation | Update conversation mode: " + mode + " with id " + id)

        if (mode !== currentConversationMode || currentId !== id) {
            currentConversationMode = mode
            currentConversationModel.clear()
            currentConversationModel.modelArr = new Array

            switch (mode) {
                case mainView.conversationMode.Person:
                    headline.text = name
                    currentId = id
                    currentConversationModel = personContentModel

                    // Get contact by Id
                    var numbers = new Array
                    for (var i = 0; i < mainView.contacts.length; i++) {
                        var contact = mainView.contacts[i]
                        if (contact["id"] === currentId) {
                            console.log("Conversation | Found contact " + contact["name"])
                            if (contact["phone.mobile"] !== undefined) numbers.push(contact["phone.mobile"])
                            if (contact["phone.work"] !== undefined) numbers.push(contact["phone.work"])
                            if (contact["phone.home"] !== undefined) numbers.push(contact["phone.home"])
                            if (contact["phone.other"] !== undefined) numbers.push(contact["phone.other"])
                            break
                        }
                    }
                    threadCount = 2
                    loadConversation({"personId": id, "numbers": numbers})
                    loadCalls({"match": name})
                    break;
                case mainView.conversationMode.Thread:
                    headline.text = name
                    currentId = id
                    currentConversationModel = threadContentModel
                    threadCount = 1
                    loadConversation({"threadId": id})
                    break;
                default:
                    console.log("Conversation | Unknown conversation mode")
                    break;
            }
        }
    }

    function loadConversation(filter) {
        console.log("Conversations | Will load messages")
        messages = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.conversationAction", filter)
    }

    function loadCalls(filter) {
        console.log("Conversation | Will load calls")
        calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callConversationAction", filter)
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: ListView.PullBackHeader

        header: Column {
            id: header
            width: parent.width
            Label {
                id: headerLabel
                topPadding: mainView.innerSpacing
                x: mainView.innerSpacing
                text: qsTr("Conversation")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                Binding {
                    target: conversationPage
                    property: "headline"
                    value: headerLabel
                }
            }
            TextField {
                id: textField
                padding: mainView.innerSpacing
                x: mainView.innerSpacing
                width: parent.width -mainView.innerSpacing * 2
                placeholderText: qsTr("Filter messages ...")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0
                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }

                Binding {
                    target: conversationPage
                    property: "textInput"
                    value: textField.displayText.toLowerCase()
                }

                Binding {
                    target: conversationPage
                    property: "textInputField"
                    value: textField
                }

                Button {
                    id: deleteButton
                    visible: textField.activeFocus
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right

                    onClicked: {
                        textField.text = ""
                        textField.focus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                border.color: "transparent"
                color: "transparent"
                height: 1.1
            }
        }

        model: currentConversationModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: messageBox.height + mainView.innerSpacing

            Rectangle {
                id: messageBox
                color: "transparent"
                width: parent.width
                implicitHeight: messageColumn.height

                Column {
                    id: messageColumn
                    spacing: 6.0
                    width: parent.width

                    Label {
                        id: receivedMessage
                        anchors.left: parent.left
                        topPadding: mainView.innerSpacing
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.m_TEXT !== undefined ? model.m_TEXT : ""
                        lineHeight: 1.1
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        visible: !model.m_IS_SENT && model.m_TEXT !== undefined
                    }
                    Label {
                        anchors.left: parent.left
                        id: receivedDate
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: model.m_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.m_STEXT
                        font.pointSize: mainView.smallFontSize
                        clip: true
                        opacity: 0.7
                        visible: !model.m_IS_SENT
                    }
                    Label {
                        id: sentMessage
                        anchors.right: parent.right
                        topPadding: mainView.innerSpacing
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.m_TEXT !== undefined ? model.m_TEXT : ""
                        lineHeight: 1.1
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                        horizontalAlignment: Text.AlignRight
                        visible: model.m_IS_SENT && model.m_TEXT !== undefined
                    }
                    Label {
                        id: sentDate
                        anchors.right: parent.right
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: model.m_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.m_STEXT
                        font.pointSize: mainView.smallFontSize
                        clip: true
                        opacity: 0.7
                        horizontalAlignment: Text.AlignRight
                        visible: model.m_IS_SENT
                    }
                    Image {
                        id: messageImage
                        x: model.m_IS_SENT ? messageBox.width * (1 -  widthFactor) + mainView.innerSpacing : mainView.innerSpacing
                        horizontalAlignment: Image.AlignLeft
                        width: messageBox.width * widthFactor
                        source: model.m_IMAGE !== undefined ? model.m_IMAGE : ""
                        fillMode: Image.PreserveAspectFit

                        Desaturate {
                            anchors.fill: messageImage
                            source: messageImage
                            desaturation: 1.0
                        }
                    }
                }
            }

            onClicked: {
                // todo: do anything with the selected message
            }
        }
    }

    ListModel {
        id: personContentModel

        property var modelArr: new Array

        function loadData() {
            console.log("Conversation | Load data for person's content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {m_ID: "message." + message["id"]}

                cMessage.m_TEXT = message["body"]

                if (message["isMMS"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • MMS"
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (message["image"] !== undefined) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
                }

                cMessage.m_DATE = message["date"]

                modelArr.push(cMessage)
            })

            conversationPage.calls.forEach(function (call, index) {
                var cCall = {m_ID: "call." + call["id"]}

                cCall.m_STEXT = mainView.parseTime(Number(call["date"])) + " • Call"
                cCall.m_IS_SENT = call["isSent"]

                modelArr.push(cCall)
            })

            modelArr.sort(function(a,b) {
                return a.m_DATE - b.m_DATE
            })
        }

        function update(text) {
            console.log("Conversation | Update person's content with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Conversation | people's content model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].m_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).m_ID
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).m_ID
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Conversation | Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Conversation | Will append " + filteredModelItem.m_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            listView.positionViewAtEnd()
        }

        function executeSelection(item, typ) {
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    ListModel {
        id: threadContentModel

        property var modelArr: []

        function loadData() {
            console.log("Conversation | Load data for thread content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {m_ID: message["id"]}

                cMessage.m_TEXT = message["body"]

                if (message["isMMS"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • MMS"
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (message["image"] !== undefined) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
                }

                modelArr.push(cMessage)
            })

            modelArr.sort(function(a,b) {
                return a.m_DATE - b.m_DATE
            })
        }

        function update (text) {
            console.log("Conversation | Update model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Conversation | Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].m_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).m_ID
                existingGridDict[modelItemName] = true
            }

            // Remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).m_ID
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Conversation | Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // Add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Conversation | Will append " + filteredModelItem.m_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            listView.positionViewAtEnd()
        }

        function executeSelection(item, type) {
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.conversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.messages = message["messages"]
//                message["messages"].forEach(function (message, index) {
//                    for (const [messageKey, messageValue] of Object.entries(message)) {
//                        console.log("Conversation | * " + messageKey + ": " + messageValue)
//                    }
//                })
                conversationPage.currentConversationModel.loadData()
                conversationPage.currentConversationModel.update(conversationPage.textInput)
            } else if (type === "volla.launcher.callConversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.calls = message["calls"]
                message["calls"].forEach(function (call, index) {
                    for (const [callKey, callValue] of Object.entries(call)) {
                        console.log("Collections | * " + callKey + ": " + callValue)
                    }
                })
                conversationPage.currentConversationModel.loadData()
                conversationPage.currentConversationModel.update(conversationPage.textInput)
            }
            threadCount = threadCount - 1
            console.log("Conversation | Thread count is " + threadCount)
//            if (threadCount < 1) {
//                mainView.updateSpinner(false)
//            }
        }
    }
}
