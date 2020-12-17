//Compilation of all analysis macros
ExitAnalysisChoice = "";
//eval("python", "from java.awt import Robot");
IJversion = IJ.getFullVersion;
pointIndex = indexOf(IJversion, ".");
IJversion = substring(IJversion, 0, pointIndex + 3);
if (parseFloat(IJversion) < 1.52) waitForUser("WARNING: Please Update ImageJ to version 1.52+! (Help >> Update ImageJ...)");
snipAndBlend = 0;

var fs;
fs = toString(File.separator);

tempDirectory = getDirectory("imagej");
tempOptDirectory = tempDirectory + "ChrisMacroTempOptions.txt";
		
for (EX = 0; EX < 3; EX++) {
	if (ExitAnalysisChoice == "Exit") continue;
	else EX = 0;
	run("Hide Console Pane");
	if (isOpen("Exception")) close("Exception");
	if (File.exists(tempOptDirectory)) {
		filestring=File.openAsString(tempOptDirectory); 
		rows=split(filestring, "\n");
	}
	
	Dialog.createNonBlocking("Main Menu");
	items1 = newArray("Organize Images", "Pre-Selection", "Synapse Selection", "Post-Selection");
	Dialog.addRadioButtonGroup("Analysis Steps", items1, 4, 1, 0);
	items2 = newArray("Run Individual Macro", "Program Repair");
	Dialog.addRadioButtonGroup("Other Options", items2, 2, 1, 0);
	
	html = "<html>"
		+"<h2>Synapse Selector Help</h2>"
		+"<head>"
		+"<body aria><u><strong>The Overall Process</strong></u><br />"
		+"<br />"
		+"There are 3 main steps to this process, and they are meant to be performed in the order listed in the options page:<br />"
		+"<br />"
		+"&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;<u><strong>Pre Selection</strong> Step (Includes the &quot;Organize Images&quot; and &quot;Pre-Selection&quot; options)</u><br />"
		+"<br />"
		+"This step is entirely automated after you:<br />"
		+"<em>1- </em>Choose a folder to process<br />"
		+"<em>2-</em> Customize your processing options.<br />"
		+"<br />"
		+"Its&nbsp;<strong>function</strong>&nbsp;is to search through the images in the folders the user has selected, then <strong>detect synapses</strong> based on the user-defined parameters. It then <strong>records synapse location and shape description&nbsp;data</strong> (width, length, angle of &#39;active zone marker&#39; bar, etc.) in the form of ROIs&nbsp;and csv files.<br />"
		+"The default options are designed to be robust and work adaptively for most images, and are designed to choose synapses rather loosely. This is to allow the user more adaptability in synapse selection later, so that the user can fine-tune and&nbsp;adjust their synapse selection criteria during the &quot;Review&quot; step.<br />"
		+"<br />"
		+"The amount of <strong>time</strong> it takes to process and experiment is roughly proportional to the number of synapses identified in your images. Thus, the following increase processing time:<br />"
		+"<em>1</em>-&nbsp; <strong>&gt;&nbsp;Noise</strong> will increase false synapse identification, thus noisy images will take longer to process&nbsp;<br />"
		+"<em>2</em>- <strong>More images</strong> will mean more processing time<br />"
		+"<em>3</em>- <strong>Greater synapse density</strong> images will take significantly longer than low density images<br />"
		+"[Low density, but high quality images with only 2 conditions and a total of 6-8 images can take as little as 20 minutes to process, however that is in a perfect scenario. A good rule of thumb is to expect 30 minutes of processing time per condition, or an hour each to be safe.]<br />"
		+"<br />"
		+"<em>For more information, please see the help section in the &quot;Pre-Selection Options Menu&quot;</em><br />"
		+"&nbsp;"
		+"<hr /><br />"
		+"&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <u><strong>Selection</strong> Step (&quot;Synapse Selection&quot;)</u><br />"
		+"<br />"
		+"This step is where the bulk of user involvement takes place.<br />"
		+"The program will <strong>display each synapse</strong> that was selected in the previous step <strong>individually</strong>, and <strong>automatically blind the user</strong>. The user then has the option to <strong>sort&nbsp;synapses</strong>&nbsp;(changing the&nbsp;order in which they are displayed) using a variety of parameters. It will also automatically enhance contrast settings (customizable) in a way that <strong>enhances edges</strong> so that the user can make decisions based on shape rather than brightness (since human vision is notoriously ill-equip to judge brightness and color in an unbiased manner). To judge brightness objectively, <strong>line-scans</strong> with raw pixel values are automatically&nbsp;displayed for each synapse.<br />"
		+"Simple keyboard shortcuts allow the user to quickly mark each synapse (<strong>keep, delete, or skip</strong>) and the exit menu allows the user to save a separate ROI file containing just the synapses that they marked to keep. This means that the &quot;deleted&quot; ROIs are NOT deleted, they are still available for review at any time.<br />"
		+"<br />"
		+"<em>For more information, please see the help section in the &quot;Synapse Selection Options Menu&quot;</em><br />"
		+"&nbsp;"
		+"<hr /><br />"
		+"&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;<u><strong>Post Selection</strong> Step (&quot;Post Selection&quot;)</u><br />"
		+"<br />"
		+"This step is completely automatic after choosing your initial options and file locations, until the end, where the user is prompted to customize the B&amp;C of the &quot;Blended&quot; images. The automated portion may take a few minutes to run.<br />"
		+"<br />"
		+"The function of this step is to provide the final output of this program, which is:<br />"
		+"<em>1</em>- Text files containing rows and columns (can be converted to excel) of <strong>line-scan data</strong><br />"
		+"<em>2</em>- I<strong>ndividual synapses&#39; cropped images</strong><br />"
		+"<em>3</em>- <strong>&quot;Blended&quot; images</strong> of all the selected synapses (Every synapse in each condition is overlaid by averaging the pixel values that overlap, produce one &#39;average&#39; image of the synapses within that condition)<br />"
		+"<br />"
		+"<em>For more information, please see the help section in the &quot;Post-Selection Options Menu&quot;</em><br />"
		+"&nbsp;</body>"
		+"</html>";
	Dialog.addHelp(html);
	Dialog.show();
	radioButtonString1 = Dialog.getRadioButton();
	radioButtonString2 = Dialog.getRadioButton();
	sortOption = 0;
	preReviewOption = 0;
	reviewOption = 0;
	postReviewOption = 0;
	individualMacroOption = 0;
	resetpreferences = 0;
	if (radioButtonString1 == items1[0]) sortOption = 1;
	else if (radioButtonString1 == items1[1]) preReviewOption = 1;
	else if (radioButtonString1 == items1[2]) reviewOption = 1;
	else if (radioButtonString1 == items1[3]) postReviewOption = 1;
	else if (radioButtonString2 == items2[0]) individualMacroOption = 1;
	else if (radioButtonString2 == items2[1]) resetpreferences = 1;
	blendMacroOption = 0;
	confocalAnalysisOption = 0;

	if (resetpreferences == 1) {
		//Delete Current Settings Files
		if (File.exists(tempOptDirectory)) deletesuccess = File.delete(tempOptDirectory);
		if (File.exists(tempDirectory + "ChrisReviewOptions.txt")) deletesuccess = File.delete(tempDirectory + "ChrisReviewOptions.txt");
		run("Reset... ");
		exit("Program Repair Sucessful. Please Close and Restart ImageJ.\n-\nIf Errors Persist,Try Updating ImageJ (Help >> Update ImageJ...)");
	}
	
	if (individualMacroOption == 1){
		Dialog.createNonBlocking("Individual Macros");
		individualMacros = newArray("", "Confocal", "Blend Macro");
		Dialog.addChoice("Choose a macro to run", individualMacros);
		Dialog.show();
		individualMacroChoice = Dialog.getChoice();
		if (individualMacroChoice == "Blend Macro") blendMacroOption = 1;
		if (individualMacroChoice == "Confocal") confocalAnalysisOption = 1;
	}
	
	if ((preReviewOption == 1) ||  (postReviewOption == 1) || individualMacroOption == 1){
		Dialog.createNonBlocking("Macro Options");
	}
	
	if (preReviewOption == 1 && !File.exists(tempOptDirectory)){
		Dialog.setInsets(0, 100, 0);
		Dialog.addMessage("[Line-Scan Options]");
		Dialog.addNumber("Scan Width", 0.25, 3, 5, "microns");
		Dialog.addNumber("Scan Length", 1.2, 3, 5, "microns");
		Dialog.setInsets(25, 60, 0);
		Dialog.addMessage("[Vesicle Cloud (VC) Constraints]");
		Dialog.addNumber("Min Depth", 0.30, 3, 5, "microns");
		Dialog.addNumber("Max Diameter",2.00, 3, 5, "microns"); 
		Dialog.setInsets(25, 20, 0);
		Dialog.addMessage("[Active Zonal/Post-Synaptic Bar Constraints]");
		Dialog.addNumber("Min Length", 0.20, 3, 5, "microns"); 
		Dialog.addNumber("Max Width", 0.40, 3, 5, "microns");
		Dialog.addNumber("Aspect Ratio (length/width)", 1.50, 3, 5, ""); 
		Dialog.addNumber("Max Distance Inside VC", 0.05, 3, 5, "microns"); 
		Dialog.addNumber("Max Distance Outside VC", 0.20, 3, 5, "microns"); 
		Dialog.setInsets(25, 100, 0);
		Dialog.addMessage("[Advanced Options]");
		Dialog.addNumber("Scan Line Length", 1, 3, 5, "microns");
		Dialog.addNumber("Scan by Fraction", NaN, 3, 5, ""); 
		Dialog.addNumber("Scan by Micrometers", 0.25, 3, 5, "microns"); 
		Dialog.addCheckbox("Overwrite Old ROIs?", 0);
	}
	else if (preReviewOption == 1 && File.exists(tempOptDirectory)) {
		Dialog.setInsets(0, 100, 0);
		Dialog.addMessage("[Line-Scan Options]");
		Dialog.addNumber("Scan Width", rows[0], 3, 5, "microns");
		Dialog.addNumber("Scan Length", rows[1], 3, 5, "microns");
		Dialog.setInsets(25, 60, 0);
		Dialog.addMessage("[Vesicle Cloud (VC) Constraints]");
		Dialog.addNumber("Min Depth", rows[2], 3, 5, "microns");
		Dialog.addNumber("Max Diameter", rows[3], 3, 5, "microns"); 
		Dialog.setInsets(25, 20, 0);
		Dialog.addMessage("[Active Zonal/Post-Synaptic Bar Constraints]");
		Dialog.addNumber("Min Length", rows[4], 3, 5, "microns"); 
		Dialog.addNumber("Max Width", rows[5], 3, 5, "microns");
		Dialog.addNumber("Aspect Ratio (length/width)", rows[6], 3, 5, ""); 
		Dialog.addNumber("Max Distance Inside VC", rows[7], 3, 5, "microns"); 
		Dialog.addNumber("Max Distance Outside VC", rows[8], 3, 5, "microns"); 
		Dialog.setInsets(25, 100, 0);
		Dialog.addMessage("[Advanced Options]");
		Dialog.addNumber("Scan Line Length", rows[9], 3, 5, "microns");
		Dialog.addNumber("Scan by Fraction", rows[10], 3, 5, ""); 
		Dialog.addNumber("Scan by Micrometers", rows[11], 3, 5, "microns"); 
		Dialog.addCheckbox("Overwrite Old ROIs?", 0);
	}
	
	if ((postReviewOption == 1 || blendMacroOption == 1) && !File.exists(tempOptDirectory)){
		Dialog.addCheckbox("Save Individual Synapses and Create Averaged Images?", 1);
		Dialog.addString("Active Zone or Post Synaptic Marker Name:", "e.g. Bassoon or PSD95");
		Dialog.addString("Vesicle Marker Name:", "e.g. Synaptophysin");
		Dialog.addString("Target Marker Name:", "e.g. ELKS1a");
	}
	else if ((postReviewOption == 1 || blendMacroOption == 1) && File.exists(tempOptDirectory)){
		Dialog.addCheckbox("Save Individual Synapses and Create Averaged Images?", 1);
		Dialog.addString("Active Zone or Post Synaptic Marker Name:", rows[12], lengthOf(rows[12]));
		Dialog.addString("Vesicle Marker Name:", rows[13], lengthOf(rows[13]));
		Dialog.addString("Target Marker Name:", rows[14], lengthOf(rows[14]));
	}
	
	if (preReviewOption == 1 || postReviewOption == 1 || blendMacroOption == 1){
		Dialog.show();
	}
	
	if (preReviewOption == 1){
		finalWidth = Dialog.getNumber();
		finalLength = Dialog.getNumber();
		minimumVClength = Dialog.getNumber();
		maximumVClength = Dialog.getNumber();
		minimumAZlength = Dialog.getNumber();
		maximumAZwidth = Dialog.getNumber();
		AZaspectRatioMin = Dialog.getNumber();
		maxInnerEdgeDistance = Dialog.getNumber();
		maxOuterEdgeDistance = Dialog.getNumber();
		scanLineLength = Dialog.getNumber();
		scanningFraction = Dialog.getNumber();
		scanningMicrometers = Dialog.getNumber();
		preOverWriteOption = Dialog.getCheckbox();
	}
	else if (File.exists(tempOptDirectory)) {
		finalWidth = parseFloat(rows[0]);
		finalLength = parseFloat(rows[1]);
		minimumVClength = parseFloat(rows[2]);
		maximumVClength = parseFloat(rows[3]);
		minimumAZlength = parseFloat(rows[4]);
		maximumAZwidth = parseFloat(rows[5]);
		AZaspectRatioMin = parseFloat(rows[6]);
		maxInnerEdgeDistance = parseFloat(rows[7]);
		maxOuterEdgeDistance = parseFloat(rows[8]);
		scanLineLength = parseFloat(rows[9]);
		scanningFraction = parseFloat(rows[10]);
		scanningMicrometers = parseFloat(rows[11]);
		preOverWriteOption = 0;
	}
	else{
		finalWidth = 0.25;
		finalLength = 1.2;
		minimumVClength = 0.3;
		maximumVClength = 2;
		minimumAZlength = 0.2;
		maximumAZwidth = 0.4;
		AZaspectRatioMin = 1.5;
		maxInnerEdgeDistance = 0.05;
		maxOuterEdgeDistance = 0.2;
		scanLineLength = 1;
		scanningFraction = NaN;
		scanningMicrometers = 0.25;
		preOverWriteOption = 0;
	}
	
	
	if (postReviewOption == 1 || blendMacroOption == 1){
		if (postReviewOption == 1) snipAndBlend = Dialog.getCheckbox();
		activeZoneMarker = Dialog.getString();
		vesicleMarker = Dialog.getString();
		targetMarker = Dialog.getString();
	}
	else if (File.exists(tempOptDirectory)) {
		activeZoneMarker = rows[12];
		vesicleMarker = rows[13];
		targetMarker = rows[14];
	}
	else{
		activeZoneMarker = "e.g. Bassoon or PSD95";
		vesicleMarker = "e.g. Synaptophysin";
		targetMarker = "e.g. ELKS1a";
	}

	if (sortOption == 1) {
		dir = getDirectory("Choose File Containing All Images to Sort");
		
		prePostVar = "Sort";
		count = 0;
		countFiles(dir);

		var pathPassString = "";
		varLast = 0;
		processFiles(dir);
		
		compDir = File.directory;
	}
	else {
		compDir = getDirectory("Choose File Containing Condition-Named Folders (E.g. Banana and Apple)");
	}
	
	ConditionsFF = getFileList(compDir);
	
	
	tempOptions = File.open(tempOptDirectory);
	print(tempOptions, finalWidth); //0
	print(tempOptions, finalLength); //1
	print(tempOptions, minimumVClength); //2
	print(tempOptions, maximumVClength); //3
	print(tempOptions, minimumAZlength); //4
	print(tempOptions, maximumAZwidth); //5
	print(tempOptions, AZaspectRatioMin); //6
	print(tempOptions, maxInnerEdgeDistance); //7
	print(tempOptions, maxOuterEdgeDistance); //8
	print(tempOptions, scanLineLength); //9
	print(tempOptions, scanningFraction); //10
	print(tempOptions, scanningMicrometers); //11
	print(tempOptions, activeZoneMarker); //12
	print(tempOptions, vesicleMarker); //13
	print(tempOptions, targetMarker); //14
	print(tempOptions, compDir); //15
	File.close(tempOptions);
	
	
	
	setBatchMode("hide");////////////////////////////////////////////////////
	var saveDirectory;
	saveDirectory = compDir; 
	hideResults();

	if (preOverWriteOption == 1) {
		clearOldFiles(compDir);
	}
	
	if (preReviewOption == 1) {
		prePostVar = "Pre";
		count = 0;
		countFiles(compDir);
		
		varLast = 0;
		var timeTotal = 0;
		timeCounter = 0;
		processFiles(compDir);
	}
	
	if (reviewOption == 1) {
		prePostVar = "Review";
		javascriptString = "new MacroInstaller().install(\" macro 'shortcut1 [d]' {runMacro('shortcutSkip')}; \"  \n + \" macro 'shortcut2 [a]' {runMacro('shortcutBack')}; \"  \n + \" macro 'shortcut3 [c]' {runMacro('shortcutCondition')}; \"  \n + \" macro 'shortcut4 [w]' {runMacro('shortcutKeep')}; \"  \n + \" macro 'shortcut5 [s]' {runMacro('shortcutDelete')} \"  \n + \" macro 'shortcut6 [e]' {runMacro('shortcutExit')} \");";
		success = eval("script", javascriptString);
		count = 0;
		countFiles(compDir);

		var pathPassString = "";
		varLast = 0;
		processFiles(compDir);
		if (isOpen("Log")) close("Log");
	}
	
	
	if (postReviewOption == 1) {
		prePostVar = "Post";
		clearTextFiles(compDir);

		if (snipAndBlend == 1){
			compDirI = saveDirectory + "Individual Synapses" + File.separator;
			if (File.exists(compDirI)) clearFile(compDirI);
			else File.makeDirectory(compDirI);
			for (ii = 0; ii < ConditionsFF.length; ii++) {
				if (!matches(ConditionsFF[ii], ".*Individual Synapses.*") && !matches(ConditionsFF[ii], ".*ROI Data.*")){
					File.makeDirectory(compDirI + ConditionsFF[ii] + File.separator);
					File.makeDirectory(compDirI + ConditionsFF[ii] + File.separator + activeZoneMarker + File.separator);
					File.makeDirectory(compDirI + ConditionsFF[ii] + File.separator + vesicleMarker + File.separator);
					File.makeDirectory(compDirI + ConditionsFF[ii] + File.separator + targetMarker + File.separator);
				}
			}
		}

		count = 0;
		countFiles(compDir);
		
		varLast = 0;
		processFiles(compDir);
	}
	

	if (blendMacroOption == 1) runMacro("Macro Blend Images", saveDirectory + "Individual Synapses" + File.separator);
	if (confocalAnalysisOption == 1) runMacro("Confocal Analysis", saveDirectory);
	
	setBatchMode(false);
	run("Close All");
	close("Roi Manager");
	if (isOpen("Results")) close("Results");
	if (isOpen("Exception")) close("Exception");
	
	Dialog.createNonBlocking("Exit or Continue");
	rerunAnalysis = newArray("Main Menu", "Exit");
	Dialog.addChoice("", rerunAnalysis, 0);
	var onVar = 0;
	Dialog.show();
	ExitAnalysisChoice = Dialog.getChoice();
}

function countFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (((endsWith(list[i], "/")) || (endsWith(list[i], fs))) && (!matches(list[i], ".*Individual Synapses.*")) && (!matches(list[i], ".*ROI Data.*"))){
			countFiles(""+dir+list[i]);
		}
		else if (endsWith(list[i], ".tif")) count++;
		else if ((prePostVar == "Sort") && endsWith(list[i], ".lif")) count++;
	}
}




function processFiles(dir) {
	list = getFileList(dir);
	
	for (i=0; i<list.length; i++) {
		if ((varLast == 0) && (prePostVar == "Review")){
			roiManager("reset");
			checkForImages = getList("image.titles");
			for (im = 0; im < checkForImages.length; im++) {
				selectWindow(checkForImages[im]);
				close();
			}
		}
		if (((endsWith(list[i], "/")) || (endsWith(list[i], fs))) && (!matches(list[i], ".*Individual Synapses.*")) && (!matches(list[i], ".*ROI Data.*")))
			processFiles(""+dir+list[i]);
		else if (endsWith(list[i], ".tif")){
			varLast++;
			path = dir+list[i];
			processFile(path);
		}
		else if ((prePostVar == "Sort") && endsWith(list[i], ".lif")){
			varLast++;
			path = dir+list[i];
			pathPassString = pathPassString + "|" + path;
			if (varLast == count) runMacro("Separate Hyperstack", pathPassString);
		}
	}
}




