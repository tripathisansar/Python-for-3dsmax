from PySide2 import QtWidgets as qw
from PySide2.QtCore import *
from qtmax import GetQMaxMainWindow
from pymxs import runtime as rt
from os import path,walk
import os
from zipfile import ZipFile
import zipfile
import time




global main_Dialog

try:
    main_Dialog.close()
except:
    pass



        

class Worker(QThread):
    progress = Signal(int)
    progressMax= Signal(int)
    statusText = Signal(str)
    aborted = False
    def __init__(self):
        QThread.__init__(self)
        
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
            self.statusText.emit(path.basename(paths[1]))
            zip.write(paths[1], path.basename(paths[1]))
            for dirpath, dirnames, filenames in walk(paths[0]):
                self.progressMax.emit(len(filenames))
                for filename in filenames:
                    progressCounter+=1
                    self.progress.emit(progressCounter)
                    self.statusText.emit(path.basename(filename))
                    filepath = path.join(paths[0], filename)
                    arcname = path.join(paths[2], filename)
                    zip.write(filepath, arcname)
            
    def abort(self):
        self.aborted = True
        
    def buttonEnabled(self, bool):
        buttonStatus = bool
        
class SceneArchiver(qw.QDialog):
    
    def __init__(self, parent= None):
        super().__init__(parent)
        
        self.setWindowTitle('Scene Archiver')
        self.progressBar = qw.QProgressBar(self)
        self.archiveButton = qw.QPushButton('Start Archiving', self)
        self.stopButton = qw.QPushButton('Stop', self) 
        self.status = qw.QLabel('This is label')
        self.init_UI()
        
    def init_UI(self):
        #self.setFixedSize(300,100)
        main_Layout = qw.QVBoxLayout()
        main_Layout.setSpacing(5)
        
        #self.button.setFixedSize(280, 50)
        self.archiveButton.clicked.connect(self.main_program)
        
        self.progressBar.setFixedSize(280, 5)
        self.progressBar.setMinimum(0)
        self.progressBar.setMaximum(20)
        self.progressBar.setTextVisible(False)
        
        main_Layout.addWidget(self.archiveButton)
        main_Layout.addWidget(self.stopButton)
        main_Layout.addWidget(self.progressBar)
        main_Layout.addWidget(self.status)
        self.setLayout(main_Layout)
        
    def main_program(self):
        self.archiveButton.setEnabled(False)
        self.worker = Worker()
        self.worker.start()
        self.worker.progress.connect(self.progressBar.setValue)
        self.worker.progressMax.connect(self.progressBar.setMaximum)
        self.worker.statusText.connect(self.status.setText)
        """
        if rt.SMTD_PerformSanityCheck():
            archive(getAssetFilePath(), self)
        else:
            print('Sanity Check Failed')
        """   
    
main_Dialog = SceneArchiver(GetQMaxMainWindow())
main_Dialog.show()