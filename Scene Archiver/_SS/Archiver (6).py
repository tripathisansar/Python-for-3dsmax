"""
Scene_Archiver Alpha V0.5
02/01/2023 
By: Sansar Tripathi

-------------------------------------------------------------------------------
3ds max script to automatically archive currently open maxfile. 

Known Limitations:

* If the maxfile name has additional '_' the shot number will be wrong which will have wrong outputs. Probably Get errors
P.S : this has been addressed. 

"""



from PySide2 import QtWidgets as qw
from PySide2.QtCore import *
from PySide2.QtGui import *
from qtmax import GetQMaxMainWindow
from pymxs import runtime as rt
from os import path,walk
import os
from zipfile import ZipFile
import zipfile
import time
import shutil
import re




global main_Dialog
try:
    main_Dialog.deleteLater()
except:
    pass

initial_msgBox = qw.QMessageBox()
initial_msgBox.setText('File has not been saved. Please save with correct naming convention.')
initial_msgBox.setInformativeText('for eg : PRO1234_ProjectName_M010_EXT_Shotname')

close_msgBox = qw.QMessageBox()
close_msgBox.setText('Are you sure you want to close and cancel all the progress?')
close_msgBox.setStandardButtons(qw.QMessageBox.Yes | qw.QMessageBox.No)
    
    
class ProjectInfo():
    
    maxpath = rt.maxfilepath.split(path.sep)
    maxfileSplit = rt.maxfilename.split('_')
    
    if len(maxfileSplit) < 5:
        maxfile = ['Error','Error','Error','Error','Error']
    else:
        maxfile = maxfileSplit
    
    def __init__(self):
        ...
    
    def getMaxFile():
        return (path.join(rt.maxfilepath, rt.maxfilename))
        
    def getProjectName():
        return (ProjectInfo.maxpath[1])
        
    def getShotNumber():
        return(ProjectInfo.maxfile[ProjectInfo.getShotIndex()])
        
    def getOutputPath():
        ...
    
    def getAssetPath():
        assetDir = path.join(r'01_Assets\01_Maps\Film', ProjectInfo.getShotNumber())
        prodDir = path.join(ProjectInfo.maxpath[0], path.sep, ProjectInfo.maxpath[1], ProjectInfo.maxpath[2])
        finalAssetPath = path.join(prodDir, assetDir)
        return finalAssetPath
        
    def getShotIndex():
        ctr = 0
        for i in ProjectInfo.maxfileSplit:
            if re.findall(r'M\d\d\d',i):
                return ctr
            ctr+=1

class SMTD_sanityCheck():
    def __init__(self):
        ... 
        
    def loadSanityCheck(self):
        # -- Hardcoded path values to be updated in the future
        DeadRep = r'P:' + path.sep
        userScripts = rt.pathConfig.getDir(rt.name('userScripts'))
        sanityCheckDrv = r'C:\Users\tripa\My Drive\04_Scripts\Latest Deadline Submitter\01_sanity_checks' + path.sep
        
        if (str(rt.renderers.current)[0:5]) == 'V_Ray':
            privateSanity =sanityCheckDrv + "PrivateSanity_Vray.ms"
        else:
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
        
        rt.SMTD_sanityChecksToPerform=[]
        rt.FileIn(localGeneralSanity)
            
        rt.SMTD_Private_SanityChecksToPerform=[]
        rt.FileIn(localPrivateSanity)
        
        if len(rt.SMTD_Private_sanityChecksToPerform)!=0:
            rt.SMTD_sanityChecksToPerform += rt.SMTD_Private_SanityCheckstoPerform
        
    def performSanityCheck(self):
        
        #self.loadSanityCheck()
        return (rt.SMTD_performSanityCheck())
        

