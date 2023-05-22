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
	
	--Checks Missing Maps--
	
	fn CheckMissingMaps=
	(
		allmaps=getclassinstances bitmaptexture + getclassinstances coronaBitmap 
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
	--print instances
	),
	
	
	
	-----------Checks For Forbidden Paths---------------
	
	fn CheckforbiddenPath =
	(
	a=getclassinstances BitmapTexture + getclassinstances CoronaBitmap
	vrhdri=getclassinstances vrayhdri
	ForbiddenPath=#("B","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","V","X","Y","W","\\")
	DriveLetters=#()
	ctr=0
	for items in a where items.filename!=undefined do append DriveLetters (substring items.filename 1 1)
	for h in vrHDRI where h.HDRImapName!=undefined and h.HDRImapName!="" do append DriveLetters (Substring h.HDRImapName 1 1)
	for letters in Driveletters do
	(
	for p in ForbiddenPath do
	(
		If letters==p do
		(
		ctr+=1 
		exit()
		)
		
	)
	)
	if ctr==0 then return true else return false

	),
	
	----------------Check If the maps are in C drive other than Specified Paths---------------------------------------
	/* Disabled for now as the paths.txt file is missing
	fn CheckDefaultCpath =
	(
	
	Fpathcheck=0
	AllBmaps=getclassinstances BitmapTexture + getclassinstances CoronaBitmap
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
	
	
	
	fn CheckFilenameDots=
	(
	illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")
	DotCount=0
	if rendoutputfilename!=undefined and rendoutputfilename!="" do
	(
	for char in illegalCharacters do
	(
	OutName=getfilenamefile rendoutputfilename
	DotCheck=filterstring OutName char splitEmptyTokens:true	
	if Dotcheck.count>1 do 
	(
	DotCount=Dotcount+1
	exit()
	)
	)
	
	)
	If dotcount>0 then return false else return true

	),
	
	
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

OutPath=rendoutputfilename
	if outpath.count>200 then return false else return true
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

fn checkGI=
(
	cr=renderers.current
	if cr.shading_secondarySolver==1 then return false else return true
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

FN checkCoronaLutPath=
(
	cr=renderers.current
	ctr=0
	LUTPaths=#()
	if cr.colorMap_lut_enable==true do
	(
	if cr.colorMap_lut_path!=undefined and cr.colorMap_lut_path!="" do append LUTPaths cr.colorMap_lut_path
	)
	CorOutput=getclassinstances CoronaColorCorrect
	if CorOutput.count!=0 do
	(
		for items in CorOutput where items.lutfile!=undefined and items.lutfile!="" do append LUTPaths items.lutfile
	)
	if LUTPaths.count==0 then return true else
	(
		for paths in LUTPaths do 
		(
			if tolower(substring paths 1 1)=="c" or tolower(substring paths 1 1)=="d" do 
			(
			ctr+=1
			exit()
			)
		)
		if ctr==0 then return true else return false
	)
),





FN checkCoronaLutMissing=
(
	cr=renderers.current
	ctr=0
	LUTPaths=#()
	if cr.colorMap_lut_enable==true do
	(
	if cr.colorMap_lut_path!=undefined and cr.colorMap_lut_path!="" do append LUTPaths cr.colorMap_lut_path
	)
	CorOutput=getclassinstances CoronaColorCorrect
	if CorOutput.count!=0 do
	(
		for items in CorOutput where items.lutfile!=undefined and items.lutfile!="" do append LUTPaths items.lutfile
	)
	if LUTPaths.count==0 then return true else
	(
		for paths in LUTPaths do 
		(
			if doesfileexist paths==false do
			(
			ctr+=1
			exit()
			)
		)
		if ctr==0 then return true else return false
	)
),


FN CheckIESpath=
(
	
ctr=0
IESpaths=#()
CrLights =getclassinstances coronalight
PtLights=getclassinstances Target_light + getclassinstances Free_Light 

if crlights.count!=0 do
(
for cl in crlights where (hasproperty cl #iesfile)==true do
(
	if cl.iesfile!=undefined and cl.iesfile!="" do append IESpaths cl.iesfile
)
)


if ptlights.count!=0 do
(
for pl in Ptlights where (hasproperty pl #webfile)==true do
(
	if pl.webfile!=undefined and pl.webfile!="" do append IESpaths pl.webfile
)
)

if IESpaths.count==0 then return true else
(
	for paths in IESpaths do 
		(
			if tolower(substring paths 1 1)=="c" or tolower(substring paths 1 1)=="d" do 
			(
			ctr+=1
			exit()
			)
		)
		if ctr==0 then return true else return false
	)
	
),


FN CheckMissingIES=
(
	
ctr=0
IESpaths=#()
CrLights =getclassinstances coronalight
PtLights=getclassinstances Target_light + getclassinstances Free_Light 

if crlights.count!=0 do
(
for cl in crlights where (hasproperty cl #iesfile)==true do
(
	if cl.iesfile!=undefined and cl.iesfile!="" do append IESpaths cl.iesfile
)
)


if ptlights.count!=0 do
(
for pl in Ptlights where (hasproperty pl #webfile)==true do
(
	if pl.webfile!=undefined and pl.webfile!="" do append IESpaths pl.webfile
)
)

if IESpaths.count==0 then return true else
(
	for paths in IESpaths do 
		(
			if doesfileexist paths==false do
			(
			ctr+=1
			exit()
			)
		)
		if ctr==0 then return true else return false
	)
	
),
FN checknoiselimit=
(
	cr=renderers.current
	if cr.adaptivity_targetError==0 then return false else return true
),

FN checknoisepass=
(
	cr=renderers.current
	if cr.adaptivity_targetError>6 then return false else return true
),
FN checknoisepassV2=
(
	cr=renderers.current
	if cr.adaptivity_targetError<3 then return false else return true
),



fn CheckTextplus =
(
	textPlusobj=for obj in objects where classof obj.baseobject==textplus collect obj
	if textPlusobj.count>0 then return false else return true
),

fn CheckBeautyandBG=
(
re=maxops.getcurrenderelementmgr()
elementCount=re.NumRenderElements()
test=true
for i=0 to (elementCount-1) do
(
	if classof (re.getrenderelement i)==CShading_Beauty or classof (re.getrenderelement i)==CShading_BloomGlare do 
	(
	test=false
	exit()
	)
)
return test
),

fn CheckforbiddenPathProxy =
	(
	a=getclassinstances Cproxy + getclassinstances VrayProxy
	ForbiddenPath=#("B","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","V","X","Y","W","\\")
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

fn CheckMissingProxy=
	(
		proxy=getclassinstances Cproxy + getclassinstances VrayProxy
		missingproxy=0
		for p in proxy where (p.filename!=undefined and p.filename!="") do
		(
		if (doesfileexist p.filename==false)do missingproxy=missingproxy+1
		)
		if missingproxy==0 then return true else return false
	),
fn checkCameraIllegalChar =
(
	finalVal=true
	illegalCharacters=#("~","`","!","@","#","$","%","^","&","*","(",")","{","}","[","]","\\","|",";",":","?","/")
	if viewport.getcamera()!=undefined do
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

/* -- Check Not needed for animation scene archive
fn CheckResolution=
(
	renderscenedialog.close()
	if deadlinesubmitCorona.CKB_EXR.state==true then
	(
	if renderwidth*renderheight>40000000 then return false else return true
	)
	else return true
),
*/

