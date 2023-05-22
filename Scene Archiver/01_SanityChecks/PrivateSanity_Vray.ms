-----------------------------------------------------------------------------------------------------------------------------------------------
--THIS FILE CONTAINS YOUR USER-DEFINED CHECKS TO BE PERFORMED AND THE FUNCTIONS
--TO BE USED TO CHECK AND REPAIR THE SCENE BEFORE SUBMISSION
-----------------------------------------------------------------------------------------------------------------------------------------------
--THIS FILE WILL **NOT** BE UPDATED AUTOMATICALLY BY THINKBOX SOFTWARE INC
--AND SHOULD BE USED FOR YOUR IN-HOUSE NEEDS.
-----------------------------------------------------------------------------------------------------------------------------------------------

(
global SMTD_Private_SanityCheckFunctions
global SMTD_Private_SanityChecksToPerform
global SMTD_Private_RepairFunctions 

global SMTD_RepairFunctions
global SMTD_SanityChecksToPerform
global SMTD_SanityCheckFunctions
global DeadRep=@"P:\"
struct SMTD_Private_SanityCheckFunctions
(
	--Checks VFB Color Correction Settings--
    fn VFBCCCheck =
    (
	cc=#()
	append cc ((vfbcontrol #exposure )[1])
	append cc ((vfbcontrol #whitebalance)[1])
	append cc ((vfbcontrol #huesat)[1])
	append cc ((vfbcontrol #colorbalance)[1])
	append cc ((vfbcontrol #levels)[1])
	append cc ((vfbcontrol #curve)[1])
	append cc ((vfbcontrol #bkgr)[1])
	append cc ((vfbcontrol #lut)[1])
	append cc ((vfbcontrol #ocio)[1])
	append cc ((vfbcontrol #icc)[1])
	n=0
	for items in cc where items==1 do
	(
	n=1
	exit
	)
	if n==0 then return true else return false
    ),
	fn CheckAutoExposureAndWhiteBalance = 
	(
		/*
		Checks if Camera Auto exposure or Auto white balance are ON.
		*/
		ae_status = renderers.current.camera_autoExposure
		awb_status = renderers.current.camera_autoWhiteBalance
		
		if ae_status==True or awb_status==1 then
		(
			return false
		)
		else
		(
			return true
		)
	),
	--Checks Missing Maps--
	fn CheckMissingMaps=
	(
		vr=renderers.current
		vr.system_checkForMissingFiles = true
		
		allmaps=getclassinstances bitmaptexture
		vrhdri=getclassinstances vrayhdri
		missingmaps=0
		for maps in allmaps where (maps.filename!=undefined and maps.filename!="") do
		(
			if (doesfileexist maps.filename==false) do missingmaps=missingmaps+1
		)
		for h in vrhdri where (h.HDRImapName!=undefined and h.HDRImapName!="") do
		(
			if (doesfileexist h.HDRImapName==false) do missingmaps=missingmaps+1
		)

		if missingmaps==0 then return true else return false 
	),
	
	
	--Check Missing Proxies--
	fn CheckMissingProxy=
	(
		proxy=getclassinstances vrayproxy
		missingproxy=0
		for p in proxy where (p.filename!=undefined and p.filename!="") do
		(
		if (doesfileexist p.filename==false)do missingproxy=missingproxy+1
		)
		if missingproxy==0 then return true else return false
	),
	
	fn checkEmptyProxy=
		(
		prx=getclassinstances VrayProxy
		missingproxy=0
		for p in prx do
		(
			if p.filename==undefined or p.filename=="" do 
			(
				missingproxy=missingproxy+1
				exit()
			)
		)
		if missingproxy==0 then return true else return false
	),
	
	--CHecks Missing Plugin----
	fn CheckMissingPlugin=
	(
		standin_classes = #(Missing_Point4_Control,
		Missing_SoundObj,
		Missing_Shader_Plug_in,
		Missing_Float_Control,
		Missing_Shadow_Type,
		Missing_WSM_Object,
		Missing_TextureMap,
		Missing_GeomObject,
		Missing_UVGen,
		Missing_XYZGen,
		Missing_Camera,
		Missing_Texture_Output_Plug_in,
		Missing_Point3_Control,
		Missing_Renderer,
		Missing_Atmospheric,
		Missing_Matrix3_Control,
		Missing_Light,
		Missing_Helper,
		Missing_System,
		Missing_Render_Element_Plug_in,
		Missing_OSM,
		Missing_Position_Control,
		Missing_Shape,
		Missing_Texture_Bake_Element,
		Missing_RefTarget,
		Missing_Custom_Attribute_Plugin,
		Missing_Mtl,
		Missing_Radiosity,
		Missing_Rotation_Control,
		Missing_Exposure_Control,
		Missing_Render_Effect,
		Standin_for_missing_MultiPass_Camera_Effect_Plugin,
		Missing_RefMaker,
		Missing_Scale_Control,
		Missing_Morph_Control,
		Missing_WSM
	)
	instances=#()
	for c in standin_classes do
	(
		if ((getclassinstances c).count !=0) do append instances (getclassinstances c)
	)
	if instances.count==0 then return true else return false
	print instances
	),
	
	------Check If Vray Denoiser Pass is being used-------
	fn CheckVrayDenoiser = 
	(
		re=maxops.getcurrenderelementmgr()
		if re.numrenderelements()!=0 then
		(
			cntr=0
			for i=0 to re.numrenderelements() where classof(re.getrenderelement i)==VrayDenoiser do
			(
				cntr=1
				exit
			)
			if cntr==1 then return false else return true
		)
		else return true
	),
	
	-----------Checks For Forbidden Paths---------------
	
	fn CheckforbiddenPath =
	(
	Bmap=getclassinstances BitmapTexture 
	vrhdri=getclassinstances vrayhdri
	ForbiddenPath=#("B","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","V","X","Y","W","\\")
	DriveLetters=#()
	result=true
	for items in Bmap where items.filename!=undefined do append DriveLetters (substring items.filename 1 1)
	for h in vrHDRI where h.HDRImapName!=undefined and h.HDRImapName!="" do append DriveLetters (Substring h.HDRImapName 1 1)

	for letters in Driveletters do
	(
	if (finditem ForbiddenPath letters)!=0 do
		(
		result=false
		exit()
		)
	)
	return result
	),
	
	fn CheckforbiddenpathProxy=
	
	(
	a=getclassinstances vrayproxy
	ForbiddenPath=#("C","B","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","V","X","Y","W","\\")
	DriveLetters=#()
	result=true
	for items in a where items.filename!=undefined do append DriveLetters (substring items.filename 1 1)

	for letters in Driveletters do
	(
	if (finditem ForbiddenPath letters)!=0 do
		(
		result=false
		exit()
		)
	)
	return result
	),
	
	
	----------------Check If the maps are in C drive other than Specified Paths---------------------------------------
	/*
	fn CheckDefaultCpath =
	(
	
	Fpathcheck=0
	AllBmaps=getclassinstances BitmapTexture
	vrhdri=getclassinstances vrayhdri
	allfilepaths=#()
	for m in allBmaps where m.filename!=undefined and m.filename!="" do append allfilepaths m.filename
	for h in vrhdri where h.HDRImapName!=undefined and h.HDRImapName!="" do append allfilepaths h.HDRImapName
	ForbiddenPath=#()
	
	Ofile=openfile (DeadRep+"custom\submission\binyan\04_misc\Paths.txt")
	while not eof Ofile do
		(
			append ForbiddenPath (readline ofile)
		)
	close Ofile 
	
	for maps in AllfilePaths where maps!=undefined and maps!="" do
		(
			if tolower(substring maps 1 1)=="c" do
			(
			for paths in Forbiddenpath do
			(
				If tolower(getfilenamepath maps)==paths do
				(
					Fpathcheck=1
					exit()
				)
				
			)
			If FpathCheck==1 then FpathCheck=0 else 
			(
			FpathCheck=1 
			exit()
			)
			)
		)

		If Fpathcheck==1 then return false else return true
	),
	*/

	FN CheckProgressive=
	(
		vr=renderers.current
		if vr.imagesampler_type_new==1 then return false else return true
	),
	
	
fn CheckFilenameDots=
	(
	vr=renderers.current
	if vr.output_splitfilename==undefined do return True
	illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")
	DotCount=0

	for char in illegalCharacters do
	(
	OutName=getfilenamefile vr.output_splitfilename
	DotCheck=filterstring OutName char splitEmptyTokens:true	
	if Dotcheck.count>1 do 
	(
	DotCount=Dotcount+1
	exit()
	)
	)
	
	If dotcount>0 then return false else return true
),

fn CheckFastSSS=
(
		FastSSS=getclassinstances VrayFastSSS2
		if FastSSS.count==0 then return true else
		(
		if tolower(substring FastSSS[1].name 1 7)=="fastsss" then return true else return false
		)
),
	
/*
fn CheckRenderMask=
	(
		vr=renderers.current
		if getrendertype()!=#region then return true else
		(
			if vr.imagesampler_rendermask_type==0 then return true else return false
		)
),
*/
	
fn CheckElementName=
(
illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")
RE=maxops.getcurrenderelementmgr()
noElement=RE.numrenderelements()

DotCount=0

for i=0 to (noElement-1) do
(
	for char in illegalCharacters do
	(
	renelement=RE.GetrenderElement i
	DotCheck=filterstring renelement.elementname char splitEmptyTokens:true	
	if Dotcheck.count>1 do 
	(
	DotCount+=1
	exit()
	)
	)
	)
	If dotcount>0 then return false else return true
),

fn checkOutputPathlength=
(
Vr=Renderers.current
OutPath=vr.output_splitfilename
if(OutPath!=undefined) then	
	if outpath.count>200 then return false else return true
else 
	return true
),

fn checkElementNameLength=
(
	RE=maxops.getcurrenderelementmgr()
	noElement=RE.numrenderelements()
	lencheck=0
	for i=0 to (noElement-1) do
	(
		renelement=RE.GetrenderElement i
		elementpath= renelement.elementname
		if elementpath.count>50 do
		(
			lencheck+=1
			exit()
		)
	)
	If lencheck>0 then return false else return true
),

fn CheckMissingXref=
(
	ctr=0
nxref=xrefs.getxreffilecount()
If nxref!=0 do
(

for i=1 to nxref do
(
	Filename=(xrefs.getxreffile i).filename
	If doesfileexist filename==false do ctr+=1
)

)
if ctr==0 then return true else return false
),

fn CheckSeparateFolders=
	(
		vr=renderers.current
		if vr.output_separateFolders==true then return false else return true
	),
fn CheckTextplus =
(
	textPlusobj=for obj in objects where classof obj.baseobject==textplus collect obj
	if textPlusobj.count>0 then return false else return true
),
fn checkDuplicateElements = 
(
	renderElem=#()
	re=maxops.getCurRenderElementMgr()
	recount=re.NumRenderElements()
	renderElem= for i=0 to recount-1 where (re.GetRenderElementFilename i)!=undefined and (re.GetRenderElementFilename i)!="" collect (getfilenamefile (re.GetRenderElementFilename i))
	if renderElem.count!=0 then
	(
	newArray=makeuniquearray renderElem
	if newArray.count<renderElem.count then return false else return true
	)
	else return true
	
),
fn checkCameraIllegalChar =
(
	finalVal=true
	illegalCharacters=#("~","`","!","@","#","$","%","^","&","*","(",")","{","}","[","]","\\","|",";",":","?","/")
	if getActiveCamera()!=undefined do
	(
	activecamera=(getActiveCamera()).name
	for char in illegalCharacters do
	(
		if findstring activecamera char!=undefined then 
		(
			finalVal=false
			exit()
		)
		else finalVal=true
	)
	)
	return finalVal
		
),
/*
fn checkElementsStatus=
(
	re=maxops.getCurRenderElementMgr()
	if deadlinesubmit.CKB_HighRamUsage.checked then return true else return re.getelementsActive()
),
*/

fn checkLowResolution=
(
	if renderwidth<1000 or renderheight<1000 then return false else return true
),

	fn CheckMaxRootFIle=
	(
	Folders=filterstring maxfilepath "\\"
	if folders.count>1 and folders[1]=="Z:" then return true else return false
	),
	
fn CheckassetZPath=
(
	tester=true
	RootFolder=filterstring maxfilepath "\\"
	fileSplit = (filterstring maxfileName "_")
	re = python.import "re"
	shotNumber = for i in fileSplit where (re.findall "M\d\d\d" i)[1]!=undefined collect i
	AssetPath = RootFolder[1]+"\\"+RootFolder[2]+"\\"+"02_Production\01_Assets\01_Maps\FILM\\"+shotNumber[1]+"\\" 
	
	cbitmaps = getClassInstances CoronaBitmap	
	allmaps=getclassinstances bitmaptexture
	vrhdri=getclassinstances vrayhdri
	proxy=getclassinstances cproxy
	
	allpaths=#()
	for bmap in cbitmaps where bmap.filename!=undefined and bmap.filename!="" do append allpaths bmap.filename
	for maps in allmaps where maps.filename!=undefined and maps.filename!="" do append allpaths maps.filename
	for hdr in vrhdri where hdr.HDRImapname!=undefined and hdr.HDRImapname!="" do append allpaths hdr.HDRImapname
	for prx in proxy where prx.filename!=undefined and prx.filename!="" do append allpaths prx.filename
	
	for paths in allpaths do 
	(
		
		AnimaAssetPath = (filterstring paths "\\")[4]
		if getfilenamepath(paths)!=AssetPath do
		(
			
			if animaAssetPath!="14_Anima" do
			(
				print paths
				tester=false
				exit()
			)
		)
		
		
	)
	return tester
),

-- fn checkBKimage = 
-- (
-- 	if (vfbcontrol #bkgr)==1 return false else return true
-- )

fn checkBKimage = 
(
	if (vfbcontrol #bkgr)[1]==1 AND (vfbcontrol #bkgrimgfile)[1]!="" then
	(
		return false
	) 
	else
	(
		return true
	)
)
	

	
)--end struct		


struct SMTD_Private_RepairFunctions 
(
    fn VFBCCFix =
    (
	vfbcontrol #exposure false 
	vfbcontrol #whitebalance false
	vfbcontrol #huesat false
	vfbcontrol #colorbalance false
	vfbcontrol #levels false
	vfbcontrol #curve false
	vfbcontrol #bkgr false
	vfbcontrol #lut false
	vfbcontrol #ocio false
	vfbcontrol #icc false
	),
	
	fn VFBBKimageFix =
	(
		vfbcontrol #bkgr false
	),
	
	fn nothing=
	(
		true
	),
	
	fn FixVrayDenoiser=
	(
		re=maxops.getcurrenderelementmgr()
		if re.numrenderelements()!=0 do
		(
			for i=re.numrenderelements() to 0  by -1 where classof(re.getrenderelement i)==VrayDenoiser do
			(
				re.removerenderelement (re.getrenderelement i)
			)
		)
	),
	
	fn FixProgressive=
	(
		vr=renderers.current
		vr.imagesampler_type_new=0
	),
	
	fn FixFilenameDots =
	(
		vr=renderers.current 
		if vr.output_splitfilename==undefined do return True
		
		illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")
		DotCount=0
		NewElementName=""
		
		for char in illegalCharacters do
		(
			renelement=getfilenamefile vr.output_splitfilename
			
			DotCheck=filterstring renelement char	splitEmptyTokens:true
			if Dotcheck.count>1 do 
			(
				renderscenedialog.close()
				for str in dotcheck do
				(
					NewElementName+=str
				)
				filepath=getfilenamepath vr.output_splitfilename
				fileext=getfilenametype vr.output_splitfilename
				vr.output_splitfilename=filepath+NewElementName+fileext
			)
			NewElementName=""
	)

renderscenedialog.open()
	),
	/*
	fn FixRendermask=
	(
		vr=renderers.current
		vr.imagesampler_rendermask_type=0
	),
	*/
	fn FixElementName=
(
	illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")
RE=maxops.getcurrenderelementmgr()
noElement=RE.numrenderelements()

DotCount=0
NewElementName=""
for i=0 to (noElement-1) do
(
	for char in illegalCharacters do
	(
		renelement=RE.GetrenderElement i
		DotCheck=filterstring renelement.elementname char splitEmptyTokens:true	
		if Dotcheck.count>1 do 
		(
			renderscenedialog.close()
			for str in dotcheck do
			(
				NewElementName+=str
			)
			renelement.elementname=NewElementName
		)
		NewElementName=""
	)
)
renderscenedialog.open()
	
),

fn FixSeparateFolders=
	(
		vr=renderers.current
		vr.output_separatefolders=false
	),
fn FixTextPlus=
(
	textPlusObj=for obj in objects where classof obj.baseobject==textplus collect obj
	for items in textPlusObj do convertToPoly items
	),

	FN FixDuplicateElement=
(
	renderscenedialog.close()
	re=maxops.getCurRenderElementMgr()
	elementCount=re.NumRenderElements()
	elementNames=for i=0 to elementcount-1 where (re.getRenderElementfilename i )!=undefined and (re.GetRenderElementFilename i)!="" collect (re.getRenderelementfilename i)
	if elementNames.count>1 do
	(
	for i=1 to elementCount-1 do
	(
		index=1
		for j=i+1 to elementCount do
		(
			if elementNames[i]==elementNames[j] do
			(
				filepath=getfilenamepath elementNames[j]
				filename=getfilenamefile elementNames[j]+index as string
				filetype=getfilenametype elementNames[j]
				newfilename=filepath+filename+filetype
				index+=1
				deleteitem elementNames j
				insertitem newFileName elementNames j
			)
		)
	)
	
	
	
	for k=1 to elementCount do
	(
		re.SetRenderElementFilename (k-1) elementNames[k]
	)
)
	
),

fn FixCameraIllegalChar =
(

	illegalCharacters=#("~","`","!","@","#","$","%","^","&","*","(",")","{","}","[","]","\\","|",";",":","?","/")


DotCount=0
NewCameraName=""

	for char in illegalCharacters do
	(
		cameraName=(getActiveCamera()).name
		DotCheck=filterstring cameraName char	splitEmptyTokens:true
		if Dotcheck.count>1 do 
		(
			
			for str in dotcheck do
			(
				NewCameraName+=str
			)
			(getActiveCamera()).name=NewCameraName
		)
		NewCameraName=""
	)


),
fn FixFastSSS=
	(
		Global NewMtl
		fastsssmtl=getclassinstances VrayFastSSS2
		if fastsssmtl.count!=0 do
		(
			for mtl in fastsssmtl do
			(
				mtlprop=getpropnames mtl
				NewMtl=VrayFastSSS2 name:("fastSSS_"+mtl.name)
				for prop in mtlprop do 
				(
					if (getproperty mtl prop)!=undefined do setproperty NewMtl prop (getproperty mtl prop)
				)
				replaceinstances mtl NewMtl
			)
		)
	),
	
	fn FixSeparateFolders=
	(
		vr=renderers.current
		vr.output_separatefolders=false
	),
	
	fn fixElementstatus=
	(
		re=maxops.getCurRenderElementMgr()
		re.setelementsActive true
	),
	fn fixEmptyProxy=
	(
		prx=getclassinstances VrayProxy
		nds=#()
		for p in prx where p.filename==undefined or p.filename=="" do append nds (refs.dependentNodes P)
		for obj in nds do delete obj
	),
	fn FixMissingProxy=
	(
		if querybox"Are you sure you want to delete Missing Proxy?" do
		(
		proxy=getclassinstances vrayproxy
		missingproxy=0
		for p in proxy where (p.filename!=undefined and p.filename!="") do
		(
		if (doesfileexist p.filename==false)do delete (refs.dependentnodes p)
		)
		)
	)

	



	
)--end struct 

------------------------------------------------------------------------------------------------------------------------------------------------------
--SANITY CHECK PRIVATE DEFINITIONS
------------------------------------------------------------------------------------------------------------------------------------------------------

SMTD_Private_SanityChecksToPerform = #(
	#(SMTD_Private_SanityCheckFunctions.CheckForbiddenPath,#fail,"Texture Maps not in production drive. Collect all assets in Project Folder.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.VFBCCCheck, #fix, "Some VFB Color Corrections are enabled. This may be as intended? Right click to disable it.", SMTD_Private_RepairFunctions.VFBCCFix, false),
	#(SMTD_Private_SanityCheckFunctions.CheckMissingMaps,#fail,"Missing Maps.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckMissingProxy,#fail,"Missing Proxies. Right click to Delete",SMTD_Private_RepairFunctions.fixMissingProxy,true),
	#(SMTD_Private_SanityCheckFunctions.CheckEmptyProxy,#fail,"Empty Proxies. Right click to Delete",SMTD_Private_RepairFunctions.fixEmptyProxy,true),
	#(SMTD_Private_SanityCheckFunctions.CheckMissingPlugin,#fail,"Missing Plugins. Remove unsupported items and resave the maxfile.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckVrayDenoiser,#fix,"Vray Denoiser found. Right click to remove untick to ignore.",SMTD_Private_RepairFunctions.FixVrayDenoiser,true),
	--#(SMTD_Private_SanityCheckFunctions.CheckDefaultCPath,#fail,"Texture Maps in C Drive.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckFileNameDots,#fail,"Output Filename has Illegal Characters. Right Click to Fix.",SMTD_Private_RepairFunctions.FixFilenameDots,true),
	#(SMTD_Private_SanityCheckFunctions.CheckProgressive,#fix,"Image Sampler is Progressive. This may be as intended? Right click to change to Bucket.",SMTD_Private_RepairFunctions.FixProgressive,false),
	--#(SMTD_Private_SanityCheckFunctions.CheckRenderMask,#fail,"RenderMask Should be none.Right click to fix",SMTD_Private_RepairFunctions.FixRenderMask,true),
	#(SMTD_Private_SanityCheckFunctions.CheckFastSSS,#fix,"Some FastSSS material in the scene. Right Click to Replace with New FastSSS.",SMTD_Private_RepairFunctions.FixFastSSS,true),
	#(SMTD_Private_SanityCheckFunctions.CheckElementName,#fail,"Some RenderElement Name has illegal Characters. Right click to Fix.",SMTD_Private_RepairFunctions.FixElementName,true),
	#(SMTD_Private_SanityCheckFunctions.CheckOutPutPathLength,#fail,"Output Path Longer than 200 Characters.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckElementNameLength,#fail,"ElementName Longer than 50 Characters.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckMissingXref,#fail,"Missing Xrefs.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckSeparateFolders,#fail,"Separate Folders on. Right click to turn off.",SMTD_Private_RepairFunctions.FixSeparateFolders,true),
	#(SMTD_Private_SanityCheckFunctions.CheckTextplus,#fail,"TextPlus object in the scene. Right Click to Collapse.",SMTD_Private_RepairFunctions.FixTextPlus,true),
	#(SMTD_Private_SanityCheckFunctions.CheckforbiddenPathProxy,#fail,"Proxies on Forbidden Path. Should only be in Z drive",SMTD_Private_RepairFunctions.nothing,true),
	--#(SMTD_Private_SanityCheckFunctions.checkDuplicateElements,#fail,"Duplicate Render Elements Found. Right Click to fix.",SMTD_Private_RepairFunctions.FixDuplicateElement,true),
	#(SMTD_Private_SanityCheckFunctions.checkCameraIllegalChar,#fail,"ActiveCamera has illegal characters in its name. Right click to fix.",SMTD_Private_RepairFunctions.FixCameraIllegalChar,true),
	--#(SMTD_Private_SanityCheckFunctions.checkElementsStatus,#fix,"Elements are disabled. This may be as intended? Right click to enable.",SMTD_Private_RepairFunctions.fixElementstatus,true),
	#(SMTD_Private_SanityCheckFunctions.checkLowResolution,#fix,"Render resolution seems very small. This may be as intended?.",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.checkMaxRootFile,#fail,"Maxfile should be saved in Z: drive inside correct Project Folder",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.CheckassetZPath,#fail,"Assets are Not in correct Location . Collect all assets in 01_Assets\01_Maps\FILM\ShotNumber(M000) ",SMTD_Private_RepairFunctions.nothing,true),
	#(SMTD_Private_SanityCheckFunctions.checkBKimage,#fail,"Vray Frame Buffer Background Image not supported. Right Clik to disable.",SMTD_Private_RepairFunctions.VFBBKimageFix,true),
	#(SMTD_Private_SanityCheckFunctions.CheckAutoExposureAndWhiteBalance,#fail,"Camera Auto Expsoure or Auto White Balance detected. Disable or transfer values to active camera.",SMTD_Private_RepairFunctions.nothing,true)
)--end checks array

)--End File