class Worker(QThread):
    progress = Signal(int)
    progressMax= Signal(int)
    statusText = Signal(str)
    statusTextColor = Signal(str)
    archiveButtonState = Signal(bool)
    stopButtonState = Signal(bool)
    
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
        paths = self.getAssetFilePath()
        progressCounter=0
        projectName = (paths[0].split(path.sep))[1]
        arcDrive = "R:"
        archiveDir =path.join(arcDrive, path.sep, projectName, '04_Archive')
        
        if path.isdir(archiveDir):
            zipFilename = path.join(archiveDir + path.sep + paths[2]+'.zip')
            if not path.isfile(zipFilename):
                self.stopButtonState.emit(True)
                with ZipFile(zipFilename, 'w', zipfile.ZIP_DEFLATED) as zip:
                    if self.readme:
                        zip.writestr('Notes_Please_Read.txt', self.readme)
                    self.statusText.emit(path.basename(paths[1]))
                    zip.write(paths[1], path.basename(paths[1]))  # -- Adds maxfile to archive. Disabled during Testing. Enable before final
                    for dirpath, dirnames, filenames in walk(paths[0]):
                        self.progressMax.emit(len(filenames))
                        for filename in filenames:
                            if self.aborted:
                                self.statusText.emit('Canceled')
                                self.archiveButtonState.emit(True)
                                self.progress.emit(0)
                                return
                            progressCounter+=1
                            self.progress.emit(progressCounter)
                            self.statusText.emit(path.basename(filename))
                            
                            filepath = path.join(paths[0], filename)
                            arcname = path.join(paths[2], filename)
                            zip.write(filepath, arcname)
                self.archiveButtonState.emit(True)
                self.statusText.emit('Archive Finished')
                self.stopButtonState.emit(False)
            else:
                self.statusText.emit('Existing archive found with same shot name. Manually delete or superseed existing archive')
                self.statusTextColor.emit('color:red')
                self.archiveButtonState.emit(True)
                
        else:
            self.statusText.emit('Path For Archive Doesnot Exist : ' + archiveDir)
            self.statusTextColor.emit('color:red')
            self.archiveButtonState.emit(True)
            
    def abort(self):
        self.aborted = True
        self.statusText.emit('Canceling....')
        self.stopButtonState.emit(False)
        
        