fn checkHiddenLights = 
(
	hLights=0
	for l in lights where l.ishidden do hlights+=1
	if hlights>0 then return false else return true
),

fn checkCGeometry=
(
	cGeometryElements=#()
		for el in (getclassinstances CGeometry_Zdepth) do append cGeometryElements el
	for el in (getclassinstances CGeometry_WorldPosition) do append cGeometryElements el
	for el in (getclassinstances CGeometry_Velocity) do append cGeometryElements el
	for el in (getclassinstances CGeometry_UvwCoords) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsShading) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsGeometry) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsDotProduct) do append cGeometryElements el
	if cGeometryElements.count!=0 then return false else return true
),
fn checkElementsStatus=
(
	re=maxops.getCurRenderElementMgr()
	return re.getelementsActive()
),
fn checkRenderSelected=
(
	if renderers.current.renderselected_mode==1 then return false else return true
),
fn checkRenderSelectedlist=
(
	if renderers.current.renderselected_mode!=1 and renderers.current.renderselected_mode!=0 then
	(
		if renderers.current.renderselected_mode==3 do if renderers.current.renderselected_list.count==0 then return false else return true
		if renderers.current.renderselected_mode==2 do if renderers.current.renderselected_objectId==0 then return false else return true
	)
	else return true
	
),
fn checkLowResolution=
(
	if renderwidth<1280 or renderheight<720 then return false else return true
),