function processFile(path) {
	if (prePostVar != "Review" && prePostVar != "Post") open(path);
	
//	if (prePostVar != "Review" && prePostVar != "Pre" && prePostVar != "Sort") setBatchMode("exit and display");
	
	if (prePostVar != "Review" && prePostVar != "Post") mainWindow = getTitle(); 
	
	if (prePostVar == "Pre"){
		if (!File.exists(saveDirectory + "ROI Data" + File.separator)) File.makeDirectory(saveDirectory + "ROI Data" + File.separator);
		if(!File.exists(path + "ROIs.zip")){
			selectWindow(mainWindow);
			timeBefore = getTime();
			
			runMacro("AutoLine ROIs", path);
			
			timeCounter++;
			timeTotal = timeTotal + (((getTime() - timeBefore)/1000)/60);
			timeAverage = timeTotal/timeCounter;
			predictedTime = timeAverage * (count - timeCounter);
			print("\\Clear");
			print("Time Remaining (estimated): " + toString(round(predictedTime)) + " minutes");
			print(toString(timeCounter) + " out of " + toString(count) + " images");
			print("Time Elapsed: " + toString(timeTotal) + " minutes");
			print("Time per image (average): " + toString(timeAverage) + " minutes");
		}
	}
	
	if (prePostVar == "Review"){
		pathPassString = pathPassString + "|" + path;
		if (varLast == count){
			pathPassString = pathPassString + "|" + saveDirectory;
			runMacro("Review Selections", pathPassString);
			setBatchMode(false);
			close("*");
			roiManager("reset");
			javascriptString = "new MacroInstaller().install(\" macro 'clearShortcuts' {variable = 1;}; \");";
			success = eval("script", javascriptString);
		}
	}
	
	if (prePostVar == "Post"){
		print("\\Clear");
		print(toString(varLast) + " out of " + toString(count) + " images");
		if (File.exists(path + "finalROIs.zip")){
			passString = path + "|" + vesicleMarker + "|" + activeZoneMarker + "|" + targetMarker;
			if (snipAndBlend == 1) runMacro("Macro Snip Synapses", passString); 
			else open(path);
			mainWindow = getTitle();
			runSideViews(path, mainWindow);
		}
	}

	if (prePostVar == "Sort"){
		pathPassString = pathPassString + "|" + path;
		if (varLast == count){
			runMacro("Separate Hyperstack", pathPassString);
		}
	}
	
//    if (prePostVar != "Sort") setBatchMode("hide");
	if ((prePostVar == "Post") && (varLast == count) && (snipAndBlend == 1)) runMacro("Macro Blend Images", saveDirectory + "Individual Synapses" + File.separator); 
	if (isOpen("Exception")) close("Exception");
}