class SceneArchiver(qw.QDialog):
    
    def __init__(self, parent= None):
        super().__init__(parent)
        self.initialRenderer = str(rt.renderers.current)[0:5]
        self.setMinimumWidth(700)
        self.setMinimumHeight(400)
        self.setMaximumHeight(500)
        self.resize(0, 0)
        self.setWindowTitle('Scene Archiver')
        
        
        self.init_UI()
        self.init_Info()
        
    def init_UI(self):
        # -- Creating Layouts
        self.main_Layout = qw.QVBoxLayout()
        self.main_Layout.setSpacing(5)
        
        self.horizontal_Layout = qw.QHBoxLayout()
        self.horizontal_Layout.setSpacing(20)
        self.horizontal_Layout.addLayout(self.main_Layout)
        
        self.info_Layout = qw.QVBoxLayout()
        self.info_Layout.setMargin(5)
        
        self.progress_Layout = qw.QVBoxLayout()
        self.progress_Layout.setSpacing(10)
        self.progress_Layout.addLayout(self.horizontal_Layout)
        
        # -- UI widgets
        self.progressBar = qw.QProgressBar(self)
        self.archiveButton = qw.QPushButton('Start Archiving', self)
        self.stopButton = qw.QPushButton('Cancel', self) 
        self.status = qw.QLabel('')
        self.notes = qw.QPlainTextEdit()
        self.label_Notes = qw.QLabel('Notes:')
        
        # -- Info UI Labels
        self.info = qw.QGroupBox('Info:')
        self.projectName = qw.QLabel()
        self.projectName.setFont(QFont('Arial', 8))
        self.shotNumber = qw.QLabel()
        self.shotNumber.setFont(QFont('Arial', 8))
        self.assetPath = qw.QLabel()
        self.assetPath.setFont(QFont('Arial', 8))
        
        # -- Notes Text editor properties
        self.notes.setFixedWidth(330)
        self.notes.setPlaceholderText('Type any notes here')
        
        # -- Start Arrchiving Button properties and events
        self.archiveButton.setFixedHeight(50)
        self.archiveButton.setFixedWidth(330)
        self.archiveButton.setAutoDefault(False) #Prevents button being clicked when Enter is pressed
        self.archiveButton.clicked.connect(self.start_Archive)
        
        # -- Cancel Button properties and events
        self.stopButton.setFixedWidth(330)
        self.stopButton.setAutoDefault(False) #Prevents button being clicked when Enter is pressed
        self.stopButton.setEnabled(False)
        
        # -- Progress Bar properties
        self.progressBar.setFixedHeight(5)
        self.progressBar.setMinimum(0)
        self.progressBar.setMaximum(20)
        self.progressBar.setTextVisible(False)
        
        # -- Info UI groupbox Properties
        self.info.setLayout(self.info_Layout)
        
        # -- Add Widgets to the vertical layout 1 
        self.main_Layout.addWidget(self.label_Notes)
        self.main_Layout.addWidget(self.notes)
        self.main_Layout.addWidget(self.archiveButton)
        self.main_Layout.addWidget(self.stopButton)
        
        self.progress_Layout.addWidget(self.progressBar)
        self.progress_Layout.addWidget(self.status)
        
        # -- Add widgets to info Layout
        self.horizontal_Layout.addWidget(self.info)
        self.info_Layout.addWidget(self.shotNumber)
        self.info_Layout.addWidget(self.projectName)
        self.info_Layout.addWidget(self.assetPath)
        
        self.setLayout(self.progress_Layout)
        
    def init_Info(self):
        # -- Set Info Labels 
        if (str(rt.renderers.current)[0:5]) == 'V_Ray' or (str(rt.renderers.current)[0:5]) == 'Coron':
            self.projectName.setText('Project Name : ' + ProjectInfo.getProjectName())
            self.shotNumber.setText('Shot Number : ' + ProjectInfo.getShotNumber())
            self.assetPath.setText('Asset Path: ' + ProjectInfo.getAssetPath())
            return (True)
        else:
            self.archiveButton.setEnabled(False)
            
            self.shotNumber.setStyleSheet('color:red')
            self.shotNumber.setText('Render Engine not supported.')
            
            self.projectName.setStyleSheet('color:red')
            self.projectName.setText('Supported Renderer V_Ray or Corona.')
            
            self.assetPath.setText('')
            
            self.status.setText('')
            return (False)
        
    def start_Archive(self):
        if self.init_Info():
            SMTD = SMTD_sanityCheck()
            
            if self.initialRenderer != str(rt.renderers.current)[0:5]:
                SMTD.loadSanityCheck()
            
            if SMTD.performSanityCheck():
                self.status.setStyleSheet('color:white')
                self.archiveButton.setEnabled(False)
                self.worker = Worker(self.notes.toPlainText())
                self.worker.start()
                self.worker.progress.connect(self.progressBar.setValue)
                self.worker.progressMax.connect(self.progressBar.setMaximum)
                self.worker.statusText.connect(self.status.setText)
                self.worker.statusTextColor.connect(self.status.setStyleSheet)
                self.worker.archiveButtonState.connect(self.archiveButton.setEnabled)
                self.worker.stopButtonState.connect(self.stopButton.setEnabled)
                self.stopButton.clicked.connect(self.worker.abort)
                
                
            else:
                self.status.setText('Sanity Check Failed !!!')
                self.status.setStyleSheet('color:red')
                
    def closeEvent(self, event):
        try:
            if self.worker.isRunning():
                returnValue = close_msgBox.exec()
                if returnValue == qw.QMessageBox.Yes:
                    self.worker.abort()
                    self.worker.exit()
                    event.accept()
                    rt.destroyDialog(rt.SMTD_SanityCheck_errorReportRollout)
                else:
                    event.ignore()
                    
        except:
            rt.destroyDialog(rt.SMTD_SanityCheck_errorReportRollout)
        
if rt.maxfilename!='':
    SMTD = SMTD_sanityCheck()
    SMTD.loadSanityCheck()
    main_Dialog = SceneArchiver(GetQMaxMainWindow())
    main_Dialog.show()
else:
    initial_msgBox.exec()