fn CheckForDuplicateREPaths = 
		(
			re = maxOps.GetCurRenderElementMgr()
			if re != undefined then
			(
				if re.numrenderelements() != 0 then
					(
						Paths = SMTD_SanityCheckFunctions.ReturnREPaths()
						uniquePaths = makeuniquearray Paths
						
						local renderer = SMTD_SanityCheckFunctions.GetRendererIdString()
						if renderer == "vray" OR renderer == "vrayrt" then
						(
							if renderer == "vray" then vr = renderers.current else vr = renderers.current.V_Ray_settings
							if vr.output_on do return true --exit if V-Ray VFB is enabled as duplicate RE is not applicable
						)
						
						Paths.count == uniquePaths.count
					)
				else true
			)--end if re undefined
			else true
		),
		
	fn CheckMaxRootFIle=
	(
	Folders=filterstring maxfilepath "\\"
	if folders.count>1 and folders[1]=="Z:" then return true else return false
	),
	
fn CheckassetZPath=
(
	cr=renderers.current
	tester=true
	RootFolder=filterstring maxfilepath "\\"
	fileSplit = (filterstring maxfileName "_")
	re = python.import "re"
	shotNumber = for i in fileSplit where (re.findall "M\d\d\d" i)[1]!=undefined collect i
	AssetPath = RootFolder[1]+"\\"+RootFolder[2]+"\\"+"02_Production\01_Assets\01_Maps\FILM\\"+shotNumber[1]+"\\" 
	
	--- Collect All LUT Paths 
	/*
	LUTPaths=#()
	if cr.colorMap_lut_enable==true do
	(
	if cr.colorMap_lut_path!=undefined and cr.colorMap_lut_path!="" do append LUTPaths cr.colorMap_lut_path
	)
	CorOutput=getclassinstances CoronaColorCorrect
	if CorOutput.count!=0 do
	(
		for items in CorOutput where items.lutfile!=undefined and items.lutfile!="" do append LUTPaths items.lutfile
	)
	*/
	cbitmaps = getClassInstances CoronaBitmap	
	allmaps=getclassinstances bitmaptexture
	vrhdri=getclassinstances vrayhdri
	proxy=getclassinstances cproxy + getClassInstances vrayProxy 
	
	allpaths=#()
	for bmap in cbitmaps where bmap.filename!=undefined and bmap.filename!="" do append allpaths bmap.filename
	for maps in allmaps where maps.filename!=undefined and maps.filename!="" do append allpaths maps.filename
	for hdr in vrhdri where hdr.HDRImapname!=undefined and hdr.HDRImapname!="" do append allpaths hdr.HDRImapname
	for prx in proxy where prx.filename!=undefined and prx.filename!="" do append allpaths prx.filename
	--for lp in LUTPaths do append allpaths lp
	
	for paths in allpaths do 
	(
		
		AnimaAssetPath = (filterstring paths "\\")[4]
		if toUpper(getfilenamepath(paths))!=toUpper(AssetPath) do
		(
			
			if animaAssetPath!="14_Anima" do
			(
				print AssetPath
				print paths
				tester=false
				exit()
			)
		)
		
		
	)
	return tester
)





)--end struct		


