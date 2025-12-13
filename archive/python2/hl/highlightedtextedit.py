#!/usr/bin/env python
from PyQt4 import QtCore, QtGui
from sx.qt.keywordhl import SearchKeywordHL

class SearchHL(QtGui.QWidget) :
    def __init__(self, parent = None):
        QtGui.QWidget.__init__(self, parent)
        mainLayout = QtGui.QVBoxLayout()
        self.__textedit = HighlightedTextEdit()
        mainLayout.addWidget(self.__textedit)

        hlEnableButton = QtGui.QPushButton(self.tr("&Enable Highlight"))
        self.connect(hlEnableButton, QtCore.SIGNAL("clicked()"), self.onHLEnable)
        mainLayout.addWidget(hlEnableButton)

        hlDisableButton = QtGui.QPushButton(self.tr("&Disable Highlight"))
        self.connect(hlDisableButton, QtCore.SIGNAL("clicked()"), self.onHLDisable)
        mainLayout.addWidget(hlDisableButton)


        self.__searchLineEdit = QtGui.QLineEdit()
        mainLayout.addWidget(self.__searchLineEdit)

        self.setLayout(mainLayout)


        char_format = QtGui.QTextCharFormat()
        char_format.setFont(self.__textedit.font())

        self.__hl = SearchKeywordHL(self.__textedit.document(), char_format)
        self.__textedit.setHighlighter(self.__hl)


    def onHLEnable(self) :
        self.__hl.setKeywords(())
        searchWord = str(self.__searchLineEdit.text()).strip()
        keywords = ( searchWord, )

        self.__hl.setKeywords(keywords)

    def onHLDisable(self) :
        self.__hl.setKeywords(())

class HighlightedTextEdit(QtGui.QTextEdit):
    def __init__(self, parent = None):

        QtGui.QTextEdit.__init__(self, parent)

        self.setFrameShape(QtGui.QFrame.Box)
        self.setFrameShadow(QtGui.QFrame.Plain)
        self.__hl = None

    # The code property is implemented with the getCode() and setCode()
    # methods, and contains the plain text shown in the editor.
    def getCode(self):
        self._code = self.toPlainText()
        return self._code
    def setCode(self, text):
        self.setPlainText(text)

    code = QtCore.pyqtProperty("QString", getCode, setCode)

    # The displayFont property is implemented with the getDisplayFont() and
    # setDisplayFont() methods, and contains the font used to display the
    # text in the editor.
    def getDisplayFont(self):
        return QtGui.QWidget.font(self)
    def setDisplayFont(self, font):
        QtGui.QWidget.setFont(self, font)
        if (not self.__hl == None):
            self.__hl.updateHighlighter(font)
        self.update()

    displayFont = QtCore.pyqtProperty("QFont", getDisplayFont, setDisplayFont)

    def setHighlighter(self, hl) :
        self.__hl = hl

if __name__ == "__main__":

    import sys

    app = QtGui.QApplication(sys.argv)
    searchhl = SearchHL()
    searchhl.show()
    sys.exit(app.exec_())