function runSideViews(path, mainWindow){
	roiManager("reset");
	roiManager("open", path + "finalROIs.zip");
	channelWindows = newArray(3);
	channelNames = newArray(3);
//	setBatchMode("hide");  

	channelNames[0] = vesicleMarker;
	channelNames[1] = activeZoneMarker;
	channelNames[2] = targetMarker;
	selectWindow(mainWindow);
	getPixelSize(unit, pixelWidth, pixelHeight);
	run("Select All");
	run("Duplicate...", "duplicate channels=1");
	channelWindows[0] = getImageID();
	
	selectWindow(mainWindow);
	run("Select All");
	run("Duplicate...", "duplicate channels=2");
	channelWindows[1] = getImageID();
	
	selectWindow(mainWindow);
	run("Select All");
	run("Duplicate...", "duplicate channels=3");
	channelWindows[2] = getImageID();
	
	if (lastIndexOf(path, fs) > lastIndexOf(path, "/")) dirSV = substring(path, 0, lastIndexOf(path, fs));
	else dirSV = substring(path, 0, lastIndexOf(path, "/"));
	
	dirSVss = dirSV;

	if (lastIndexOf(dirSVss, fs) > lastIndexOf(dirSVss, "/")) ConditionsFFns = substring(dirSVss, lastIndexOf(dirSVss, fs) + 1, lengthOf(dirSVss));
	else ConditionsFFns = substring(dirSVss, lastIndexOf(dirSVss, "/") + 1, lengthOf(dirSVss));
	for(K=0; K < 3;K++){
		run("Clear Results");
		name = ConditionsFFns + channelNames[K] + ".txt";
		if (File.exists(dirSV + File.separator + name)) run("Results... ", "open=[" + dirSV + File.separator + name + "]");
		selectImage(channelWindows[K]);
		for(j=0; j < roiManager("count"); j++){ 
			roiManager("Select", j);
			roiName = Roi.getName;
			y = getProfile();
			for (ii=0; ii<y.length; ii++){
				setResult(roiName + toString(varLast - 1), ii, y[ii]);
			}
			setResult(roiName + toString(varLast - 1), y.length, NaN);
		}
		run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column");
		selectWindow("Results");
		saveAs("Results", dirSV + File.separator + name);
		selectImage(channelWindows[K]);
		close();
	}
	selectWindow(mainWindow);
	close();
	roiManager("reset");
//	setBatchMode("Exit and Display");
}

function clearOldFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (((endsWith(list[i], "/")) || (endsWith(list[i], fs))))
			clearOldFiles(""+dir+list[i]);
		if (endsWith(list[i], "ROIs.zip") || endsWith(list[i], "info.csv") || endsWith(list[i], "plots.csv") || endsWith(list[i], ".txt")){
			path = dir+list[i];
			deletesuccess = File.delete(path);
		}
	}
}

function clearTextFiles(dir) {
//	firstDeletion = 0;
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (((endsWith(list[i], "/")) || (endsWith(list[i], fs))))
			clearTextFiles(dir+list[i]);
		if (endsWith(list[i], ".txt")){
			path = dir+list[i];
//			if (firstDeletion == 0) {
//				waitForUser("Are you sure you want to overwrite files? (Text Files)");
//				firstDeletion = 1;
//			}
			deletesuccess = File.delete(path);
		}
	}
}

function clearFile(dir) {
	list = getFileList(dir);
	while (list.length > 0){
		for (i=0; i<list.length; i++) {
			path = dir+list[i];
			if (((endsWith(list[i], "/")) || (endsWith(list[i], fs)))) clearFile(path);
			deletesuccess = File.delete(path);
		}
		list = getFileList(dir);
	}
}

function hideResults() {
	call("ij.gui.ImageWindow.setNextLocation", -1100, -1100)
	newImage("nullImage", "8-bit", 1, 1, 1);
	nullImage = getImageID();
	run("Select All");
	run("Measure");
	close();
	selectWindow("Results");
	setLocation(-1000, -1000);
	run("Clear Results");
}