struct SMTD_Private_RepairFunctions 
(
	
	fn nothing=
	(
		true
	),
	
	fn FixFilenameDots =
	(
	illegalCharacters=#("!","@","#","$","%","^","&","*","(",")","=","+","~","`",",",";",":",".","<",">","?","/","'","\"","{","[","}","]","|","`","\\")


DotCount=0
NewElementName=""

	for char in illegalCharacters do
	(
		renelement=getfilenamefile rendoutputfilename
		DotCheck=filterstring renelement char	splitEmptyTokens:true
		if Dotcheck.count>1 do 
		(
			renderscenedialog.close()
			for str in dotcheck do
			(
				NewElementName+=str
			)
			filepath=getfilenamepath rendoutputfilename
			fileext=getfilenametype rendoutputfilename
			rendoutputfilename=filepath+NewElementName+fileext
		)
		NewElementName=""
	)

renderscenedialog.open()
	),
	
	
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

fn fixGIsolver=
(
	cr=renderers.current
	cr.shading_secondarySolver=4
),
fn fixnoiselimit=
(
	cr=renderers.current
	cr.adaptivity_targetError=3
),
fn FixTextPlus=
(
	textPlusObj=for obj in objects where classof obj.baseobject==textplus collect obj
	for items in textPlusObj do convertToPoly items
),
	
	fn FixCameraIllegalChar =
(

	illegalCharacters=#("~","`","!","@","#","$","%","^","&","*","(",")","{","}","[","]","\\","|",";",":","?","/")


DotCount=0
NewCameraName=""
if viewport.getcamera()!=undefined do
(
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
)

),

fn fixhiddenlights=
(
	for l in lights where l.ishidden do unhide l
),

fn fixCGeometry=
(
	re=maxops.getcurrenderelementmgr()
	cGeometryElements=#()
	for el in (getclassinstances CGeometry_Zdepth) do append cGeometryElements el
	for el in (getclassinstances CGeometry_WorldPosition) do append cGeometryElements el
	for el in (getclassinstances CGeometry_Velocity) do append cGeometryElements el
	for el in (getclassinstances CGeometry_UvwCoords) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsShading) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsGeometry) do append cGeometryElements el
	for el in (getclassinstances CGeometry_NormalsDotProduct) do append cGeometryElements el

	if cGeometryElements.count!=0 do for zdp in cGeometryElements do re.removerenderelement zdp
),

	fn fixElementstatus=
	(
		re=maxops.getCurRenderElementMgr()
		re.setelementsActive true
	),
	
	/*
	fn fixResolution=
	(
		deadlinesubmitCorona.CKB_EXR.state=true
		deadlinesubmitCorona.CKB_denoise.state=false
		deadlinesubmitCorona.CKB_HighRamUsage.state=true
	),
	*/
	
	fn fixRenderSelected=
	(
		renderers.current.renderselected_mode=0
	),
	fn FixDuplicateREPaths =
	(
	
	re=maxops.getCurRenderElementMgr()
	elementCount=re.NumRenderElements()
	for i=0 to elementcount-1 do re.setRenderElementfilename i ""
	renderscenedialog.close()
	)



	
)--end struct 

------------------------------------------------------------------------------------------------------------------------------------------------------
--SANITY CHECK PRIVATE DEFINITIONS
------------------------------------------------------------------------------------------------------------------------------------------------------

SMTD_Private_SanityChecksToPerform = #(
#(SMTD_Private_SanityCheckFunctions.CheckMissingMaps,#fail,"Missing Maps",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckMissingPlugin,#fail,"Missing Plugins.Remove unsupported items and resave the maxfile.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckForbiddenPath,#fail,"Texture Maps not in production drive. Collect all assets in Project Folder.",SMTD_Private_RepairFunctions.nothing,true),
	--#(SMTD_Private_SanityCheckFunctions.CheckDefaultCPath,#fail,"Texture Maps in C Drive.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckFileNameDots,#fail,"Output Filename has Illegal Characters. Right Click to Fix.",SMTD_Private_RepairFunctions.FixFilenameDots,true),
#(SMTD_Private_SanityCheckFunctions.CheckElementName,#fail,"Output Elementname has Illegal Characters. Right Click to Fix.",SMTD_Private_RepairFunctions.FixElementName,true),
#(SMTD_Private_SanityCheckFunctions.CheckOutPutPathLength,#fail,"Output Path Longer than 200 Characters.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckElementNameLength,#fail,"Element Name Longer than 50 Characters.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.checkGI,#fix,"Secondary Solver is set to PathTracing. Render Time may be longer.",SMTD_Private_RepairFunctions.fixGIsolver,true),
#(SMTD_Private_SanityCheckFunctions.CheckMissingXref,#fail,"Missing Xrefs.",SMTD_Private_RepairFunctions.nothing,true),
--#(SMTD_Private_SanityCheckFunctions.CheckCoronaLutPath,#fail,"Corona LUT file in local Drive.",SMTD_Private_RepairFunctions.nothing,true),
--#(SMTD_Private_SanityCheckFunctions.CheckCoronaLutmissing,#fail,"Missing Corona LUT file.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckIESpath,#fail,"IES file in Local Drive.",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckMissingIES,#fail,"Missing IES files.",SMTD_Private_RepairFunctions.nothing,true),
	--#(SMTD_Private_SanityCheckFunctions.CheckNoiseLimit,#fail,"Noise Limit set to 0. Recommended Value 3",SMTD_Private_RepairFunctions.fixnoiselimit,true),
