"""
Scene_Archiver Alpha V0.7
19/01/2023 
By: Sansar Tripathi

-------------------------------------------------------------------------------
3ds max Python script to automatically archive currently open maxfile. 

Update V0.7
19/01/2023

- Zip file gets deleted if user cancels the operation
- Added feature to save maxfile before archiving if file has not been saved previously
- UI improvement
    - Shows a text saying Performing sanity check when sanity check takes time
    - Shows status as saving max file when max file is being saved
    - Red Info text when the the filename is not based on the standard naming convention
    - Added Archiving : "Name of file" in the status bar when files are being archived
- Fixed error with getshotnumber function when there is no shot number in the filename. Now it return ERRR which gets displayed in the info section in RED.
- Thread gets deleted when the task is finished. 



Update V0.6 
09/01/2023

-Fixed get Info method during archiving. Now uses ProjectInfo Class to get all the info.
-Avoids issue when getting shot number when there is '_' in project name. 
-Removed getFinalAsset path method from the Scene Archiver class.

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
from pathlib import Path



# Destroying dialog before we create a new one to avoid multiple dialogs. 
global main_Dialog
try:
    main_Dialog.deleteLater()
except:
    pass

# Exception Handling if the file has not been saved. Called at the begining of script execution before creating the UI.
initial_msgBox = qw.QMessageBox()
initial_msgBox.setText('File has not been saved. Please save with correct naming convention.')
initial_msgBox.setInformativeText('for eg : PRO1234_ProjectName_M010_EXT_Shotname')

# Message box to appear when the Close button is clicked while the Archive process is going
close_msgBox = qw.QMessageBox()
close_msgBox.setText('Are you sure you want to close and cancel all the progress?')
close_msgBox.setStandardButtons(qw.QMessageBox.Yes | qw.QMessageBox.No)
    
# class that provides methods to get different aspects of the project like filename, shotName, shotNumber , etc.
class ProjectInfo():
    
    maxpath = rt.maxfilepath.split(path.sep) # splitting the file path to get individual components
    maxfileSplit = rt.maxfilename.split('_') # splitting the maxfilename to get individual components
    
    # standard naming convention dictates when filename is split with '_' token there should be min of 5 items. If its less than 5 it replaces the maxfilesplit with 5 Error strings.
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
        if (ProjectInfo.getShotIndex() == False): # Check to see if shotnumber M000 pattern exist in the filename. If not return "ERRR" which gets displayed in the UI in RED to let user know something is wrong.
            return "ERRR"
        else:
            return(ProjectInfo.maxfile[ProjectInfo.getShotIndex()])
        
    def getOutputPath():
        ...
    
    def getAssetPath():
        assetDir = path.join(r'01_Assets\01_Maps\Film', ProjectInfo.getShotNumber())
        prodDir = path.join(ProjectInfo.maxpath[0], path.sep, ProjectInfo.maxpath[1], ProjectInfo.maxpath[2])
        finalAssetPath = path.join(prodDir, assetDir)
        return finalAssetPath
        
    def getShotIndex():  # Looks for a pattern in maxfilesplit to find shot number and returns the index value within the array which is used when getShotNumber method is called.
        ctr = 0
        for i in ProjectInfo.maxfileSplit:
            if re.findall(r'M\d\d\d',i):
                return ctr
            ctr+=1
        return False

# custom SanityCheck class to help load files required for sanity checks at a different stage during script execution.
class SMTD_sanityCheck():
    def __init__(self):
        ... 
    
    # Method that loads required sanity check files both General and Private based on given path. 
    def loadSanityCheck(self):
        # -- Hardcoded path values to be updated in the future
        DeadRep = r'P:' + path.sep
        userScripts = rt.pathConfig.getDir(rt.name('userScripts'))
        sanityCheckDrv = r'B:\Sansars Scripts\Scene Archiver\01_SanityChecks' + path.sep
        
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
    
    # Method performs sanity check 
    def performSanityCheck(self):
        
        #self.loadSanityCheck()
        return (rt.SMTD_performSanityCheck())
        

# Creation of a worker class inherited from QThread. All the archiving task takes place within the worker thread.

class Worker(QThread):
    progress = Signal(int) #--Progress Bar update 
    progressMax= Signal(int) #--Progress Bar maximum value based on number of files to be archived
    statusText = Signal(str) #-- Update status bar text to show the progress.
    statusTextColor = Signal(str) #-- Update status bar text color. (RED if something is wrong, WHITE if everything is normal)
    archiveButtonState = Signal(bool) #--Signal to enable disable main archive button based on the progress within the worker thread.
    stopButtonState = Signal(bool) #--Signal to enable disable cancel button
    
    aborted = False
    def __init__(self, userNotes): #--userNotes : argument to store notes from the UI to the worker thread to create a text file within the archive.
        QThread.__init__(self)
        self.readme = userNotes 
  
    def run(self):
        progressCounter=0
        shotNumber = ProjectInfo.getShotNumber()
        projectName = ProjectInfo.getProjectName()
        maxfile = ProjectInfo.getMaxFile()
        finalAssetPath = ProjectInfo.getAssetPath()
        arcDrive = "R:"
        archiveDir =path.join(arcDrive, path.sep, projectName, '04_Archive')
        
        if path.isdir(archiveDir):
            zipFilename = path.join(archiveDir + path.sep + shotNumber +'.zip')
            if not path.isfile(zipFilename):
                self.stopButtonState.emit(True)
                with ZipFile(zipFilename, 'w', zipfile.ZIP_DEFLATED) as zip:
                    if self.readme:
                        zip.writestr('Notes_Please_Read.txt', self.readme)
                    self.statusText.emit("Archiving : "+path.basename(maxfile))
                    zip.write(maxfile, path.basename(maxfile))  # -- Adds maxfile to archive. Disabled during Testing. Enable before final
                    for dirpath, dirnames, filenames in walk(finalAssetPath):
                        self.progressMax.emit(len(filenames))
                        for filename in filenames:
                            if self.aborted:
                                self.statusText.emit('Canceled')
                                self.archiveButtonState.emit(True)
                                self.progress.emit(0)
                            else:
                                progressCounter+=1
                                self.progress.emit(progressCounter)
                                if(path.basename(filename)!="thumbs.db"):
                                    self.statusText.emit("Archiving : "+ path.basename(filename))
                                    filepath = path.join(finalAssetPath, filename)
                                    arcname = path.join(shotNumber, filename)
                                    zip.write(filepath, arcname)
                
                if self.aborted:
                    os.remove(zipFilename)
                    return
                            
                self.archiveButtonState.emit(True)
                self.statusText.emit('Archive Finished')
                self.progress.emit(0)
                self.stopButtonState.emit(False)
            else:
                self.statusText.emit('Existing archive found with same shot name. Manually delete or superseed existing archive')
                self.statusTextColor.emit('color:red')
                self.archiveButtonState.emit(True)
                
        else:
            self.statusText.emit('Path For Archive Doesnot Exist : ' + archiveDir)
            self.statusTextColor.emit('color:red')
            self.archiveButtonState.emit(True)
            
    #--Function gets called whenever cancel button is clicked.Sets aborted variable to true which is then checked within the run function to see if the process should be canceled.        
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
            if(not ProjectInfo.getShotIndex()):
                self.projectName.setStyleSheet('color:red')
                self.shotNumber.setStyleSheet('color:red')
                self.assetPath.setStyleSheet('color:red')
                self.status.setStyleSheet('color:red')
                self.projectName.setText('Project Name : ' + ProjectInfo.getProjectName())
                self.shotNumber.setText('Shot Number : ' + ProjectInfo.getShotNumber())
                self.assetPath.setText('Asset Path: ' + ProjectInfo.getAssetPath())
                self.status.setText("Something seems wrong with the filename")
                return(False)
            else:
                self.projectName.setStyleSheet('color:white')
                self.shotNumber.setStyleSheet('color:white')
                self.assetPath.setStyleSheet('color:white')
                self.status.setStyleSheet('color:white')
                self.status.setText("")
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
        self.status.setStyleSheet('color:white')
        self.status.setText("Performing Sanity Check. Please Wait")
        QCoreApplication.processEvents()
        if self.init_Info():
            SMTD = SMTD_sanityCheck()
            
            if self.initialRenderer != str(rt.renderers.current)[0:5]:
                SMTD.loadSanityCheck()
            if SMTD.performSanityCheck():
                self.status.setStyleSheet('color:white')
                self.archiveButton.setEnabled(False)
                if (rt.getSaveRequired()):
                    self.status.setText("Saving Max File....")
                    QCoreApplication.processEvents()
                    rt.saveMaxFile (rt.maxfilepath+rt.maxfilename)
                self.worker = Worker(self.notes.toPlainText())
                self.worker.start()
                self.worker.progress.connect(self.progressBar.setValue)
                self.worker.progressMax.connect(self.progressBar.setMaximum)
                self.worker.statusText.connect(self.status.setText)
                self.worker.statusTextColor.connect(self.status.setStyleSheet)
                self.worker.archiveButtonState.connect(self.archiveButton.setEnabled)
                self.worker.stopButtonState.connect(self.stopButton.setEnabled)
                self.stopButton.clicked.connect(self.worker.abort)
                self.worker.finished.connect(self.worker.deleteLater)
                
                
            else:
                self.status.setText('Sanity Check Failed !!!')
                self.status.setStyleSheet('color:red')
                
    def closeEvent(self, event):
        try:
            if self.worker.isRunning():
                returnValue = close_msgBox.exec()
                if returnValue == qw.QMessageBox.Yes:
                    self.worker.abort()
                    self.worker.deleteLater()
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
