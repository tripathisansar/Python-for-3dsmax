from PySide2 import QtWidgets as qw
from PySide2.QtCore import *
from qtmax import GetQMaxMainWindow
from pymxs import runtime as rt
from os import path,walk
import os
from zipfile import ZipFile
import zipfile
import time
import shutil




global main_Dialog
try:
    main_Dialog.close()
except:
    pass


class SMTD_sanityCheck():
    def __init__(self):
        ... 
        
    def loadSanityCheck(self):
        # -- Hardcoded path values to be updated in the future
        DeadRep = r'P:' + path.sep
        userScripts = rt.pathConfig.getDir(rt.name('userScripts'))
        sanityCheckDrv = r'C:\Users\tripa\My Drive\04_Scripts\Latest Deadline Submitter\01_sanity_checks' + path.sep
        privateSanity =sanityCheckDrv + "PrivateSanity_Corona.ms"
        
        
        localPrivateSanity = userScripts + "\\SubmitMaxToDeadline_SanityCheck_Private.ms"
        generalSanity = DeadRep+r"submission\3dsmax\Main\SubmitMaxToDeadline_SanityCheck_General.ms"
        localGeneralSanity = userScripts + "\\SubmitMaxToDeadline_SanityCheck_General.ms"
        
        
        if path.exists(privateSanity):
            if path.exists(localPrivateSanity):
                os.remove(localPrivateSanity)
                shutil.copyfile(privateSanity, localPrivateSanity)
        
        if path.exists(generalSanity):
            if path.exists(localGeneralSanity):
                os.remove(localGeneralSanity)
                shutil.copyfile(generalSanity, localGeneralSanity)
        
        rt.FileIn(localGeneralSanity)
        rt.FileIn(localPrivateSanity)
        
        if rt.SMTD_Private_sanityChecksToPerform.count!=0:
            rt.SMTD_sanityChecksToPerform += rt.SMTD_Private_SanityCheckstoPerform
    
    def performSanityCheck(self):
        
        self.loadSanityCheck()
        return (rt.SMTD_performSanityCheck())
        

class Worker(QThread):
    progress = Signal(int)
    progressMax= Signal(int)
    statusText = Signal(str)
    buttonState = Signal(bool)
    aborted = False
    def __init__(self, userNotes):
        QThread.__init__(self)
        self.readme = userNotes
        
    def getAssetFilePath(self):
        maxfilepath = rt.maxfilepath
        maxfilename = rt.maxfilename
        maxpath = rt.maxfilepath.split(path.sep)
        shotNumber = maxfilename.split('_')[2]
        assetDir = path.join(r'01_Assets\01_Maps\Film', shotNumber)
        prodDir = path.join(maxpath[0], path.sep, maxpath[1], maxpath[2])
        finalAssetPath = path.join(prodDir, assetDir)
        maxfile = path.join(maxfilepath, maxfilename)
        return (finalAssetPath, maxfile ,shotNumber)
        
    def run(self):
        self.buttonEnabled(False)
        paths = self.getAssetFilePath()
        progressCounter=0
        projectName = (paths[0].split(path.sep))[1]
        arcDrive = "R:"
        archiveDir =path.join(arcDrive, path.sep, projectName, '04_archive')
        
        zipFilename = path.join(archiveDir + path.sep + paths[2]+'.zip')
        with ZipFile(zipFilename, 'w', zipfile.ZIP_DEFLATED) as zip:
            if self.readme:
                zip.writestr('Notes_Please_Read.txt', self.readme)
            self.statusText.emit(path.basename(paths[1]))
            #zip.write(paths[1], path.basename(paths[1]))  # -- Adds maxfile to archive. Disabled during Testing. Enable before final
            for dirpath, dirnames, filenames in walk(paths[0]):
                self.progressMax.emit(len(filenames))
                for filename in filenames:
                    if self.aborted:
                        self.statusText.emit('Canceled')
                        self.buttonState.emit(True)
                        self.progress.emit(0)
                        return
                    progressCounter+=1
                    self.progress.emit(progressCounter)
                    self.statusText.emit(path.basename(filename))
                    
                    filepath = path.join(paths[0], filename)
                    arcname = path.join(paths[2], filename)
                    zip.write(filepath, arcname)
            
    def abort(self):
        self.aborted = True
        self.statusText.emit('Canceling....')
        
        
    def buttonEnabled(self, bool):
        buttonStatus = bool
        
class SceneArchiver(qw.QDialog):
    
    def __init__(self, parent= None):
        super().__init__(parent)
        
        self.setFixedWidth(400)
        self.setWindowTitle('Scene Archiver')
        
        self.init_UI()
        
    def init_UI(self):
        # -- Creating Layout
        self.main_Layout = qw.QVBoxLayout()
        self.main_Layout.setSpacing(5)
        
        # -- UI widgets
        self.progressBar = qw.QProgressBar(self)
        self.archiveButton = qw.QPushButton('Start Archiving', self)
        self.stopButton = qw.QPushButton('Cancel', self) 
        self.status = qw.QLabel('')
        self.notes = qw.QPlainTextEdit()
        self.label_Notes = qw.QLabel('Notes:')
        
        # -- Start Arrchiving Button properties and events
        self.archiveButton.setFixedHeight(50)
        self.archiveButton.setAutoDefault(False) #Prevents button being clicked when Enter is pressed
        self.archiveButton.clicked.connect(self.start_Archive)
        
        # -- Cancel Button properties and events
        self.stopButton.setAutoDefault(False) #Prevents button being clicked when Enter is pressed
        
        self.notes.setPlaceholderText('Type any notes here')
        
        # -- Progress Bar properties
        self.progressBar.setFixedHeight(5)
        self.progressBar.setMinimum(0)
        self.progressBar.setMaximum(20)
        self.progressBar.setTextVisible(False)
        
        #-- Add Widgets to the layout
        self.main_Layout.addWidget(self.label_Notes)
        self.main_Layout.addWidget(self.notes)
        self.main_Layout.addWidget(self.archiveButton)
        self.main_Layout.addWidget(self.stopButton)
        self.main_Layout.addWidget(self.progressBar)
        self.main_Layout.addWidget(self.status)
        
        
        self.setLayout(self.main_Layout)
        
    def start_Archive(self):
        
        SMTD = SMTD_sanityCheck()
        
        if SMTD.performSanityCheck():
            self.status.setStyleSheet('color:white')
            self.archiveButton.setEnabled(False)
            self.worker = Worker(self.notes.toPlainText())
            self.worker.start()
            self.worker.progress.connect(self.progressBar.setValue)
            self.worker.progressMax.connect(self.progressBar.setMaximum)
            self.worker.statusText.connect(self.status.setText)
            self.worker.buttonState.connect(self.archiveButton.setEnabled)
            self.stopButton.clicked.connect(self.worker.abort)
        else:
            self.status.setText('Sanity Check Failed')
            self.status.setStyleSheet('color:red')
        
            
    def test(self):
        SMTD = SMTD_sanityCheck()
        SMTD.performSanityCheck()
    
    def stopTest(self):
        print('stopped')
    
main_Dialog = SceneArchiver(GetQMaxMainWindow())
main_Dialog.show()