#(SMTD_Private_SanityCheckFunctions.CheckNoisePass,#fix,"Noise Limit set to more than 6. This may be as intended?",SMTD_Private_RepairFunctions.fixnoiselimit,true),
#(SMTD_Private_SanityCheckFunctions.CheckNoisePassV2,#fail,"Noise Limit set to less than 3. Recommended Noise Value for 2K image is 3 and 5k+ is 4.",SMTD_Private_RepairFunctions.fixnoiselimit,true),
#(SMTD_Private_SanityCheckFunctions.CheckTextplus,#fail,"TextPlus object in the scene. Right Click to collapse.",SMTD_Private_RepairFunctions.FixTextPlus,true),
#(SMTD_Private_SanityCheckFunctions.CheckBeautyandBG,#fix,"Beauty or Bloom and Glare Pass exist.These Elements wont get saved out From CXR.",SMTD_Private_RepairFunctions.nothing,false),
#(SMTD_Private_SanityCheckFunctions.CheckforbiddenPathProxy,#fail,"Proxies on Forbidden Path(C:,D:,Y:,W:,X:)",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckMissingProxy,#fail,"Missing Proxies",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckCameraIllegalChar,#fail,"ActiveCamera has illegal characters in its name. Right click to fix.",SMTD_Private_RepairFunctions.fixCameraIllegalChar,true),
--#(SMTD_Private_SanityCheckFunctions.CheckResolution,#fail,"Denoising is not supported for large CXR images. Right Click to save the output as EXR",SMTD_Private_RepairFunctions.fixResolution,true),
#(SMTD_Private_SanityCheckFunctions.checkHiddenLights,#fix,"Hidden lights in scene. They wont be rendered.Right click to unhide.",SMTD_Private_RepairFunctions.fixHiddenLights,true),
--#(SMTD_Private_SanityCheckFunctions.checkAlpha,#fix,"Alpha element in the Scene. Denoising will fail. Right click to remove.",SMTD_Private_RepairFunctions.fixAlpha,true),
#(SMTD_Private_SanityCheckFunctions.checkCGeometry,#fix,"CGeometry elements in the Scene. The Denoised CXR will not be saved. Right click to remove.",SMTD_Private_RepairFunctions.fixCGeometry,true),
#(SMTD_Private_SanityCheckFunctions.checkElementsStatus,#fix,"Elements are disabled. Right click to enable.",SMTD_Private_RepairFunctions.fixElementstatus,true),
#(SMTD_Private_SanityCheckFunctions.checkRenderSelected,#fail,"Render Selected (Viewport Selection) Not supported. Right click to disable.",SMTD_Private_RepairFunctions.fixRenderSelected,true),
#(SMTD_Private_SanityCheckFunctions.checkRenderSelectedList,#fail,"RenderSelected Enabled but nothing selected. Right click to disable.",SMTD_Private_RepairFunctions.fixRenderSelected,true),
#(SMTD_Private_SanityCheckFunctions.checkLowResolution,#fix,"Render resolution seems very small. This may be as intended? ",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_SanityCheckFunctions.CheckForDuplicateREPaths, #fail, "Duplicate Render Elements saving to same File Found!", SMTD_Private_RepairFunctions.FixDuplicateREPaths, true),
#(SMTD_Private_SanityCheckFunctions.checkMaxRootFile,#fail,"Maxfile should be saved in Z: drive inside correct Project Folder",SMTD_Private_RepairFunctions.nothing,true),
#(SMTD_Private_SanityCheckFunctions.CheckassetZPath,#fail,"Assets are Not in correct Location . Collect all assets in 01_Assets\01_Maps\FILM\ShotNumber(M000) ",SMTD_Private_RepairFunctions.nothing,true)

)--end checks array

)--End File
