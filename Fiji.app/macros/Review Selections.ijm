// Review Selections MACRO 

// To get rid of the selections popping up everytime a new image loads, create temporary image, paste into image, then try copying and pasting without a selection. If that doesn't work,
// then you can create two loops, one that collects the pixel data (with an X and Y nested loop) and another that pastes it into the image that is never closed

// http://www.fileformat.info/info/unicode/char/search.htm?q=delta&preview=entity for more character codes (look for 3 number HTML Entity (Decimal)
tempDirectory = getDirectory("imagej");
tempOptDirectory = tempDirectory + "ChrisMacroTempOptions.txt";
tempRevDirectory = tempDirectory + "ChrisReviewOptions.txt";
pathPassString = getArgument();
pathPass = split(pathPassString, "|");
saveDirectory = pathPass[pathPass.length - 1];
pathPass[pathPass.length - 1] = "";
combinedFolder = saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator;
keyOpt = 0;
quickSelection = 0;
customNumberToPlot = NaN;
run("Colors...", "foreground=black background=white selection=white");
setOption("DebugMode", false);
setOption("ExpandableArrays", true);
run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column save_row");
var shiftKey = 0;
var ctrlKey = 0;
run("Plots...", "width=160 height=90 font=12 draw minimum=0 maximum=0 sub-pixel");
run("Console");
run("Hide Console Pane");

if (File.exists(tempOptDirectory)) {
	filestring=File.openAsString(tempOptDirectory); 
	rows=split(filestring, "\n");
}
if (File.exists(tempRevDirectory)) {
	filestring=File.openAsString(tempRevDirectory); 
	reviewSettings=split(filestring, "\n");

	xPlot1 = parseFloat(reviewSettings[0]);
	yPlot1 = parseFloat(reviewSettings[1]);
	xPlot2 = parseFloat(reviewSettings[2]);
	yPlot2 = parseFloat(reviewSettings[3]);
	lastSquareSize = parseFloat(reviewSettings[4]);
	zoom = parseFloat(reviewSettings[5]);
	AZzoom = parseFloat(reviewSettings[6]);
	dialogX = parseFloat(reviewSettings[7]);
	dialogY = parseFloat(reviewSettings[8]);
	dialogLocl = reviewSettings[9];
	xWin = parseFloat(reviewSettings[10]);
	yWin = parseFloat(reviewSettings[11]);
	AZxWin = parseFloat(reviewSettings[12]);
	AZyWin = parseFloat(reviewSettings[13]);
	displayMode = reviewSettings[14];
	activeChannels = reviewSettings[15];
	blocksizeChoice = parseFloat(reviewSettings[16]);
}
else{
	xPlot1 = 0;
	yPlot1 = 0;
	xPlot2 = xPlot1+300;
	yPlot2 = yPlot1 + 0;
	lastSquareSize = 4;
	zoom = 400;
	AZzoom = 100;
	dialogX = 100;
	dialogY = 100;
	dialogLocl = "Top Right";
	xWin = 0;
	yWin = 0;
	AZxWin = 0;
	AZyWin = 0;
	displayMode = "composite";
	activeChannels = "11";
	blocksizeChoice = 30;	
}

dialogLoc = dialogLocl;
k = 0;
squareSize = lastSquareSize;
keepCount = 0;
lastSortChoice = " ";
sortChoice = lastSortChoice;
individualSortChoice = "";
blocksize = blocksizeChoice;
viewVerticalLast = 0;
viewVertical = viewVerticalLast;
lastViewChoice = "View All";
viewChoice = lastViewChoice;
windowNumber = 0;
skipToRoi = 0;
lastRoiSelection = 0;
editROI = 0;
wasEditROI = 0;
nFilteredROIs = 0;

roiDefaultColor = "#20e2e2e2";
finalWidth = parseFloat(rows[0]);
finalLength = parseFloat(rows[1]);
saveDirectorySubfolders = getFileList(saveDirectory);
saveDirectorySubfolders = Array.delete(saveDirectorySubfolders, "ROI Data/");
saveDirectorySubfolders = Array.delete(saveDirectorySubfolders, "ROI Data" + File.separator);
saveDirectorySubfolders = Array.delete(saveDirectorySubfolders, "Individual Synapses/");
saveDirectorySubfolders = Array.delete(saveDirectorySubfolders, "Individual Synapses" + File.separator);
checkBoxArray = newArray(NaN, NaN);
weightValueP = newArray(NaN, NaN);
weightValueN = newArray(NaN, NaN);
setBatchMode("hide");
newImage("null", "8-bit", 1, 1, 1);
setBatchMode("show");
close();
close("Roi Manager");

for (w = 0; w < pathPass.length; w++) if (!File.exists(pathPass[w] + "ROIs.zip")) pathPass[w] = "";
pathPass = Array.delete(pathPass, "");
if (pathPass.length < 1) exit("No Images Open");
shuffle(pathPass);

openListDir = newArray(pathPass.length);
openList = newArray(pathPass.length);
for (w = 0; w < pathPass.length; w++) {
	index = lastIndexOf(pathPass[w], File.separator);
	indexB = lastIndexOf(pathPass[w], "/");
	if (indexB > index) index = indexB;
	openListDir[w] = substring(pathPass[w], 0, index + 1);
	openList[w] = substring(pathPass[w], index + 1, lengthOf(pathPass[w]));
}

run("Clear Results");
// Save information linking each image to which repetition(culture) it belongs to in an easily retrievable array format:
repNumber = NaN;
if (File.exists(combinedFolder +"Repetitions.csv")) {
	run("Results... ", "open=[" + combinedFolder +"Repetitions.csv]");
	repResultHeadings = split(String.getResultsHeadings, "\t");
	repResultHeadings = Array.delete(repResultHeadings, " ");
	repResultHeadings = Array.delete(repResultHeadings, "");
	numberOfRepetitions = repResultHeadings.length;
	repetitionNumber = newArray(openList.length);
	for (w = 0; w < openList.length; w++) {
		repetitionNumber[w] = NaN;
		for (i = 0; i < nResults; i++) {
		    for (ii = 0; ii< numberOfRepetitions; ii++) {
		    	resultString = getResultString(repResultHeadings[ii], i);
		    	comparisonString = replace(openList[w], ".tif", "");
				if (comparisonString == resultString) repetitionNumber[w] = ii;
		    }
		}
		if (isNaN(repetitionNumber[w])) print(openList[w] + " is not associated with a repetition(culture)");
	}
	run("Clear Results");
	selectWindow("Results");
	setLocation(-1000, -1000);
	//now, the culture number for each image is stored in the repetitionNumber array
	//and that number corresponds to the headings in the repResultHeadings array

	if (numberOfRepetitions > 1) {
		repetitionChoices = Array.getSequence(numberOfRepetitions + 1);
		for (i = 0; i < numberOfRepetitions; i++) repetitionChoices[i] = repResultHeadings[i];
		repetitionChoices[numberOfRepetitions] = "Analyze All Together";
		Dialog.createNonBlocking("Repetitions(Cultures)");
		Dialog.addChoice("Choose Repetition(Culture) to analyze:" , repetitionChoices);
		Dialog.show();
		repetitionChoice = Dialog.getChoice();
	
		if (repetitionChoice != "Analyze All Together") {
			for (w = 0; w < pathPass.length; w++) {
				if (repResultHeadings[repetitionNumber[w]] != repetitionChoice) pathPass[w] = "";
				else if (isNaN(repNumber)) repNumber = repetitionNumber[w];
			}
			pathPass = Array.delete(pathPass, "");
			if (pathPass.length < 1) exit("No Images Open");
			shuffle(pathPass);
			
			openListDir = newArray(pathPass.length);
			openList = newArray(pathPass.length);
			for (w = 0; w < pathPass.length; w++) {
				index = lastIndexOf(pathPass[w], File.separator);
				indexB = lastIndexOf(pathPass[w], "/");
				if (indexB > index) index = indexB;
				openListDir[w] = substring(pathPass[w], 0, index + 1);
				openList[w] = substring(pathPass[w], index + 1, lengthOf(pathPass[w]));
			}
		}
	}
}
else print("No Repetitions CSV file");

if (isNaN(repNumber)) repNumber = "";
else repNumber = toString(repNumber);

if (File.exists(combinedFolder + "filterSettings" + repNumber + ".csv")) {
	filestring=File.openAsString(combinedFolder + "filterSettings" + repNumber + ".csv"); 
	lastChoiceSettings = split(filestring, ",");
}
else {
	lastChoiceSettings = newArray(125);
	lastChoiceSettings = Array.fill(lastChoiceSettings, NaN);
}

grouplist = newArray(openList.length);
grouplist = Array.fill(grouplist, NaN);
condition = newArray(openList.length);
possibleConditions = saveDirectorySubfolders;
for (C = 0; C < possibleConditions.length; C++) possibleConditions[C] = substring(possibleConditions[C], 0, lengthOf(possibleConditions[C]) - 1);
shuffle(possibleConditions);

for (w = 0; w < pathPass.length; w++) {
	temp = substring(openListDir[w], 0, lengthOf(openListDir[w]) - 1);
	index = lastIndexOf(temp, File.separator);
	indexB = lastIndexOf(temp, "/");
	if (indexB > index) index = indexB;
	condition[w] = substring(temp, index + 1, lengthOf(temp));
	for (C = 0; C < possibleConditions.length; C++) if (condition[w] == possibleConditions[C]) grouplist[w] = C;
}

aExit = newArray("Continue", "Quick Mode", "Reset", "Exit and Save");
CPL = newArray("Middle Right", "Top", "Top Right", "Bottom", "Bottom Right");
individualSortChoices = newArray("Length", "overlap", "halfMaxWidthVMminusOverlap", "halfMaxWidthAZ", "maxVM", "maxAZ", "noiseVM", "noiseAZ", "backVM", "SnVM", "SnAZ", "extraPeak", "VCarea", "VCmean", "VCstDv", "surroundingMean", "surroundingStDv", "AZarea", "AZmean", "AZstDv", "VCdepth", "distanceFromEdge");

sortChoicesDisplayNames = newArray("", "", "Length", "Overlap", "VCM Half-Max Width", "AZM Half-Max Width", "VCM Max", "AZM Max", "VCM Noise", "AZM Noise", "VCM Back / VCM Max", "VCM Signal to Noise", "AZM Signal to Noise", "# of Extra Peaks", "VCM Area", "VCM Mean", "VCM StDev", "Mean of Signal Surrounding VCM", "StDev of Signal Surrounding VCM", "AZM Area", "AZM Mean", "AZM StDev", "VC Depth", "AZM Distance from VCM Edge");
sortChoicesUnits = newArray("", "", getInfo("micrometer.abbreviation"), getInfo("micrometer.abbreviation"), getInfo("micrometer.abbreviation"), getInfo("micrometer.abbreviation"), "FIU", "FIU", "FIU", "FIU", "", "", "", "Peaks", getInfo("micrometer.abbreviation") + "^2", "FIU", "FIU", "FIU", "FIU", getInfo("micrometer.abbreviation") + "^2", "FIU", "FIU", getInfo("micrometer.abbreviation"), getInfo("micrometer.abbreviation"));
sortChoicesResolution = newArray(NaN, NaN, 0.025, 0.025, 0.025, 0.025, 5, 5, 5, 5, 0.05, 0.05, 0.05, 1, 0.01, 5, 1, 5, 1, 0.0025, 5, 1, 0.025, 0.025);

dialogSortChoices = newArray(" ", "Combination", "Individual"); 
sortChoices = newArray(" ", "Combination", "Length", "overlap", "halfMaxWidthVMminusOverlap", "halfMaxWidthAZ", "maxVM", "maxAZ", "noiseVM", "noiseAZ", "backVM", "SnVM", "SnAZ", "extraPeak", "VCarea", "VCmean", "VCstDv", "surroundingMean", "surroundingStDv", "AZarea", "AZmean", "AZstDv", "VCdepth", "distanceFromEdge"); 
viewChoices = newArray("View All", "Unseen", "Skipped", "Chosen", "Deleted");
combinationPassedROIs = newArray(0);
titlet = "-----------ImageThatHasYetToBeOpened----------";
allLinescans = "-----------ImageThatHasYetToBeOpened2----------";
quickSelectionWindow = "-----------ImageThatHasYetToBeOpened3----------";


for (restart = 0; restart < 2; restart++) {
	exitState = "Continue";
	run("Hide Console Pane");
	deletedROIsString = newArray(saveDirectorySubfolders.length);
	for (i = 0; i < saveDirectorySubfolders.length; i++) deletedROIsString[i] = "";
	ROIwidthString = newArray(saveDirectorySubfolders.length);
	for (i = 0; i < saveDirectorySubfolders.length; i++) ROIwidthString[i] = "";
	chosenNumber = newArray(saveDirectorySubfolders.length);
	skippedNumber = newArray(saveDirectorySubfolders.length);
	chosenNumberi = newArray(openList.length);
	skippedNumberi = newArray(openList.length);
	excludedNumber = newArray(saveDirectorySubfolders.length);
	excludedNumberi = newArray(openList.length);
	totalROIs = 0;
	currentROIfloor = newArray(openList.length);
	Array.fill(currentROIfloor, 0);
	
	call("ij.gui.ImageWindow.setNextLocation", -1100, -1100)
	newImage("nullImage", "8-bit", 1000, 1000, 1);
	nullImage = getTitle();
	roiManager("Centered", "true");
	for (w = 0; w < openList.length; w++) {
		selectWindow(nullImage);
		roiManager("reset");
		if (File.exists(pathPass[w] + "ROIs.zip")) roiManager("open", pathPass[w] + "ROIs.zip");
		else continue;
		
		RoiC = roiManager("count");
		deletionArray = Array.reverse(Array.getSequence(RoiC));
		run("Set Measurements...", "  redirect=None decimal=3");
		for (j = 0; j < RoiC; j++) {
			roiManager("select", deletionArray[j]);
			roiManager("measure");
			if (getResult("Length", 0) == 0 || isNaN(getResult("Length", 0))) roiManager("delete");
			run("Clear Results");
		}
		RoiCafter = roiManager("count");
		
		if (RoiC != RoiCafter) {
			deletesuccess = File.delete(openListDir[w] + openList[w] + "ROIs.zip");
			if (RoiC > 0){
				roiManager("deselect");
				roiManager("save", openListDir[w] + openList[w] + "ROIs.zip");
			}
		}
		
		RoiC = roiManager("count");
		for (j = 0; j < RoiC; j++) {
			roiManager("select", j);
			if (Roi.getStrokeColor == "#4000ff00"){
				chosenNumber[grouplist[w]] = (chosenNumber[grouplist[w]])+1;
				chosenNumberi[w] = chosenNumberi[w]+1;
			}
			else if (Roi.getStrokeColor == "#21e2e2e2"){
				skippedNumber[grouplist[w]] = (skippedNumber[grouplist[w]])+1;
				skippedNumberi[w] = skippedNumberi[w]+1;
			}
			
			if (Roi.getStrokeColor == "#80ff0000"){
				excludedNumber[grouplist[w]] = (excludedNumber[grouplist[w]])+1;
				excludedNumberi[w] = excludedNumberi[w]+1;
				if (deletedROIsString[grouplist[w]] == "") deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "1";
				else deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "|" + "1";
			}
			else if (deletedROIsString[grouplist[w]] == "") deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "0";
			else deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "|" + "0";

		}
		currentROIfloor[w] = totalROIs;
		totalROIs = totalROIs + RoiC;
	}
	roiManager("Centered", "false");
	selectImage(nullImage);
	close();
	run("Clear Results");
	
	
	//Preloading and formatting plot profile csv file into arrays
	str = File.openAsString(saveDirectory + File.separator+ "ROI Data" + File.separator + "Combination" + File.separator + "Combined_plots.csv");
	newline = indexOf(str, "\n");
	row1Length = 1;
	whileLoop = 1;
	fromIndex = 0;
	while (whileLoop == 1){
		comma = indexOf(str, ",", fromIndex);
		if (comma < newline) {
			row1Length++;
			fromIndex = comma + 1;
		}
		else whileLoop = 0;
	}
	fileMatrix = split(str, ",\n");

	usedColumns = newArray(row1Length);
	indexEnd1Column = newArray(openList.length);
	profile1Column = newArray(openList.length);
	profile2Column = newArray(openList.length);
	profile3Column = newArray(openList.length);
	for (w = 0; w < openList.length; w++) {
		for (ii = 0; ii < row1Length; ii++) {
			if (usedColumns[ii] == 0){
				if (fileMatrix[ii] == "indexEnd1" + openList[w]) {
					indexEnd1Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile1" + openList[w]) {
					profile1Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile2" + openList[w]) {
					profile2Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile3" + openList[w]) {
					profile3Column[w] = ii;
					usedColumns[ii] = 1;
				}
			}
		}
	}
	//Preloading and formatting plot profile csv file into arrays^

	
	//Preloading and formatting plot profile csv file into arrays
	str = File.openAsString(saveDirectory + File.separator+ "ROI Data" + File.separator + "Combination" + File.separator + "Combined_plots.csv");
	newline = indexOf(str, "\n");
	row1Length = 1;
	whileLoop = 1;
	fromIndex = 0;
	while (whileLoop == 1){
		comma = indexOf(str, ",", fromIndex);
		if (comma < newline) {
			row1Length++;
			fromIndex = comma + 1;
		}
		else whileLoop = 0;
	}
	fileMatrix = split(str, ",\n");

	usedColumns = newArray(row1Length);
	indexEnd1Column = newArray(openList.length);
	profile1Column = newArray(openList.length);
	profile2Column = newArray(openList.length);
	profile3Column = newArray(openList.length);
	for (w = 0; w < openList.length; w++) {
		for (ii = 0; ii < row1Length; ii++) {
			if (usedColumns[ii] == 0){
				if (fileMatrix[ii] == "indexEnd1" + openList[w]) {
					indexEnd1Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile1" + openList[w]) {
					profile1Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile2" + openList[w]) {
					profile2Column[w] = ii;
					usedColumns[ii] = 1;
				}
				if (fileMatrix[ii] == "profile3" + openList[w]) {
					profile3Column[w] = ii;
					usedColumns[ii] = 1;
				}
			}
		}
	}
	firstRunThrough = 1;
	//Preloading and formatting plot profile csv file into arrays^
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	minFromCI = newArray(sortChoices.length);
	maxFromCI = newArray(sortChoices.length);
	sortArrayTargetMaxString = newArray(saveDirectorySubfolders.length);
	
	for (C = 0; C < saveDirectorySubfolders.length; C++) {
		run("Hide Console Pane");

		WSaveStart = newArray(openList.length);
		WSaveEnd = newArray(openList.length);
		roiManager("reset");
	    for (w = 0; w < openList.length; w++) {
	    	if (grouplist[w] == C){
				if (File.exists(pathPass[w] + "ROIs.zip")){
					WSaveStart[w] = roiManager("count");
					roiManager("open", pathPass[w] + "ROIs.zip");
					WSaveEnd[w] = roiManager("count");
				}
	    	}
	    }
	    
	    RoiC = roiManager("count");
	    roiSaveIndexes = Array.getSequence(RoiC);

		if (!File.exists(saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator)) File.makeDirectory(saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator);
		

		run("Clear Results");
		Combined_results = "Combined_info" + toString(C) + "_" + repNumber + ".csv";
	    count = 0; 
	    countForRois = 0;
	    windowIdentifier = newArray(RoiC);
	    if (File.exists(combinedFolder+Combined_results)) deletesuccess = File.delete(combinedFolder+Combined_results);
	    for (w = 0; w < openList.length; w++) {
	    	if (grouplist[w] == C){
				str = File.openAsString(saveDirectory + "ROI Data" + File.separator + openList[w] + "ROIinfo.csv");
				if (count == 0) {
					lastlineEnd = lengthOf(str);
					stringForCount = replace(str, "\n", "");
					totalcount = lastlineEnd - lengthOf(stringForCount) - 1;
					File.saveString(str, combinedFolder+Combined_results);
				}
				else {
					lastlineEnd = lengthOf(str);
					stringForCount = replace(str, "\n", "");
					totalcount = lastlineEnd - lengthOf(stringForCount) - 1;
					lineOneEnd = indexOf(str, '\n'); 
					substr = substring(str, lineOneEnd + 1, lastlineEnd - 1);
					File.append(substr, combinedFolder+Combined_results); 
				}
				for (ii = 0; ii < totalcount; ii++) {
					windowIdentifier[countForRois] = w;
					countForRois++;
				}
				count++;
			}
		}
		run("Clear Results");
		
		run("Results... ", "open=[" + combinedFolder +"Combined_info" + toString(C) + "_" + repNumber + ".csv]");

		if (firstRunThrough == 1) {

			//Save ROI order based on max target value, for filtering later
			profile3Max = newArray(RoiC);
			for (jj = 0; jj < RoiC; jj++) {
				w = windowIdentifier[jj];
				currentROI = currentROIfloor[w] + jj;
				RoiForCW = WSaveEnd[w] - WSaveStart[w];
		
				indexEnd1 = newArray(RoiForCW+1);
		
				for (ii = 0; ii < RoiForCW+1; ii++){
					indexEnd1[ii] = parseInt(fileMatrix[((ii + 1) * row1Length)+indexEnd1Column[w]]);
				}
				
				start = indexEnd1[jj-WSaveStart[w]]+1;
				end = indexEnd1[jj+1-WSaveStart[w]];
				for (ii = start; ii < end; ii++) {
					rowIndex = ((ii + 1) * row1Length);
					if (parseFloat(fileMatrix[rowIndex + profile3Column[w]]) > profile3Max[jj]) profile3Max[jj] = parseFloat(fileMatrix[rowIndex + profile3Column[w]]);
				}

				if (ROIwidthString[C] == "") ROIwidthString[C] = ROIwidthString[C] + getResultString("halfMaxWidthAZ", jj);
				else ROIwidthString[C] = ROIwidthString[C] + "|" + getResultString("halfMaxWidthAZ", jj);
			}
			sortArrayTargetMax = Array.rankPositions(profile3Max);
			sortArrayTargetMaxString[C] = toString(sortArrayTargetMax[0]);
			for (i = 1; i < sortArrayTargetMax.length; i++) {
				sortArrayTargetMaxString[C] = sortArrayTargetMaxString[C] + "|" + toString(sortArrayTargetMax[i]);
			}
			

			//Save min and max of all attributes per attribute regardless of condition
			for (i = 2; i < sortChoices.length; i++) {
				for (j = 1; j < nResults; j++) {
					if (minFromCI[i] > abs(getResult(sortChoices[i],j)) || (C == 0 && j == 1)) minFromCI[i] = abs(getResult(sortChoices[i],j));
					if (maxFromCI[i] < abs(getResult(sortChoices[i],j)) || (C == 0 && j == 1)) maxFromCI[i] = abs(getResult(sortChoices[i],j));
				}
			}
			if (C == saveDirectorySubfolders.length - 1) {
				firstRunThrough = 0;
				C = -1;
			}
			run("Clear Results");
			continue;
		}
		
		filterState = newArray(RoiC);
		sortArray = Array.getSequence(RoiC);
		exceptionTrigger = 0;
		newWindow = 1;

/////////////////////////////

		for (j = 0; j < RoiC; j++) {
			if (j == 0) exitState = "Back";
			else if (j >= RoiC - nFilteredROIs){
				j = RoiC;
				continue;
			}
			print("\\Clear");
before = getTime();
			w = windowIdentifier[sortArray[j]];
			currentROI = currentROIfloor[w] + sortArray[j];

			 
			if(!isOpen("nullImage")) {
				call("ij.gui.ImageWindow.setNextLocation", -1100, -1100)
				newImage("nullImage", "8-bit", 1, 1, 1);
			}
			roiManager("select", sortArray[j]);
			roiColor = Roi.getStrokeColor;

			if(exitState != "Back" && ((viewChoice == "Unseen" && roiColor != roiDefaultColor) || (viewChoice == "Skipped" && roiColor != "#21e2e2e2") || (viewChoice == "Chosen" && roiColor != "#4000ff00") || (viewChoice == "Deleted" && roiColor != "#80ff0000"))){
				continue;
			}


			if ((((roiColor != "#80ff0000" || exitState == "Back" || exceptionTrigger == 1) && filterState[j] == 0) || newWindow == 1) 
				&& !isNaN(getResult("Length", sortArray[j])) 
				&& getResult("Length", sortArray[j]) != 0){

				
				open(openListDir[w]+openList[w]);
				selectWindow(openList[w]);
				getPixelSize(unit, pixelWidth, pixelHeight);
				getDimensions(width, height, channels, slices, frames);
				
				xArray = Array.getSequence(round(finalLength/pixelWidth));
				for (i = 0; i < xArray.length; i++) {
					xArray[i] = xArray[i]*(finalLength/xArray.length);
				}
							
				RoiForCW = WSaveEnd[w] - WSaveStart[w];

				//pulling out info relevant to profiles for this ROI
				profile1 = newArray(0);
				profile2 = newArray(0);
				indexEnd1 = newArray(RoiForCW+1);
				
				for (ii = 0; ii < RoiForCW+1; ii++){
					indexEnd1[ii] = parseInt(fileMatrix[((ii + 1) * row1Length)+indexEnd1Column[w]]);
				}

				start = indexEnd1[sortArray[j]-WSaveStart[w]]+1;
				end = indexEnd1[sortArray[j]+1-WSaveStart[w]];
				counter = 0;
				for (ii = start; ii < end; ii++) {
					rowIndex = ((ii + 1) * row1Length);
					profile1[counter] = parseFloat(fileMatrix[rowIndex + profile1Column[w]]);
					profile2[counter] = parseFloat(fileMatrix[rowIndex + profile2Column[w]]);
					counter++;
				}
				//pulling out info relevant to profiles for this ROI^
				
				if (newWindow == 0){
					exceptionTrigger = 0;
					ogSquareSize = squareSize;
					squareSize = squareSize * 2;
					XCoord = (((getResult("X", sortArray[j]))/pixelWidth)-(squareSize/2)/pixelWidth);
					YCoord = (((getResult("Y", sortArray[j]))/pixelHeight)-(squareSize/2)/pixelHeight);
					canvasPosition = 0;
					if (XCoord < 0 && XCoord + squareSize/pixelWidth > width && YCoord < 0 && YCoord + squareSize/pixelHeight > height) canvasPosition = "Center";
					else if (XCoord < 0){
						canvasPosition = "Center-Right";
						if (YCoord < 0){
							canvasPosition = "Bottom-Right";
						}
						if (YCoord + squareSize/pixelHeight > height){
							canvasPosition = "Top-Right";
						}
					}
					else if (XCoord + squareSize/pixelWidth > width){
						canvasPosition = "Center-Left";	
						if (YCoord < 0){
							canvasPosition = "Bottom-Left";
						}
						if (YCoord + squareSize/pixelHeight > height){
							canvasPosition = "Top-Left";
						}	
					}
					else if (YCoord < 0){
						canvasPosition = "Bottom-Center";
					}
					else if (YCoord + squareSize/pixelHeight > height){
						canvasPosition = "Top-Center";
					}
					widthAdjustment = 0;
					heightAdjustment = 0;
					if (XCoord < 0){ 
						widthAdjustment = abs(XCoord);
						XCoord = 0;
					}
					if (YCoord < 0){
						heightAdjustment = abs(YCoord);
						YCoord = 0;
					}
					
					if ((XCoord - (squareSize/pixelWidth - widthAdjustment) == 0) || (YCoord - (squareSize/pixelHeight - heightAdjustment) == 0)) continue;				
					
					makeRectangle(XCoord, YCoord, squareSize/pixelWidth - widthAdjustment, squareSize/pixelHeight - heightAdjustment);
					
					run("Duplicate...", "duplicate channels=1-2");

					rename("Rotated 2 channel composite Image");
					temporaryRotatedImage = getTitle();
					run("Remove Slice Labels");
					if (canvasPosition != 0) run("Canvas Size...", "width=" + (squareSize/pixelWidth) + " height=" + (squareSize/pixelHeight) + " position=" + canvasPosition + " zero");
					
					squareSize = ogSquareSize;
					roiManager("select", sortArray[j]);
					getLine(x1, y1, x2, y2, lineWidth);
					angle = getAngle(x1, y1, x2, y2);
					angle = angle-90;
					run("Rotate... ", "angle="+angle+" grid=1 interpolation=None");
					rotateImageWidth = getWidth();
					rotateImageHeight = getHeight();

					setKeyDown("none");
					selectWindow(temporaryRotatedImage);
					run("Stack to RGB");
					temporaryRotatedImageRGB = getTitle();
					selectWindow(temporaryRotatedImageRGB);
					makeRectangle((rotateImageWidth/2)-((squareSize/pixelWidth)/2), (rotateImageHeight/2)-((squareSize/pixelHeight)/2), squareSize/pixelWidth, squareSize/pixelHeight);
					run("Copy");
					close(); //Close temporaryRotatedImageRGB
					
					if (!isOpen(titlet)) {
						newImage("ROI#"+currentROI+"/"+totalROIs+ " ||    ["+chosenNumberi[w]+"] chosen , ["+skippedNumberi[w]+"] skipped & ["+ excludedNumberi[w] +"] excluded               zoom:", "RGB", squareSize/pixelWidth, squareSize/pixelHeight, 1, 1, 1);
						titlet = getTitle();
						run("Select None");
						call("ij.gui.ImageWindow.setNextLocation", xWin, yWin);
						setBatchMode("show");
						run("Set... ", "zoom=0");
						run("Original Scale");
						run("Set... ", "zoom=" + zoom);
						run("Select None");
					}
					else {
						selectWindow(titlet);
						run("Select All");
						setBackgroundColor(0, 0, 0);
						run("Clear");
						if (getWidth() != (squareSize/pixelWidth) || getHeight() != (squareSize/pixelHeight)) run("Canvas Size...", "width=" + (squareSize/pixelWidth) + " height=" + (squareSize/pixelHeight) + " position=Center zero");
						rename("Local Contrast Square Width: [" + blocksizeChoice + "] pixels  ||  Synapse View Square Width: [" + squareSize + "]" + getInfo("micrometer.abbreviation") + "                   zoom:");
						titlet = getTitle();
						run("Set... ", "zoom=" + zoom);
					}
					
					selectWindow(titlet);
					run("Paste");

					roiManager("select", sortArray[j]);
					currentRoiColor = Roi.getStrokeColor;
					currentRoiName = Roi.getName;
					if (viewVertical == 1) angle = angle + 90;
					run("Rotate...", "  angle="+angle);
					roiManager("add");
					roiManager("select", RoiC);
					if (viewVertical == 1) {
						getLine(x1, y1, x2, y2, lineWidth);
						lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
						F = ((finalLength - (lineLength))/2);
						F = (F/(lineLength));
						makeLine((x1+F*(x1-x2)), (y1+F*(y1-y2)), (x2+F*(x2-x1)), (y2+F*(y2-y1)), round(finalWidth / pixelWidth));
						roiManager("update");
						if (currentRoiColor != "#80ff0000" && currentRoiColor != "#4000ff00"){
							Roi.setStrokeColor("#30e2e2e2");
							roiManager("update");
						}
						else{
							Roi.setStrokeColor(currentRoiColor);
							roiManager("update");
						}
						roiManager("select", RoiC);
					}

					
					if (ctrlKey) ctrlString = "CTRL + ";
					else ctrlString = "";

					if (shiftKey) shiftString = "SHIFT + ";
					else shiftString = "";
					
					
					if (lastSortChoice == "Combination") dialogTitle = "Keep Synapse?  (" + j + "/" + RoiC + ") " + " (" + "Combination Score:" + passCount[sortArray[j]] + ") Last Input: " + ctrlString + shiftString + "Enter";
					else dialogTitle = "Keep Synapse?  (" + j + "/" + RoiC + ") " + " (" + getResultString(individualSortChoice, sortArray[j]) + ") Last Input: " + ctrlString + shiftString + "Enter";

					if (quickSelection == 0){
						Dialog.createNonBlocking(dialogTitle);
						
						Dialog.addChoice("Sort ROIs?", dialogSortChoices, lastSortChoice)
						Dialog.addToSameRow();
						Dialog.addChoice("", viewChoices, lastViewChoice);
						Dialog.addNumber("Selection Size", squareSize, 0, 3, getInfo("micrometer.abbreviation"));
	//					Dialog.addToSameRow();
	//					Dialog.addChoice("", CPL, dialogLocl);
						Dialog.addNumber("Local Contrasting:", blocksizeChoice, 0, 3, "pixels");
						Dialog.addToSameRow();
						Dialog.addChoice("", aExit, 0);
						Dialog.addNumber("Go to Condition:", C + 1, 0, 3, "/" + toString(saveDirectorySubfolders.length));
						Dialog.addNumber("Go to ROI#:", j + 1, 0, 3, "/" + toString(RoiC - nFilteredROIs));
						Dialog.addToSameRow();
						Dialog.addCheckbox("Perpendicular", viewVerticalLast);
	//					if (matches(currentRoiName, ".*EditAfter.*")){ 
	//						Dialog.addCheckbox("Edit ROI", 1);
	//						wasEditROI = 1;
	//					}
	//					else {
	//						Dialog.addCheckbox("Edit ROI", 0);
	//						wasEditROI = 0;
	//					}
						Dialog.setLocation(dialogX,dialogY);
					}

					Plot.create("Perpendicular Plot1", getInfo("micrometer.abbreviation"), "Gray Value");	
				
					Array.getStatistics(profile1, min, max, mean, stdDev);			
					Plot.add("line", xArray, profile1); 
					Plot.setColor("blue");
					Plot.add("separated bar", newArray(xArray[profile1.length/2], xArray[profile1.length/2]), newArray(min, max));
					Plot.setLimits(NaN, NaN, NaN, NaN);	
					Plot.show();
					plot1Title = getTitle();
					selectWindow(plot1Title);
					run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
					run("Select All");
					getSelectionBounds(x, y, plot1width, plot1height);


					Plot.create("Perpendicular Plot2", getInfo("micrometer.abbreviation"), "Gray Value");
					Array.getStatistics(profile2, min, max, mean, stdDev);
					//////////////
//					rollingAvgProfile = profile2;
//					for (i = 2; i < rollingAvgProfile.length - 2; i++) {
//						rollingAvgProfile[i] = (profile2[i-2] + profile2[i-1] + profile2[i] + profile2[i+1] + profile2[i+2]) / 5;
//					}
					//////////////
					Plot.add("line", xArray, profile2);
					Plot.setColor("red");
					Plot.add("separated bar", newArray(xArray[profile2.length/2], xArray[profile2.length/2]), newArray(min, max));
					Plot.setLimits(NaN, NaN, NaN, NaN);
					Plot.show();
					plot2Title = getTitle();
					selectWindow(plot2Title);
					run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
					run("Select All");
					getSelectionBounds(x, y, plot2width, plot2height);

					if (plot1width > plot2width) largestWidth = plot1width;
					else largestWidth = plot2width;
					if (plot1height > plot2height) largestHeight = plot1height;
					else largestHeight = plot2height;

					print("[ CTRL + Enter = Keep ] [ SHIFT + Enter = Delete ] \n[ Enter = Skip ] [ CTRL + SHIFT + Enter = Back ]");
					for (i = 2; i < sortChoices.length; i++) {
						print(sortChoicesDisplayNames[i] + ": " + abs(getResultString(sortChoices[i], sortArray[j])));
					}
					shuffledGroupList = Array.getSequence(chosenNumber.length);
////					shuffle(shuffledGroupList);
//					for (i = 0; i < chosenNumber.length; i++){
//						ii = shuffledGroupList[i];
//						if (ii == grouplist[w]) print("Group-> "+"["+chosenNumber[ii]+"] chosen && ["+skippedNumber[ii]+"] skipped");
//					}
					for (i = 0; i < chosenNumber.length; i++){
						ii = shuffledGroupList[i];
						if (ii != grouplist[w]) print("Group X ["+chosenNumber[ii]+"] chosen & ["+skippedNumber[ii]+"] skipped & ["+excludedNumber[ii]+"] excluded");
						else if (ii == grouplist[w]) print("Group-> "+"["+chosenNumber[ii]+"] chosen & ["+skippedNumber[ii]+"] skipped & ["+excludedNumber[ii]+"] excluded");
					}

					
					selectWindow(titlet);
					run("Select None");
					if (blocksize < 0 || blocksize > squareSize/pixelWidth) blocksize = 30;
					else blocksize = blocksizeChoice;
					histogram_bins = 256;
					maximum_slope = 3;
					mask = "*None*";
					fast = true;
					process_as_composite = true;
					if (blocksize > 0) run( "Enhance Local Contrast (CLAHE)", "blocksize=" + blocksize + " histogram=" + histogram_bins + " maximum=" + maximum_slope + " mask=" + mask + " fast_(less_accurate)" + " process_as_composite");

					selectWindow(temporaryRotatedImage);
					azWindowWidth = getWidth();
					azWindowTargetWidth = 1.5/pixelWidth;
					if (azWindowWidth > floor(azWindowTargetWidth)) {
						makeRectangle((azWindowWidth/2)-(azWindowTargetWidth/2), (azWindowWidth/2)-(azWindowTargetWidth/2), azWindowTargetWidth, azWindowTargetWidth);
					}
					else run("Select All");
						
					run("Duplicate...", "duplicate channels=1-2");
					initialazWindow = getTitle();
					
					
					run("Select All");
					run("Scale...", "x=- y=- width="+ plot2height +" height=- interpolation=None average create");
					azWindow = getTitle();
					getSelectionBounds(x, y, azWindowWidth, azWindowHeight);
					selectWindow(initialazWindow);
					close(); //Close initialazWindow
					selectWindow(temporaryRotatedImage);
					close(); //Close temporaryRotatedImage

					if (!isOpen(allLinescans)) {
						newImage("Linescans", "RGB", largestWidth + azWindowWidth, plot1height + plot2height, 1);
					}
					else {
						selectWindow(allLinescans);
						run("Select All");
						setBackgroundColor(0, 0, 0);
						run("Clear");
						if (getWidth() != largestWidth + azWindowWidth || getHeight() != plot1height + plot2height)
							run("Canvas Size...", "width=" + (largestWidth + azWindowWidth) + " height=" + (plot1height + plot2height) + " position=Center zero");
					}
					allLinescans = getTitle();

					
					
					selectWindow(plot1Title);
					run("Select All");
					run("Copy");
					close(); //Close plot1Title
					selectWindow(allLinescans);
					makeRectangle(0, 0, plot1width, plot1height);
					run("Paste");

					selectWindow(plot2Title);
					run("Select All");
					run("Copy");
					close(); //Close plot2Title
					selectWindow(allLinescans);
					makeRectangle(0, plot1height, plot2width, plot2height);
					run("Paste");

					selectWindow(azWindow);
					Stack.setChannel(2);
					run("Select All");
					run("Copy");
					selectWindow(allLinescans);
					makeRectangle(largestWidth, plot1height, azWindowWidth, azWindowHeight);
					run("Paste");

					selectWindow(azWindow);
					Stack.setChannel(1);
					run("Select All");
					run("Copy");
					close(); //Close azWindow
					selectWindow(allLinescans);
					makeRectangle(largestWidth, 0, azWindowWidth, azWindowHeight);
					run("Paste");
					run("Select None");

					call("ij.gui.ImageWindow.setNextLocation", xPlot1, yPlot1);
					setBatchMode("show");
					run("Select None");

					selectWindow(titlet);

					roiManager("Centered", "true");
					roiManager("select", RoiC);
					roiManager("Centered", "false");

					/////////////////////
//					if (!isOpen("selection buttons")) run("Action Bar","/plugins/ActionBar/selection_buttons.txt");
//					restoreKey();
					keyOpt = 0;
					ccl = 0;
					if (quickSelection == 0){
						Dialog.show();
						logString = getInfo("log");
						ccl = charCodeAt(logString, 0);
					}
					else {
						quickSelectionModeString = "   [E] = Exit Quick Selection Mode"
							+ "\n   -------------------------------------"
							
							+ "\n   [C] = Next Condition"
							+ "\n   -------------------------------------"
							+ "\n                 [W] = Keep\n   [A]=Back [S]=Delete [D]=Skip"
							+ "\n   -------------------------------------"
							+ "\n   Condition # [" + toString(C + 1) + "] / [" + toString(saveDirectorySubfolders.length) + "]"
							+ "\n   ROI # [" + toString(j + 1) + "] / [" + toString(RoiC - nFilteredROIs) + "]";
						setFont("SansSerif", 14, "antialiased");
						if (!isOpen(quickSelectionWindow)) {
							newImage("Quick Selection Mode", "8-bit", getStringWidth("   [E]=Exit Quick Selection Mode") + 12, (16 * 11) + 5, 1);
							quickSelectionWindow = getTitle();
						}
						else {
							setBackgroundColor(256, 256, 256);
							selectWindow(quickSelectionWindow);
							run("Select All");
							run("Clear");
						}
						selectWindow(quickSelectionWindow);
						run("Select None");
						makeText(quickSelectionModeString, 0, 5);
						setForegroundColor(0, 0, 0);
						run("Draw", "slice");
						run("Select None");
						call("ij.gui.ImageWindow.setNextLocation", dialogX,dialogY);
						setBatchMode("show");
						logString = getInfo("log");
						ccl = charCodeAt(logString, 0);
						while (ccl == 91){
							logString = getInfo("log");
							ccl = charCodeAt(logString, 0);
						}
					}

//					Back (1) = 66
//					Keep (4) = 75
//					Skip (3) = 83
//					Delete (2) = 68
//					Exit Quick Selection = 69
//					Condition+ = 67
					if (ccl == 66) keyOpt = 1;
					else if (ccl == 83) keyOpt = 3;
					else if (ccl == 68) keyOpt = 2;
					else if (ccl == 75) keyOpt = 4;
					else if (ccl == 69) keyOpt = 5;
					else if (ccl == 67) keyOpt = 6;
					else if (isKeyDown("shift")&& isKeyDown("control")) keyOpt = 1;
					else if (!isKeyDown("shift") && !isKeyDown("control")) keyOpt = 3;
					else if (isKeyDown("shift") && !isKeyDown("control")) keyOpt = 2;
					else if (!isKeyDown("shift") && isKeyDown("control")) keyOpt = 4;

					cacheKey();
					setKeyDown("none");

					
					/////////////////////
					if (isOpen(allLinescans)) { 
						selectWindow(allLinescans);
						getLocationAndSize(xPlot1, yPlot1, plotwidth, plotheight);
					}
					
					
					roiManager("select", RoiC);
					roiManager("delete");
					
					print("\\Clear");
					if (quickSelection == 0){
						sortChoice = Dialog.getChoice();
						viewChoice = Dialog.getChoice();
						squareSize = Dialog.getNumber();
						blocksizeChoice = round(Dialog.getNumber());
	//					dialogLoc = Dialog.getChoice();
						windowNumber = Dialog.getNumber() - 1;
						exitState = Dialog.getChoice();
						skipToRoi = Dialog.getNumber() - 1;
						viewVertical = Dialog.getCheckbox();
	//					editROI = Dialog.getCheckbox();
					}
					else {
						sortChoice = lastSortChoice;
						viewChoice = lastViewChoice;
						squareSize = squareSize;
	//					dialogLoc = Dialog.getChoice();
						windowNumber = C;
						exitState = "Continue";
						skipToRoi = j;
						blocksizeChoice = blocksizeChoice;
						viewVertical = viewVerticalLast;
	//					editROI = Dialog.getCheckbox();
					}
					
					if (exitState == "Quick Mode") {
						quickSelection = 1;
						j = j-1;
						exitState = "Continue";
					}
					

					if (sortChoice == "Individual" && lastSortChoice != "Individual") {
						Dialog.createNonBlocking("Sort by:")
						Dialog.addChoice("", individualSortChoices, 0);
						Dialog.show();
						individualSortChoice = Dialog.getChoice();
					}
					
					if (isOpen(titlet)) {
						selectWindow(titlet);
						getLocationAndSize(xWin, yWin, widthWin, heightWin);
						zoom = 100*(getZoom());
					}
					

					run("Select None");
					heightWin = 0;
//					if (dialogLoc == "Top Right") heightWin = 0;
//					else if (dialogLoc == "Middle Right") heightWin = heightWin/4;
//					else if (dialogLoc == "Bottom") widthWin = 0;
//					else if (dialogLoc == "Top"){
//					heightWin = -180;
//					widthWin = 0;
//					}
//					else if (dialogLoc == "Bottom Right") heightWin = heightWin-200;
					
					dialogX = xWin + widthWin;
					dialogY = yWin + heightWin;
					
					selectWindow(openList[w]);
				}

//				if (editROI == 1){
//					roiManager("select", sortArray[j]);
//					roiManager("rename", "EditAfter[H]");
//					roiManager("update");
//				}
//				else if (wasEditROI ==1){
//					roiManager("select", sortArray[j]);
//					roiManager("rename", "[H]");
//					roiManager("update");
//				}
				
				if (keyOpt == 1) exitState = "Back";
				if (keyOpt == 5) {
					quickSelection = 0;
					if (isOpen(quickSelectionWindow)) {
						selectWindow(quickSelectionWindow);
						close();
					}
					j = j - 1;
					continue;
				}
				if (keyOpt == 6) {
					windowNumber = windowNumber + 1;
				}
				if (exitState == "Exit and Save"){
					selectWindow(titlet);
					close();
					selectWindow(allLinescans);
					close();
					j = RoiC;
					continue;
				} 
				else if (viewVerticalLast != viewVertical || blocksize != blocksizeChoice || skipToRoi != j || sortChoice != lastSortChoice || newWindow == 1 || squareSize != lastSquareSize || dialogLoc != dialogLocl || windowNumber != C || exitState == "Back" || exitState == "Reset"){
					if (blocksize != blocksizeChoice) j = j-1;
					if (viewVerticalLast != viewVertical) {
						j = j-1;
						viewVerticalLast = viewVertical;
					}
					if (skipToRoi != j){
						exceptionTrigger = 1;
						j = skipToRoi -1;
					}
					if (skipToRoi == j && (squareSize != lastSquareSize || dialogLoc != dialogLocl)){
						j = j-1;
						if (squareSize != lastSquareSize) lastSquareSize = squareSize;
						if (dialogLoc != dialogLocl) dialogLocl = dialogLoc;
					}
					if (exitState == "Back") j = lastRoiSelection - 1;

					if (exitState == "Reset"){
						for (ii = 0; ii < RoiC; ii++) {
							roiManager("select", ii);
							Roi.setStrokeColor(roiDefaultColor);
							roiManager("update");
						}
					    for (ww = 0; ww < openList.length; ww++) {
					    	if (grouplist[ww] == C){
								if (File.exists(pathPass[ww] + "ROIs.zip")){
									deletesuccess = File.delete(pathPass[ww] + "ROIs.zip");
									roiIndexes = Array.slice(roiSaveIndexes,WSaveStart[ww],WSaveEnd[ww]);
									roiManager("select", roiIndexes);
									roiManager("save selected", pathPass[ww] + "ROIs.zip");

									chosenNumber[grouplist[ww]] = (chosenNumber[grouplist[ww]]) - chosenNumberi[ww];
									chosenNumberi[ww] = 0;
									skippedNumber[grouplist[ww]] = (skippedNumber[grouplist[ww]]) - skippedNumberi[ww];
									skippedNumberi[ww] = 0;
									excludedNumber[grouplist[ww]] = (excludedNumber[grouplist[ww]]) - excludedNumberi[ww];
									excludedNumberi[ww] = 0;
								}
					    	}
					    }
					    j = -1;
					    newWindow = 0;
					    continue;
					}

					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					if (sortChoice != lastSortChoice || newWindow == 1){
						if (sortChoice == "Combination" && newWindow == 0){
							selectWindow(titlet);
							close();
							selectWindow(allLinescans);
							close();
											
							originalC = C;
							combinationPassedROIsIDs = newArray(openList.length);
							for (w = 0; w < openList.length; w++) combinationPassedROIsIDs[w] = "";
							combinationPassedROIs = newArray(openList.length);
							for (w = 0; w < openList.length; w++) combinationPassedROIs[w] = "";
							roiEdgeDistanceandDepthString = newArray(openList.length);
							for (w = 0; w < openList.length; w++) roiEdgeDistanceandDepthString[w] = "";

							iterations = 5;
							aggressiveness = 50;
							peakGoal = 5;
							meanGoal = 7.5;
							autoCombinationCountMax = NaN;
							autoCombinationCount = NaN;
							lastPeakVCdeltaValue = NaN;
							lastPeakAZdeltaValue = NaN;
							lastMeanVCdeltaValue = NaN;
							lastMeanAZdeltaValue = NaN;
							matchNumbertoPrint = newArray(saveDirectorySubfolders.length);
							
							for (C = 0; C < saveDirectorySubfolders.length; C++) {
								//Pulling out and formatting information regarding each condition, as is usually done at the beginning of the script:
								if (!File.exists(saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator)) File.makeDirectory(saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator);
								combinedFolder = saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator;
								WSaveStart = newArray(openList.length);
								WSaveEnd = newArray(openList.length);
								countForRois = 0;
								windowIdentifier = newArray(RoiC);
								roiManager("reset");
							    for (w = 0; w < openList.length; w++) {
							    	if (grouplist[w] == C){
										if (File.exists(pathPass[w] + "ROIs.zip")){
											WSaveStart[w] = roiManager("count");
											roiManager("open", pathPass[w] + "ROIs.zip");
											WSaveEnd[w] = roiManager("count");
										}
										for (ii = 0; ii < (WSaveEnd[w] - WSaveStart[w]); ii++) {
											windowIdentifier[countForRois] = w;
											countForRois++;
										}
							    	}
							    }
							    RoiC = roiManager("count");
							    roiSaveIndexes = Array.getSequence(RoiC);


								run("Clear Results");
								run("Results... ", "open=[" + combinedFolder +"Combined_info" + toString(C) + "_" + repNumber + ".csv]");
								/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
								if(C == 0 && !isNaN(autoCombinationCount)) {
									if ((lastPeakVCdeltaValue <= peakGoal) && (lastPeakAZdeltaValue <= peakGoal) && (lastMeanVCdeltaValue <= meanGoal)  && (lastMeanAZdeltaValue <= meanGoal)) {
										autoCombinationCount = NaN;
										autoCombinationCountMax = NaN;
									}
								}
								
								if(C == 0 && (autoCombinationCount >= autoCombinationCountMax || isNaN(autoCombinationCount))){
									explorer = NaN;
									checkBoxArray = newArray(sortChoices.length-2);
									weightValueP = newArray(sortChoices.length-2);
									weightValueN = newArray(sortChoices.length-2);
									minFilterVal = newArray(sortChoices.length-2);
									maxFilterVal = newArray(sortChoices.length-2);
									exploreOption = newArray(sortChoices.length-2);
									
									Dialog.create("Combination Options");
									c = 0;

									if (isNaN(lastChoiceSettings[c])) Dialog.addCheckbox(sortChoicesDisplayNames[2], 1);
									else Dialog.addCheckbox(sortChoicesDisplayNames[2], lastChoiceSettings[c]);
									c++;
									Dialog.addToSameRow();
									Dialog.addNumber("Min cut-off", lastChoiceSettings[c++], 6, 9, sortChoicesUnits[2]);
									Dialog.addToSameRow();
									Dialog.addNumber("Max cut-off", lastChoiceSettings[c++], 6, 9, sortChoicesUnits[2]);
									Dialog.addToSameRow();
									Dialog.addNumber("+weight", lastChoiceSettings[c++], 1, 3, "%");
									Dialog.addToSameRow();
									Dialog.addNumber("-weight", lastChoiceSettings[c++], 1, 3, "%");
									Dialog.addToSameRow();
									Dialog.addCheckbox("Explore Cut-offs", 0);

									for (i = 3; i < sortChoices.length; i++) {
										if (i%2 == 0) labelString = "-  -  -  -  -  -";
										else labelString = "~~~~~~~~";
										if (isNaN(lastChoiceSettings[c])) Dialog.addCheckbox(sortChoicesDisplayNames[i] + labelString, 1);
										else Dialog.addCheckbox(sortChoicesDisplayNames[i] + labelString, lastChoiceSettings[c]);
										c++;
										Dialog.addToSameRow();
										Dialog.addNumber(labelString, lastChoiceSettings[c++], 6, 9, sortChoicesUnits[i]);
										Dialog.addToSameRow();
										Dialog.addNumber(labelString, lastChoiceSettings[c++], 6, 9, sortChoicesUnits[i]);
										Dialog.addToSameRow();
										Dialog.addNumber(labelString, lastChoiceSettings[c++], 1, 3, "%");
										Dialog.addToSameRow();
										Dialog.addNumber(labelString, lastChoiceSettings[c++], 1, 3, "%");
										Dialog.addToSameRow();
										Dialog.addCheckbox(labelString, 0);
									}
									Dialog.setInsets(20, 20, 0);
									Dialog.addCheckbox("Blinded from Green Channel", 1);
									Dialog.addToSameRow();
									Dialog.addNumber("Filter lowest ", lastChoiceSettings[c++], 0, 4 ,"% TG");
									Dialog.addToSameRow();
									Dialog.addNumber("Filter highest ", lastChoiceSettings[c++], 0, 4 ,"% TG");
									Dialog.addNumber("Show average for first ", lastChoiceSettings[c++], 0, 4 ," synapses");
									Dialog.addNumber("Min # of synapses  ", lastChoiceSettings[c++], 0, 4 ,"");
									Dialog.addNumber("Auto-Setting (AI) iterations limit: ", NaN, 0, 4 ,"");
									Dialog.addToSameRow();
									Dialog.addNumber("EQ Peak "+ fromCharCode(916) +" Goal: ", peakGoal, 5, 8 ,"%");
									Dialog.addToSameRow();
									Dialog.addNumber("EQ Mean "+ fromCharCode(916) +" Goal: ", meanGoal, 5, 8 ,"%");
									Dialog.addToSameRow();
									Dialog.addNumber("EQ Aggressiveness: ", aggressiveness, 5, 8 ,"%");
									
									Dialog.show();
									c = 0;
									nExcludedSortChoices = 0;
									for (i = 0; i < sortChoices.length-2; i++){
										checkBoxArray[i] = Dialog.getCheckbox();
										lastChoiceSettings[c++] = checkBoxArray[i];
										if (checkBoxArray[i] == 0) nExcludedSortChoices++;
										minFilterVal[i] = Dialog.getNumber;
										lastChoiceSettings[c++] = minFilterVal[i];
										maxFilterVal[i] = Dialog.getNumber;
										lastChoiceSettings[c++] = maxFilterVal[i];
										weightValueP[i] = abs((Dialog.getNumber())/100);
										if (isNaN(weightValueP[i])) weightValueP[i] = 0;
										lastChoiceSettings[c++] = weightValueP[i] * 100;
										weightValueN[i] = abs((Dialog.getNumber())/100);
										if (isNaN(weightValueN[i])) weightValueN[i] = 0;
										lastChoiceSettings[c++] = weightValueN[i] * 100;
										exploreOption[i] = Dialog.getCheckbox();
										if (exploreOption[i] == 1) explorer = i;
									}
									blinded = Dialog.getCheckbox();
									lowPercent = Dialog.getNumber();
									lastChoiceSettings[c++] = lowPercent;
									highPercent = Dialog.getNumber();
									lastChoiceSettings[c++] = highPercent;
									highPercent = 100 - highPercent;
									customNumberToPlot = Dialog.getNumber();
									lastChoiceSettings[c++] = customNumberToPlot;
									minimumSynapses = Dialog.getNumber();
									lastChoiceSettings[c++] = minimumSynapses;
									iterations = Dialog.getNumber();
									peakGoal = Dialog.getNumber();
									meanGoal = Dialog.getNumber();
									aggressiveness = Dialog.getNumber();
									if (aggressiveness <= 0) aggressiveness = 0.01;
									if (aggressiveness > 100) aggressiveness = 100;
									if (isNaN(aggressiveness)) aggressiveness = 50;
									if (blinded == 1) unblindedOption = 2;
									else unblindedOption = 3;

									if (isNaN(iterations)){
										autoCombinationCountMax = NaN;
										autoCombinationCount = NaN;
									}
									else {
										autoCombinationCountMax = iterations * (sortChoices.length-2);
										toDisplayMax = iterations * (sortChoices.length-2 - nExcludedSortChoices);
										autoCombinationCount = -1;
										toDisplayCount = 1;
										C = -1;
										continue;
									}
									
									explorerFilterValue = newArray(1);
									if (!isNaN(explorer)) {
										Dialog.create("Explorer Options (" + toString(sortChoicesDisplayNames[explorer + 2]) + ")");
										if (!isNaN(minFilterVal[explorer])) minDefault = minFilterVal[explorer];
										else minDefault = minFromCI[explorer + 2] - 0.1;
										if (!isNaN(maxFilterVal[explorer])) maxDefault = maxFilterVal[explorer];
										else maxDefault = maxFromCI[explorer + 2] + 0.1;
										Dialog.addNumber("Minimum",minDefault , 6, 9, sortChoicesUnits[explorer + 2]);
										Dialog.addNumber("Maximum",maxDefault, 6, 9, sortChoicesUnits[explorer + 2]);
										if (sortChoicesResolution[explorer + 2] > ((maxDefault - minDefault) / (aggressiveness*0.5))) stepSize = sortChoicesResolution[explorer + 2]; 
										else stepSize = (maxDefault - minDefault) / (aggressiveness*0.5);
										Dialog.addNumber("Step Size", stepSize , 6, 9, sortChoicesUnits[explorer + 2]);
										items = newArray("Smaller Values", "Larger Values");
										Dialog.addChoice("Preference:", items);
										Dialog.show();
										minExplore = Dialog.getNumber;
										maxExplore = Dialog.getNumber;
										stepSizeExplore = Dialog.getNumber;
										if (isNaN(minExplore)) minExplore = 0;
										if (isNaN(maxExplore)) maxExplore = 0;
										if (isNaN(stepSizeExplore) || stepSizeExplore == 0) {
											C = -1;
											continue;
										}
										directionality = Dialog.getChoice();

										if (directionality == "Larger Values") {
											directionality = 1;
											signName = ">=";
										}
										else {
											directionality = -1;
											signName = "<=";
										}
										exploreCount = 0;
										for (i = 0; i < 2; i++) {
											explorerFilterValue[exploreCount] = minExplore + (stepSizeExplore * exploreCount);
											if (explorerFilterValue[exploreCount] >= maxExplore) {
												explorerFilterValue[exploreCount] = maxExplore;
												i = 2;
											}
											else {
												i = 0;
												exploreCount++;
											}
										}
									}
								}
								else if (C == 0 && autoCombinationCount < autoCombinationCountMax){
									if (autoCombinationCount == -1) {
										items = newArray("Smaller Values", "Larger Values");
										explorer = 0;
										autoCombinationCount = 0;
										itemsIndex = 0;
										currentIteration = 1;
									}
									else if (itemsIndex == 0) {
										itemsIndex = 1;
									}
									else {
										itemsIndex = 0;
										explorer++;
										autoCombinationCount++;
									}

									
									
									if (explorer == sortChoices.length-2) {
										explorer = 0;
										currentIteration++;
										aggressiveness = aggressiveness + ((100 - aggressiveness)/4);
									}
									directionality = items[itemsIndex];
									blinded = 1;
									unblindedOption = 2;
									
									

									weightValueP = newArray(sortChoices.length-2);
									weightValueN = newArray(sortChoices.length-2);
									minFilterVal = newArray(sortChoices.length-2);
									maxFilterVal = newArray(sortChoices.length-2);
									exploreOption = newArray(sortChoices.length-2);

									c = 0;
									for (i = 0; i < sortChoices.length-2; i++){
										c++;
										if (i == explorer) lCS_i = c;
										minFilterVal[i] = lastChoiceSettings[c++];
										maxFilterVal[i] = lastChoiceSettings[c++];
										weightValueP[i] = 0;
										c++;
										weightValueN[i] = 0;
										c++;
									}
									customNumberToPlot = NaN;
 
									
									
									explorerFilterValue = newArray(1);

									if (!isNaN(minFilterVal[explorer])) minDefault = abs(minFilterVal[explorer]);
									else minDefault = abs(minFromCI[explorer + 2]);
									if (!isNaN(maxFilterVal[explorer])) maxDefault = abs(maxFilterVal[explorer]);
									else maxDefault =abs(maxFromCI[explorer + 2]);
									minExplore = minDefault;
									maxExplore = maxDefault;
									
									stepSizeExplore = (maxDefault - minDefault) / (aggressiveness*0.5);
									if (isNaN(minExplore)) minExplore = 0;
									if (isNaN(maxExplore)) maxExplore = 0;
									if (isNaN(stepSizeExplore) || stepSizeExplore == 0) {
										if (itemsIndex == 0) print("\\Update1:[" + toString(toDisplayCount++) + "/" + toString(toDisplayMax) + "] " + toString(sortChoicesDisplayNames[explorer + 2]));
										C = -1;
										continue;
									}
									else if (sortChoicesResolution[explorer + 2] > stepSizeExplore) stepSizeExplore = sortChoicesResolution[explorer + 2];

									if (directionality == "Larger Values") {
										directionality = 1;
										signName = ">=";
									}
									else {
										directionality = -1;
										signName = "<=";
									}
									exploreCount = 0;
									for (i = 0; i < 2; i++) {
										explorerFilterValue[exploreCount] = minExplore + (stepSizeExplore * exploreCount);
										if (explorerFilterValue[exploreCount] >= maxExplore) {
											explorerFilterValue[exploreCount] = maxExplore;
											i = 2;
										}
										else {
											i = 0;
											exploreCount++;
										}
									}
								}

								if (checkBoxArray[explorer] == 0 && !isNaN(explorer)) {
									C = -1;
									continue;
								}
									
								if (C == 0) {
									runCount = -1;
									totalProfile1str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									totalProfile2str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									if (unblindedOption == 3) totalProfile3str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									totalProfileStdDev1str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									totalProfileStdDev2str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									if (unblindedOption == 3) totalProfileStdDev3str = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									numberOfMatches = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									max1 = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									max2 = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
									if (unblindedOption == 3) max3 = newArray(explorerFilterValue.length * saveDirectorySubfolders.length);
								}

								
								if (autoCombinationCount <= autoCombinationCountMax) {
									if (C == 0 && itemsIndex == 0) print("\\Update1:[" + toString(toDisplayCount++) + "/" + toString(toDisplayMax) + "] " + toString(sortChoicesDisplayNames[explorer + 2]));
									print("\\Update2:[" + signName + "]");
									print("\\Update3:Aggressiveness = " + toString(aggressiveness) + "%");
									print("\\Update5:Peak VCM "+ fromCharCode(916) +" = " + toString(lastPeakVCdeltaValue) + "%");
									print("\\Update6:Peak AZM "+ fromCharCode(916) +" = "+ toString(lastPeakAZdeltaValue) + "%");
									print("\\Update8:Mean VCM "+ fromCharCode(916) +" = " + toString(lastMeanVCdeltaValue) + "%");
									print("\\Update9:Mean AZM "+ fromCharCode(916) +" = " + toString(lastMeanAZdeltaValue) + "%");
								}
							
								for (pV = 0; pV < explorerFilterValue.length; pV++) {
									runCount++;
									if (!isNaN(explorer)) print("\\Update0:[" + toString(runCount) + "/" + toString(explorerFilterValue.length * saveDirectorySubfolders.length) + "]");
									
									nFilteredROIs = 0;
									if (isNaN(explorer) && C == 0 && pV == 0) print("# of ROIs per condition matching criteria:");
									if (isNaN(explorer)) {
										//RoiC = mean +1 SD +2 Min +3 Max
										cutOff = newArray(sortChoices.length - 2);
										lowerCutOff = newArray(sortChoices.length - 2);
										secondCutOff = newArray(sortChoices.length - 2);
										for (i = 0; i < sortChoices.length-2; i++){
											if (checkBoxArray[i] == 1){
												tempArray = newArray(RoiC);
												tempArrayHigh = newArray(RoiC);
												tempArrayLow = newArray(RoiC);
												for (ii = 0; ii < RoiC; ii++) tempArray[ii] = getResult(sortChoices[i+2], ii);
												tempArray = Array.sort(tempArray);
												tempArrayHigh = Array.slice(tempArray,round(0.75*tempArray.length)-1,round(0.75*tempArray.length));
												tempArraySecond = Array.slice(tempArray,round(0.50*tempArray.length)-1,round(0.50*tempArray.length));
												tempArrayLow = Array.slice(tempArray,round(0.25*tempArray.length)-1,round(0.25*tempArray.length));
												cutOff[i] = tempArrayHigh[0];
												secondCutOff[i] = tempArraySecond[0];
												lowerCutOff[i] = tempArrayLow[0];
											}
										}
									}
									
									passCount = newArray(RoiC);
									sortArray = newArray(RoiC);
									singleFilteredROI = newArray(RoiC);

									//If the ROI is red, prefilter it
									deletedROIsArray = split(deletedROIsString[C], "|");
									for (ii = 0; ii < RoiC; ii++){
										if (deletedROIsArray[ii] == "1") {
											passCount[ii] = passCount[ii] - 10000;
											singleFilteredROI[ii] = 1;
										}
									}

									//Use previously determined ranking of Target signal per condition to remove outliers according to user input
									sortArrayTargetMax = split(sortArrayTargetMaxString[C], "|");
									
									//First for the lower X percent
									if (!isNaN(lowPercent)) {
										for (ii = 0; ii < round(sortArrayTargetMax.length * (lowPercent / 100)); ii++){
											thisROI = parseInt(sortArrayTargetMax[ii]);
											passCount[thisROI] = passCount[thisROI] - 10000;
											singleFilteredROI[thisROI] = 1;
										}
									}
									//Then for the higher X percent
									if (!isNaN(highPercent)) {
										for (ii = round(sortArrayTargetMax.length * (highPercent / 100)); ii < sortArrayTargetMax.length; ii++){
											thisROI = parseInt(sortArrayTargetMax[ii]);
											passCount[thisROI] = passCount[thisROI] - 10000;
											singleFilteredROI[thisROI] = 1;
										}
									}

									
									for (i = 0; i < sortChoices.length-2; i++) {
										if (i == explorer) {
											for (ii = 0; ii < RoiC; ii++){
												resultTemp = getResult(sortChoices[i+2], ii);

												if (abs(resultTemp) < abs(minDefault) || abs(resultTemp) > abs(maxDefault)) {
													passCount[ii] = passCount[ii] - 10000;
													singleFilteredROI[ii] = 1;
												}
												else if (directionality * abs(resultTemp) < directionality * abs(explorerFilterValue[pV])) {
													passCount[ii] = passCount[ii] - 10000;
													singleFilteredROI[ii] = 1;
												}
											}
										}
										else if (checkBoxArray[i] == 1) {
											if (weightValueP[i] > 0 || weightValueN[i] > 0) fineSorting = 1;
											else fineSorting = 0;
											if (!isNaN(minFilterVal[i]) || !isNaN(maxFilterVal[i])) filtering = 1;
											else filtering = 0;
											if (filtering + fineSorting == 0) continue;
											
											for (ii = 0; ii < RoiC; ii++){
												if (singleFilteredROI[ii] != 1){
													resultTemp = getResult(sortChoices[i+2], ii);
													
													if (isNaN(explorer)) {
														if (fineSorting == 1){
															if (resultTemp >= cutOff[i]) passCount[ii] = passCount[ii] + 1*weightValueP[i];
															else if (resultTemp >= secondCutOff[i]) passCount[ii] = passCount[ii] + 0.5*weightValueP[i];
															else if (resultTemp >= lowerCutOff[i]) passCount[ii] = passCount[ii] - 0.5*weightValueN[i];
															else if (resultTemp <= lowerCutOff[i]) passCount[ii] = passCount[ii] - 1*weightValueN[i];
														}
													}
													
													if (filtering == 1){
														if (abs(resultTemp) < abs(minFilterVal[i]) || abs(resultTemp) > abs(maxFilterVal[i])) {
															passCount[ii] = passCount[ii] - 10000;
															singleFilteredROI[ii] = 1;
														}
													}
												}
											}
										}
									}
									
									if (isNaN(explorer)) {
										ROIwidthArray = split(ROIwidthString[C], "|");
										for (i = 0; i < RoiC; i++) {
											w = windowIdentifier[i];
											if (singleFilteredROI[i] == 1) {
												nFilteredROIs++;
												combinationPassedROIs[w] = combinationPassedROIs[w] + "0|";
												combinationPassedROIsIDs[w] = combinationPassedROIsIDs[w] + toString(i) + "|";
												roiEdgeDistanceandDepthString[w] = roiEdgeDistanceandDepthString[w] + "NA*";
											}
											else {
												combinationPassedROIs[w] = combinationPassedROIs[w] + "1|";
												combinationPassedROIsIDs[w] = combinationPassedROIsIDs[w] + toString(i) + "|";
//												if (getResult("overlap") == 0) tempString = toString(abs(getResult("distanceFromEdge", i))) + "|" + getResultString("VCdepth", i) + "*";
//												else tempString = "-" + toString(abs(getResult("distanceFromEdge", i))) + "|" + getResultString("VCdepth", i) + "*";
								
												tempString = toString(getResult("distanceFromCenter", i)) + "|" + ROIwidthArray[i] + "|" + getResultString("VCdepth", i) + "*";
												roiEdgeDistanceandDepthString[w] = roiEdgeDistanceandDepthString[w] + tempString;
											}
										}
									}
									else {
										for (i = 0; i < RoiC; i++) if (singleFilteredROI[i] == 1) nFilteredROIs++;
									}
									
									sortArray = Array.rankPositions(passCount);
									sortArray = Array.reverse(sortArray);
									lastSortChoice = sortChoice;
									j = -1;
	

									if (!isNaN(customNumberToPlot) && customNumberToPlot > 0 && customNumberToPlot < (RoiC - nFilteredROIs)) {
										for (w = 0; w < openList.length; w++) {
											if (grouplist[w] == C){
												combinationPass = split(combinationPassedROIs[w], "|");
												combinationID = split(combinationPassedROIsIDs[w], "|");
												for (jj = 0; jj < RoiC; jj++) {
													if (jj < customNumberToPlot) string = "1";
													else string = "0";
													
													for (i = 0; i < combinationPass.length; i++) {
														if (combinationID[i] == toString(sortArray[jj])) combinationPass[i] = string;
													}
												}
												combinationPassedROIs[w] = "";
												for (i = 0; i < combinationPass.length; i++) combinationPassedROIs[w] = combinationPassedROIs[w] + combinationPass[i] + "|";
											}
										}

										nFilteredROIs = (RoiC - customNumberToPlot);
									}
									
									loopEnd = (RoiC - nFilteredROIs);


									
									for (jj = 0; jj < loopEnd; jj++) {
										w = windowIdentifier[sortArray[jj]];
										currentROI = currentROIfloor[w] + sortArray[jj];
										RoiForCW = WSaveEnd[w] - WSaveStart[w];
	
										
										profile1 = newArray(0);
										profile2 = newArray(0);
										if (unblindedOption == 3) profile3 = newArray(0);
										indexEnd1 = newArray(RoiForCW+1);

										
										for (ii = 0; ii < RoiForCW+1; ii++){
											indexEnd1[ii] = parseInt(fileMatrix[((ii + 1) * row1Length)+indexEnd1Column[w]]);
										}
										
	
										start = indexEnd1[sortArray[jj]-WSaveStart[w]]+1;
										end = indexEnd1[sortArray[jj]+1-WSaveStart[w]];
										counter = 0;
										for (ii = start; ii < end; ii++) {
											rowIndex = ((ii + 1) * row1Length);
											profile1[counter] = fileMatrix[rowIndex + profile1Column[w]];
											profile2[counter] = fileMatrix[rowIndex + profile2Column[w]];
											if (unblindedOption == 3) profile3[counter] = fileMatrix[rowIndex + profile3Column[w]];
											counter++;
										}
										
										if (jj == 0){
											totalProfile1 = newArray(profile1.length + 10);
											totalProfile2 = newArray(profile2.length + 10);
											for (ii = 0; ii < totalProfile1.length; ii++) totalProfile1[ii] = "";
											for (ii = 0; ii < totalProfile2.length; ii++) totalProfile2[ii] = "";
											if (unblindedOption == 3) {
												totalProfile3 = newArray(profile3.length + 10);
												for (ii = 0; ii < totalProfile3.length; ii++) totalProfile3[ii] = "";
											}
										}
										
										for (ii = 0; ii < profile1.length; ii++) totalProfile1[ii] = totalProfile1[ii] + profile1[ii] + ",";
										for (ii = 0; ii < profile2.length; ii++) totalProfile2[ii] = totalProfile2[ii] + profile2[ii] + ",";
										if (unblindedOption == 3) for (ii = 0; ii < profile3.length; ii++) totalProfile3[ii] = totalProfile3[ii] + profile3[ii] + ",";
									}
									totalProfileStdDev1 = newArray(xArray.length);
									totalProfileStdDev2 = newArray(xArray.length);
									totalProfile1neg = newArray(xArray.length);
									totalProfile1pos = newArray(xArray.length);
									totalProfile2neg = newArray(xArray.length);
									totalProfile2pos = newArray(xArray.length);
									if (unblindedOption == 3) {
										totalProfileStdDev3 = newArray(xArray.length);
										totalProfile3neg = newArray(xArray.length);
										totalProfile3pos = newArray(xArray.length);
									}
									
									if (RoiC - nFilteredROIs == 0){
										totalProfile1 = newArray(xArray.length);
										totalProfile2 = newArray(xArray.length);
										if (unblindedOption == 3) totalProfile3 = newArray(xArray.length);
									}
									else {
										for (ii = 0; ii < totalProfile1.length; ii++) if (totalProfile1[ii] == "") totalProfile1 = Array.deleteIndex(totalProfile1, ii);
										for (ii = 0; ii < totalProfile2.length; ii++) if (totalProfile2[ii] == "") totalProfile2 = Array.deleteIndex(totalProfile2, ii);
										if (unblindedOption == 3) for (ii = 0; ii < totalProfile3.length; ii++) if (totalProfile3[ii] == "") totalProfile3 = Array.deleteIndex(totalProfile3, ii);
										for (ii = 0; ii < totalProfile1.length; ii++) {
											temporaryTotalProfile = split(totalProfile1[ii], ",");
											for (iii = 0; iii < temporaryTotalProfile.length; iii++) temporaryTotalProfile[iii] = parseFloat(temporaryTotalProfile[iii]);
											temporaryTotalProfile = Array.deleteValue(temporaryTotalProfile, NaN);
											Array.getStatistics(temporaryTotalProfile, NA1, NA2, mean, stdDev);
											totalProfile1[ii] = mean;
											totalProfileStdDev1[ii] = stdDev;
										}
										for (ii = 0; ii < totalProfile2.length; ii++) {
											temporaryTotalProfile = split(totalProfile2[ii], ",");
											for (iii = 0; iii < temporaryTotalProfile.length; iii++) temporaryTotalProfile[iii] = parseFloat(temporaryTotalProfile[iii]);
											temporaryTotalProfile = Array.deleteValue(temporaryTotalProfile, NaN);
											Array.getStatistics(temporaryTotalProfile, NA1, NA2, mean, stdDev);
											totalProfile2[ii] = mean;
											totalProfileStdDev2[ii] = stdDev;
										}
										if (unblindedOption == 3) {
											for (ii = 0; ii < totalProfile3.length; ii++) {
												temporaryTotalProfile = split(totalProfile3[ii], ",");
												for (iii = 0; iii < temporaryTotalProfile.length; iii++) temporaryTotalProfile[iii] = parseFloat(temporaryTotalProfile[iii]);
												temporaryTotalProfile = Array.deleteValue(temporaryTotalProfile, NaN);
												Array.getStatistics(temporaryTotalProfile, NA1, NA2, mean, stdDev);
												totalProfile3[ii] = mean;
												totalProfileStdDev3[ii] = stdDev;
											}
										}
									}
									totalProfile1str[runCount] = toString(totalProfile1[0]);
									totalProfile2str[runCount] = toString(totalProfile2[0]);
									totalProfileStdDev1str[runCount] = toString(totalProfileStdDev1[0]);
									totalProfileStdDev2str[runCount] = toString(totalProfileStdDev2[0]);
									if (unblindedOption == 3) {
										totalProfile3str[runCount] = toString(totalProfile3[0]);
										totalProfileStdDev3str[runCount] = toString(totalProfileStdDev3[0]);
									}

									for (ii = 1; ii < totalProfile1.length; ii++) {
										totalProfile1str[runCount] = totalProfile1str[runCount] + "," + toString(totalProfile1[ii]);
										totalProfileStdDev1str[runCount] = totalProfileStdDev1str[runCount] + "," + toString(totalProfileStdDev1[ii]);
									}
									for (ii = 1; ii < totalProfile2.length; ii++) {
										totalProfile2str[runCount] = totalProfile2str[runCount] + "," + toString(totalProfile2[ii]);
										totalProfileStdDev2str[runCount] = totalProfileStdDev2str[runCount] + "," + toString(totalProfileStdDev2[ii]);
									}
									if (unblindedOption == 3) for (ii = 1; ii < totalProfile3.length; ii++) totalProfile3str[runCount] = totalProfile3str[runCount] + "," + toString(totalProfile3[ii]);
									if (unblindedOption == 3) for (ii = 1; ii < totalProfile3.length; ii++) totalProfileStdDev3str[runCount] = totalProfileStdDev3str[runCount] + "," + toString(totalProfileStdDev3[ii]);
									numberOfMatches[runCount] = RoiC - nFilteredROIs;
									Array.getStatistics(totalProfile1, min, max1[runCount]);
									Array.getStatistics(totalProfile2, min, max2[runCount]);
									if (unblindedOption == 3) Array.getStatistics(totalProfile3, min, max3[runCount]);
									
									if (isNaN(explorer)) print(toString(C + 1) + "/" + toString(saveDirectorySubfolders.length) + " -> " + toString(RoiC - nFilteredROIs) + " matches");
								}

								//Loop through saved totalprofiles and create plots
								if (C == saveDirectorySubfolders.length - 1){
									if (!isNaN(explorer) && isNaN(autoCombinationCount)) print("\\Update:[creating plots...]");
									totalRunCount = runCount + 1;
									plotTitles = newArray(saveDirectorySubfolders.length);
									currentC = -1;
									Array.getStatistics(max1, min, MAX1);
									Array.getStatistics(max2, min, MAX2);
									if (unblindedOption == 3) {
										Array.getStatistics(max3, min, MAX3);
										allMaxArray = newArray(MAX1, MAX2, MAX3);
									}
									else allMaxArray = newArray(MAX1, MAX2);
									
									Array.getStatistics(allMaxArray, min, allMax);

									if (isNaN(autoCombinationCount)){
										for (i = 0; i < totalRunCount; i++) {
											divisor = sqrt(numberOfMatches[i]);
											
											if (i == 0 || i % explorerFilterValue.length == 0) {
												newC = 1;
												currentC++;
												pV = 0;
											}
											else {
												newC = 0;
												pV++;
											}
											totalProfile1 = split(totalProfile1str[i], ",");
											totalProfileStdDev1 = split(totalProfileStdDev1str[i], ",");
											
											for (ii = 0; ii < totalProfileStdDev1.length; ii++) totalProfileStdDev1[ii] = parseFloat(totalProfileStdDev1[ii]) / divisor;
											for (ii = 0; ii < totalProfile1.length; ii++) {
												totalProfile1[ii] = parseFloat(totalProfile1[ii]);
												totalProfile1neg[ii] = totalProfile1[ii] - totalProfileStdDev1[ii];
												totalProfile1pos[ii] = totalProfile1[ii] + totalProfileStdDev1[ii];
											}	
											
											if (isNaN(explorer)) Plot.create("Plot", toString(numberOfMatches[i]) + " matches", "Gray Value");
											else Plot.create("Plot", toString(numberOfMatches[i]) + " matches", "Gray Value");
											Plot.setColor("gray");
											Plot.add("separated bar", newArray(xArray[round((finalLength*0.5)/pixelWidth)], xArray[round((finalLength*0.5)/pixelWidth)]), newArray(0, 255));
											Plot.setColor("#ddddff");
											Plot.setLineWidth(0.5);
											Plot.add("line", xArray, totalProfile1neg);
											Plot.add("line", xArray, totalProfile1pos);

											///////////////////////////////////////////////////////
											totalProfile2 = split(totalProfile2str[i], ",");
											totalProfileStdDev2 = split(totalProfileStdDev2str[i], ",");
											for (ii = 0; ii < totalProfileStdDev2.length; ii++) totalProfileStdDev2[ii] = parseFloat(totalProfileStdDev2[ii]) / divisor;
											for (ii = 0; ii < totalProfile2.length; ii++) {
												totalProfile2[ii] = parseFloat(totalProfile2[ii]);
												totalProfile2neg[ii] = totalProfile2[ii] - totalProfileStdDev2[ii];
												totalProfile2pos[ii] = totalProfile2[ii] + totalProfileStdDev2[ii];
											}
											Plot.setColor("#ffcccb");
											Plot.add("line", xArray, totalProfile2neg);	
											Plot.add("line", xArray, totalProfile2pos);	

											Plot.setColor("blue");
											Plot.setLineWidth(1);
											Plot.add("line", xArray, totalProfile1); 
											Plot.setColor("red");
											Plot.add("line", xArray, totalProfile2);
											///////////////////////////////////////////////////////
											if (unblindedOption == 3){
												totalProfile3 = split(totalProfile3str[i], ",");
												totalProfileStdDev3= split(totalProfileStdDev3str[i], ",");
												for (ii = 0; ii < totalProfileStdDev3.length; ii++) totalProfileStdDev3[ii] = parseFloat(totalProfileStdDev3[ii]) / divisor;
												for (ii = 0; ii < totalProfile3.length; ii++) {
													totalProfile3[ii] = parseFloat(totalProfile3[ii]);
													totalProfile3neg[ii] = totalProfile3[ii] - totalProfileStdDev3[ii];
													totalProfile3pos[ii] = totalProfile3[ii] + totalProfileStdDev3[ii];
												}
												Plot.setColor("green");
												Plot.setLineWidth(0.5);
												Plot.add("line", xArray, totalProfile3neg);
												Plot.add("line", xArray, totalProfile3pos);

												
												Plot.setColor("#90EE90");
												Plot.setLineWidth(1);
												Plot.add("line", xArray, totalProfile3); 
											}
											Plot.setLimits(NaN, NaN, 0, allMax * 1.15);
											Plot.show();
											
											plotTitle = getTitle();
											selectWindow(plotTitle);
											run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
											Plot.makeHighResolution(plotTitle + "| HiRes", 4.0);
											hiRes = getTitle();
											run("Select All");
											getSelectionBounds(x, y, plotwidth, plotheight);
											run("Copy");
											close(plotTitle);
											close(hiRes);
											if (newC == 1) {
												newImage(toString(sortChoicesDisplayNames[explorer + 2]) + " -- Compiled Plots for Condition #" + toString(currentC), "RGB", plotwidth, plotheight, 1);
												plotTitles[currentC] = getTitle();
											}
											selectWindow(plotTitles[currentC]);
											if (newC == 0){
												run("Add Slice");
											}
											run("Select All");
											run("Paste");
											run("Select None");
										}
									}


									totalMatchesAllConditions = newArray(explorerFilterValue.length);
									plotChannelsTitle = newArray(unblindedOption);
									deltaValue1 = newArray(explorerFilterValue.length);
									deltaValueAllPoints1 = newArray(explorerFilterValue.length);
									deltaValueAllPoints1 = Array.fill(deltaValueAllPoints1, 0);
									for (i = 0; i < explorerFilterValue.length; i++) {
										max = max1[i];
										min = max1[i];
										//Check max values for each condition and find smallest/largest values out of them
										for (currentC = 1; currentC < saveDirectorySubfolders.length; currentC++) {
											RC = i + (explorerFilterValue.length * currentC);
											totalMatchesAllConditions[i] = totalMatchesAllConditions[i] + numberOfMatches[RC];
											if (max1[RC] > max) max = max1[RC];
											else if (max1[RC] < min) min = max1[RC];
										}
										deltaValue1[i] = ((max - min) / max) * 100;
										
										for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
											RC = i + (explorerFilterValue.length * currentC);
		
											totalProfile1 = split(totalProfile1str[RC], ",");
											totalProfileStdDev1 = split(totalProfileStdDev1str[i], ",");
											for (ii = 0; ii < totalProfileStdDev1.length; ii++) totalProfileStdDev1[ii] = parseFloat(totalProfileStdDev1[ii]);
											if (currentC == 0) {
												maxSegment1 = newArray(totalProfile1.length);
												minSegment1 = newArray(totalProfile1.length);
												for (ii = 0; ii < totalProfile1.length; ii++) {
													totalProfile1[ii] = parseFloat(totalProfile1[ii]);
													maxSegment1[ii] = totalProfile1[ii];
													minSegment1[ii] = totalProfile1[ii];
												}
											}
											else {
												for (ii = 0; ii < maxSegment1.length; ii++) {
													totalProfile1[ii] = parseFloat(totalProfile1[ii]);
													if (totalProfile1[ii] > maxSegment1[ii]) maxSegment1[ii] = totalProfile1[ii];
													if (totalProfile1[ii] < minSegment1[ii]) minSegment1[ii] = totalProfile1[ii];
												}
											}
											
											if (isNaN(autoCombinationCount)){
												if (currentC == 0) {
													Plot.create("Plot", "", "");
													Plot.setColor("gray");
													Plot.add("separated bar", newArray(xArray[round((finalLength*0.5)/pixelWidth)], xArray[round((finalLength*0.5)/pixelWidth)]), newArray(0, 255));
												}
												
												Plot.setColor("blue");
												Plot.add("line", xArray, totalProfile1); 
											}
										}

										maxSegment1 = Array.deleteValue(maxSegment1, NaN);
										for (ii = 0; ii < maxSegment1.length - 2; ii++) {
											compareTo = ((maxSegment1[ii] - minSegment1[ii])/max) * 100;
											deltaValueAllPoints1[i] = deltaValueAllPoints1[i] + (compareTo / maxSegment1.length);
										}

										if (isNaN(autoCombinationCount)){
											if (isNaN(explorer)) Plot.setXYLabels(fromCharCode(916) + " " + toString(round(deltaValue1[i] * 10) / 10) + "% (peak); " + toString((round(deltaValueAllPoints1[i] * 10))/10) + "% (mean)", "Gray Value");
											else Plot.setXYLabels(signName  + " " +  toString(explorerFilterValue[i]) + ", " + fromCharCode(916) + " " + toString(round(deltaValue1[i] * 10) / 10) + "% (peak); " + toString((round(deltaValueAllPoints1[i] * 10))/10) + "% (mean)", "Gray Value");
	
											Plot.setLimits(NaN, NaN, 0, MAX1 * 1.05);
											Plot.show();
											
											plotTitle = getTitle();
											selectWindow(plotTitle);
											run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
											Plot.makeHighResolution(plotTitle + "| HiRes", 4.0);
											hiRes = getTitle();
											run("Select All");
											getSelectionBounds(x, y, plotwidth, plotheight);
											run("Copy");
											close(plotTitle);
											close(hiRes);
											if (i == 0) {
												newImage(toString(sortChoicesDisplayNames[explorer + 2]) + " -- Vesicle Cloud Plot", "RGB", plotwidth, plotheight, 1);
												plotChannelsTitle[0] = getTitle();
											}
											selectWindow(plotChannelsTitle[0]);
											if (i > 0) run("Add Slice");
											run("Select All");
											run("Paste");
											run("Select None");
										}
									}

									deltaValue2 = newArray(explorerFilterValue.length);
									deltaValueAllPoints2 = newArray(explorerFilterValue.length);
									deltaValueAllPoints2 = Array.fill(deltaValueAllPoints2, 0);
									for (i = 0; i < explorerFilterValue.length; i++) {
										max = max2[i];
										min = max2[i];
										for (currentC = 1; currentC < saveDirectorySubfolders.length; currentC++) {
											RC = i + (explorerFilterValue.length * currentC);
											if (max2[RC] > max) max = max2[RC];
											else if (max2[RC] < min) min = max2[RC];
										}
										deltaValue2[i] = ((max - min) / max) * 100;

										for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
											RC = i + (explorerFilterValue.length * currentC);
		
											totalProfile2 = split(totalProfile2str[RC], ",");
											totalProfileStdDev2 = split(totalProfileStdDev2str[i], ",");
											for (ii = 0; ii < totalProfileStdDev2.length; ii++) totalProfileStdDev2[ii] = parseFloat(totalProfileStdDev2[ii]);
											if (currentC == 0) {
												maxSegment2 = newArray(totalProfile2.length);
												minSegment2 = newArray(totalProfile2.length);
												for (ii = 0; ii < totalProfile2.length; ii++) {
													totalProfile2[ii] = parseFloat(totalProfile2[ii]);
													maxSegment2[ii] = totalProfile2[ii];
													minSegment2[ii] = totalProfile2[ii];
												}
											}
											else {
												for (ii = 0; ii < maxSegment2.length; ii++) {
													totalProfile2[ii] = parseFloat(totalProfile2[ii]);
													if (totalProfile2[ii] > maxSegment2[ii]) maxSegment2[ii] = totalProfile2[ii];
													if (totalProfile2[ii] < minSegment2[ii]) minSegment2[ii] = totalProfile2[ii];
												}
											}

											if (isNaN(autoCombinationCount)){
												if (currentC == 0) {
													Plot.create("Plot", "", "Gray Value");
													Plot.setColor("black");
													Plot.add("separated bar", newArray(xArray[round((finalLength*0.5)/pixelWidth)], xArray[round((finalLength*0.5)/pixelWidth)]), newArray(0, 255));
												}
												
												Plot.setColor("red");
												Plot.add("line", xArray, totalProfile2); 
											}
										}

										maxSegment2 = Array.deleteValue(maxSegment2, NaN);
										for (ii = 0; ii < maxSegment2.length; ii++) {
											compareTo = ((maxSegment2[ii] - minSegment2[ii])/max) * 100;
											deltaValueAllPoints2[i] = deltaValueAllPoints2[i] + (compareTo / maxSegment2.length);
										}
										
										if (isNaN(autoCombinationCount)){
											if (isNaN(explorer)) Plot.setXYLabels(fromCharCode(916) + " " + toString(round(deltaValue2[i] * 10) / 10) + "% (peak); " + toString((round(deltaValueAllPoints2[i] * 10))/10) + "% (mean)", "Gray Value");
											else Plot.setXYLabels(signName  + " " +  toString(explorerFilterValue[i]) + ", " + fromCharCode(916) + " " + toString(round(deltaValue2[i] * 10) / 10) + "% (peak); " + toString((round(deltaValueAllPoints2[i] * 10))/10) + "% (mean)", "Gray Value");
													
											Plot.setLimits(NaN, NaN, 0, MAX2 * 1.05);
											Plot.show();
											
											plotTitle = getTitle();
											selectWindow(plotTitle);
											run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
											Plot.makeHighResolution(plotTitle + "| HiRes", 4.0);
											hiRes = getTitle();
											run("Select All");
											getSelectionBounds(x, y, plotwidth, plotheight);
											run("Copy");
											close(plotTitle);
											close(hiRes);
											if (i == 0) {
												newImage(toString(sortChoicesDisplayNames[explorer + 2]) + " -- AZ|PS Bar Plot", "RGB", plotwidth, plotheight, 1);
												plotChannelsTitle[1] = getTitle();
											}
											selectWindow(plotChannelsTitle[1]);
											if (i > 0) run("Add Slice");
											run("Select All");
											run("Paste");
											run("Select None");
										}
									}

									if (unblindedOption == 3 && isNaN(autoCombinationCount)) {
										deltaValue3 = newArray(explorerFilterValue.length);
										for (i = 0; i < explorerFilterValue.length; i++) {
											max = max3[i];
											min = max3[i];
											for (currentC = 1; currentC < saveDirectorySubfolders.length; currentC++) {
												RC = i + (explorerFilterValue.length * currentC);
												if (max3[RC] > max) max = max3[RC];
												else if (max3[RC] < min) min = max3[RC];
											}
											deltaValue3[i] = ((max - min) / max) * 100;
											for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
												RC = i + (explorerFilterValue.length * currentC);
			
												totalProfile3 = split(totalProfile3str[RC], ",");
												totalProfileStdDev3 = split(totalProfileStdDev3str[i], ",");
												for (ii = 0; ii < totalProfile3.length; ii++) totalProfile3[ii] = parseFloat(totalProfile3[ii]);
												for (ii = 0; ii < totalProfileStdDev3.length; ii++) totalProfileStdDev3[ii] = parseFloat(totalProfileStdDev3[ii]);
												
												if (currentC == 0) {
													if (isNaN(explorer)) Plot.create("Plot", fromCharCode(916) + toString(round((max - min) * 100) / 100) + " (" + toString((round(deltaValue3[i] * 10))/10) + "%)", "Gray Value");
													else Plot.create("Plot", signName + " " + toString(explorerFilterValue[i]) + ", " + fromCharCode(916) + toString(round((max - min) * 100) / 100) + " (" + toString((round(deltaValue3[i] * 10))/10) + "%)", "Gray Value");
													Plot.setColor("black");
													Plot.add("separated bar", newArray(xArray[round((finalLength*0.5)/pixelWidth)], xArray[round((finalLength*0.5)/pixelWidth)]), newArray(0, 255));
												}
												
												Plot.setColor("green");
												Plot.add("line", xArray, totalProfile3); 
											}
	
											Plot.setLimits(NaN, NaN, 0, MAX3 * 1.05);
											Plot.show();
											
											plotTitle = getTitle();
											selectWindow(plotTitle);
											run("Plots...", "width=1 height=1 font=12 draw minimum=0 maximum=0 interpolate");
											Plot.makeHighResolution(plotTitle + "| HiRes", 4.0);
											hiRes = getTitle();
											run("Select All");
											getSelectionBounds(x, y, plotwidth, plotheight);
											run("Copy");
											close(plotTitle);
											close(hiRes);
											if (i == 0) {
												newImage(toString(sortChoicesDisplayNames[explorer + 2]) + " -- Target Plot", "RGB", plotwidth, plotheight, 1);
												plotChannelsTitle[2] = getTitle();
											}
											selectWindow(plotChannelsTitle[2]);
											if (i > 0) run("Add Slice");
											run("Select All");
											run("Paste");
											run("Select None");
										}
									}
									
									bestrewardCostRatio = (100 - aggressiveness) / 100;
//									bestrewardCostRatio = 0.2;
									rewardCostRatio = newArray(explorerFilterValue.length);
									reward = newArray(explorerFilterValue.length);
									cost = newArray(explorerFilterValue.length);
									
									if (!isNaN(explorer)) {
										peakVCdelt = 0;
										peakAZdelt = 0;
										meanVCdelt = 0;
										meanAZdelt = 0;

										if (!isNaN(autoCombinationCount)){
											if (toDisplayCount == 2) startMatchesNumber = newArray(saveDirectorySubfolders.length);
										}
										else startMatchesNumber = newArray(saveDirectorySubfolders.length);
										
										if (directionality == 1){
											minimumDelta = 0;
											for (i = 0; i < explorerFilterValue.length; i++) {
												peakVCdelt = calculateIndividualDeltaVals(peakGoal, deltaValue1[0], deltaValue1[i]);
												peakAZdelt = calculateIndividualDeltaVals(peakGoal, deltaValue2[0], deltaValue2[i]);
												meanVCdelt = calculateIndividualDeltaVals(meanGoal, deltaValueAllPoints1[0], deltaValueAllPoints1[i]);
												meanAZdelt = calculateIndividualDeltaVals(meanGoal, deltaValueAllPoints2[0], deltaValueAllPoints2[i]);
										
												reward[i] = peakVCdelt + peakAZdelt + meanVCdelt + meanAZdelt;
												totalCost = 0;
												if (!isNaN(reward[i])) {
													for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
														startingMatches = numberOfMatches[explorerFilterValue.length * currentC];
														RC = i + (explorerFilterValue.length * currentC);

														
														if (startingMatches >= minimumSynapses){
															if (startingMatches == minimumSynapses) {
																if (numberOfMatches[RC] == minimumSynapses) individualCost = 0;
																else individualCost = NaN;
															}
															else individualCost = ((startingMatches - numberOfMatches[RC])/ (startingMatches - minimumSynapses)) * 100;
															totalCost = totalCost + individualCost;
															if (individualCost >= 100 || isNaN(individualCost)) {
																totalCost = NaN;
																currentC = saveDirectorySubfolders.length;
															}
														}
														else if (numberOfMatches[RC] < startingMatches) {
															totalCost = NaN;
															currentC = saveDirectorySubfolders.length;
														}
													}
													cost[i] = totalCost / saveDirectorySubfolders.length;
													rewardCostRatio = reward[i]/cost[i];
													if (rewardCostRatio > bestrewardCostRatio || cost[i] == 0) {
														if (rewardCostRatio > bestrewardCostRatio) bestrewardCostRatio = rewardCostRatio;
														minimumDelta = i;
													}
												}
											}

											
											for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
												if (!isNaN(autoCombinationCount)){
													if (toDisplayCount == 2) startMatchesNumber[currentC] = numberOfMatches[explorerFilterValue.length * currentC];
												}
												else startMatchesNumber[currentC] = numberOfMatches[explorerFilterValue.length * currentC];
												print("\\Update"+ toString(11 + currentC) +":n = " + toString(numberOfMatches[minimumDelta + (explorerFilterValue.length * currentC)]) + " synapses [" + toString(startMatchesNumber[currentC]) + " at Start]");
											}
										}
										else {
											minimumDelta = explorerFilterValue.length - 1;
											for (i = explorerFilterValue.length - 1; i >= 0 ; i--) {
												peakVCdelt = calculateIndividualDeltaVals(peakGoal, deltaValue1[explorerFilterValue.length - 1], deltaValue1[i]);
												peakAZdelt = calculateIndividualDeltaVals(peakGoal, deltaValue2[explorerFilterValue.length - 1], deltaValue2[i]);
												meanVCdelt = calculateIndividualDeltaVals(meanGoal, deltaValueAllPoints1[explorerFilterValue.length - 1], deltaValueAllPoints1[i]);
												meanAZdelt = calculateIndividualDeltaVals(meanGoal, deltaValueAllPoints2[explorerFilterValue.length - 1], deltaValueAllPoints2[i]);
												
										
												reward[i] = peakVCdelt + peakAZdelt + meanVCdelt + meanAZdelt;
												totalCost = 0;
												if (!isNaN(reward[i])) { 
													for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
														startingMatches = numberOfMatches[(explorerFilterValue.length * currentC) + explorerFilterValue.length - 1];
														RC = i + (explorerFilterValue.length * currentC);
														
														
														if (startingMatches >= minimumSynapses){
															if (startingMatches == minimumSynapses) {
																if (numberOfMatches[RC] == minimumSynapses) individualCost = 0;
																else individualCost = NaN;
															}
															else individualCost = ((startingMatches - numberOfMatches[RC])/ (startingMatches - minimumSynapses)) * 100;
															totalCost = totalCost + individualCost;
															if (individualCost >= 100 || isNaN(individualCost)) {
																totalCost = NaN;
																currentC = saveDirectorySubfolders.length;
															}
														}
														else if (numberOfMatches[RC] < startingMatches) {
															totalCost = NaN;
															currentC = saveDirectorySubfolders.length;
														}
													}
													cost[i] = totalCost / saveDirectorySubfolders.length;
													rewardCostRatio = reward[i]/cost[i];
													if (rewardCostRatio > bestrewardCostRatio || cost[i] == 0) {
														if (rewardCostRatio > bestrewardCostRatio) bestrewardCostRatio = rewardCostRatio;
														minimumDelta = i;
													}
												}
											}
											
											for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
												if (!isNaN(autoCombinationCount)){
													if (toDisplayCount == 1) startMatchesNumber[currentC] = numberOfMatches[(explorerFilterValue.length * currentC) + explorerFilterValue.length - 1];
												}
												else startMatchesNumber[currentC] = numberOfMatches[(explorerFilterValue.length * currentC) + explorerFilterValue.length - 1];
												print("\\Update"+ toString(11 + currentC) +":n = " + toString(numberOfMatches[minimumDelta + (explorerFilterValue.length * currentC)]) + " synapses [" + toString(startMatchesNumber[currentC]) + " at Start]");
											}
										}
//										print(sortChoicesDisplayNames[explorer + 2] + " |  " + signName + " " + explorerFilterValue[minimumDelta] + " |  ");
										lastPeakVCdeltaValue = deltaValue1[minimumDelta];
										lastPeakAZdeltaValue = deltaValue2[minimumDelta];
										lastMeanVCdeltaValue = deltaValueAllPoints1[minimumDelta];
										lastMeanAZdeltaValue = deltaValueAllPoints2[minimumDelta];
									}
								
									if (isNaN(autoCombinationCount)){
										selectWindow(plotChannelsTitle[0]);
										run("Select All");
										getSelectionBounds(x, y, plotwidth, plotheight);
										imageColumns = round(sqrt(saveDirectorySubfolders.length)) + 1;
										imageRows = floor(sqrt(saveDirectorySubfolders.length)) + 1;
										if (imageColumns < unblindedOption) imageColumns = unblindedOption;
										
										newImage(toString(sortChoicesDisplayNames[explorer + 2]) + " - All Plots   [X axis - distance in " + getInfo("micrometer.abbreviation") + "]   ", "RGB", plotwidth * imageColumns, plotheight * imageRows, explorerFilterValue.length);
										imageMontage = getTitle();
										for (i = 0; i < explorerFilterValue.length; i++) {
											loopRow = 0;
											loopColumn = 0;
											selectWindow(imageMontage);
											setSlice(i + 1);
											for (currentC = 0; currentC < saveDirectorySubfolders.length; currentC++) {
												if (loopColumn == imageColumns) {
													loopColumn = 0;
													loopRow++;
												}
												selectWindow(plotTitles[currentC]);
												setSlice(i + 1);
												run("Select All");
												run("Copy");
												selectWindow(imageMontage);
												makeRectangle(plotwidth * loopColumn, plotheight * loopRow, plotwidth, plotheight);
												run("Paste");
												run("Select None");
												loopColumn++;
											}
												
											loopRow = imageRows - 1;
											loopColumn = 0;
											for (ii = 0; ii < unblindedOption; ii++) {
												selectWindow(plotChannelsTitle[ii]);
												setSlice(i + 1);
												run("Select All");
												run("Copy");
												selectWindow(imageMontage);
												makeRectangle(plotwidth * loopColumn, plotheight * loopRow, plotwidth, plotheight);
												run("Paste");
												run("Select None");
												loopColumn++;
											}

										setMetadata("Label", "Reward: " + toString(reward[i]) + " Cost: " + toString(cost[i]) + " Reward Cost Ratio: " + toString(reward[i]/cost[i]));
										}
										selectWindow(imageMontage);
	
										call("ij.gui.ImageWindow.setNextLocation", 0, 0);
										setBatchMode("show");
										getLocationAndSize(IMx, IMy, IMwidth, IMheight);
										if (!isNaN(explorer)) setSlice(minimumDelta + 1);
									}
								}

								//Loop through saved totalprofiles and create plots^
								
								if (C == saveDirectorySubfolders.length - 1){
									//setBatchMode("show");

									if (autoCombinationCount <= autoCombinationCountMax){
										if (signName == "<=") lastChoiceSettings[lCS_i + 1] = explorerFilterValue[minimumDelta];
										else if (signName == ">=") lastChoiceSettings[lCS_i] = explorerFilterValue[minimumDelta];
										
										C = -1;
									}
									else {
										if (!isNaN(explorer)) print("\\Clear");
										if (!isNaN(customNumberToPlot) && customNumberToPlot > 0) print("First " + toString(customNumberToPlot) + " synapses averaged");
										
										Dialog.createNonBlocking("Filter Settings Adjustment");
										choicesCC = newArray("No", "Yes");
										if (explorerFilterValue.length == 1){ 
											Dialog.addChoice("Use these settings?", choicesCC, 0);
											Dialog.setLocation(IMx + IMwidth,IMy);
											Dialog.show();
											if (Dialog.getChoice() == "No") C = -1;
										}
										else {
											print("[" + toString(sortChoicesDisplayNames[explorer + 2]) + "]\nRecommended Filter Setting: " + signName + " " + toString(explorerFilterValue[minimumDelta]) + "\n\nAdjust slider to explore filter values"
												+ "\n(Slider has been set to recommended value)\n\n'" + fromCharCode(916) 
												+ "' Value corresponds to max difference \nbetween each curve's max intensities\n");
											
											Dialog.addMessage("Click OK to Continue");
											Dialog.setLocation(IMx + IMwidth,IMy);
											Dialog.show();
											C = -1;
										}
										close("*");
										call("ij.gui.ImageWindow.setNextLocation", -1100, -1100)
										newImage("nullImage", "8-bit", 1000, 1000, 1);
										print("\\Clear");
									}
								}
							}
							/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
							C = originalC - 1;
							newWindow = 1;
							j = RoiC;
							continue;
						}
						else if (sortChoice == "Combination" && newWindow == 1){
							nFilteredROIs = 0;
							//RoiC = mean +1 SD +2 Min +3 Max
							cutOff = newArray(sortChoices.length - 2);
							lowerCutOff = newArray(sortChoices.length - 2);
							secondCutOff = newArray(sortChoices.length - 2);
							for (i = 0; i < sortChoices.length-2; i++){
								if (checkBoxArray[i] == 1 && (weightValueP[i] != 0 || weightValueN[i] != 0)){
									tempArray = newArray(RoiC);
									tempArrayHigh = newArray(RoiC);
									tempArrayLow = newArray(RoiC);
									for (ii = 0; ii < RoiC; ii++) tempArray[ii] = getResult(sortChoices[i+2], ii);
									tempArray = Array.sort(tempArray);
									tempArrayHigh = Array.slice(tempArray,round(0.75*tempArray.length)-1,round(0.75*tempArray.length));
									tempArraySecond = Array.slice(tempArray,round(0.50*tempArray.length)-1,round(0.50*tempArray.length));
									tempArrayLow = Array.slice(tempArray,round(0.25*tempArray.length)-1,round(0.25*tempArray.length));
									cutOff[i] = tempArrayHigh[0];
									secondCutOff[i] = tempArraySecond[0];
									lowerCutOff[i] = tempArrayLow[0];
								}
							}
							passCount = newArray(RoiC);
							sortArray = newArray(RoiC);
							singleFilteredROI = newArray(RoiC);


							//If the ROI is red, prefilter it
							deletedROIsArray = split(deletedROIsString[C], "|");
							for (ii = 0; ii < RoiC; ii++){
								if (deletedROIsArray[ii] == "1") {
									passCount[ii] = passCount[ii] - 10000;
									singleFilteredROI[ii] = 1;
								}
							}


							//Use previously determined ranking of Target signal per condition to remove outliers according to user input
							sortArrayTargetMax = split(sortArrayTargetMaxString[C], "|");
							
							//First for the lower X percent
							if (!isNaN(lowPercent)) {
								for (ii = 0; ii < round(sortArrayTargetMax.length * (lowPercent / 100)); ii++){
									thisROI = parseInt(sortArrayTargetMax[ii]);
									passCount[thisROI] = passCount[thisROI] - 10000;
									singleFilteredROI[thisROI] = 1;
								}
							}
							//Then for the higher X percent
							if (!isNaN(highPercent)) {
								for (ii = round(sortArrayTargetMax.length * (highPercent / 100)); ii < sortArrayTargetMax.length; ii++){
									thisROI = parseInt(sortArrayTargetMax[ii]);
									passCount[thisROI] = passCount[thisROI] - 10000;
									singleFilteredROI[thisROI] = 1;
								}
							}
									
							for (i = 0; i < sortChoices.length-2; i++) {
								if (checkBoxArray[i] == 1) {
									if (weightValueP[i] > 0 || weightValueN[i] > 0) fineSorting = 1;
									else fineSorting = 0;
									if (!isNaN(minFilterVal[i]) || !isNaN(maxFilterVal[i])) filtering = 1;
									else filtering = 0;
									if (filtering + fineSorting == 0) continue;
									
									for (ii = 0; ii < RoiC; ii++){
										if (singleFilteredROI[ii] != 1){
											resultTemp = getResult(sortChoices[i+2], ii);
											
											if (fineSorting == 1){
												if (resultTemp >= cutOff[i]) passCount[ii] = passCount[ii] + 1*weightValueP[i];
												else if (resultTemp >= secondCutOff[i]) passCount[ii] = passCount[ii] + 0.5*weightValueP[i];
												else if (resultTemp >= lowerCutOff[i]) passCount[ii] = passCount[ii] - 0.5*weightValueN[i];
												else if (resultTemp <= lowerCutOff[i]) passCount[ii] = passCount[ii] - 1*weightValueN[i];
											}
											
											if (filtering == 1){
												if (abs(resultTemp) < abs(minFilterVal[i]) || abs(resultTemp) > abs(maxFilterVal[i])) {
													passCount[ii] = passCount[ii] - 10000;
													singleFilteredROI[ii] = 1;
												}
											}
										}
									}
								}
							}
							for (i = 0; i < RoiC; i++) if (singleFilteredROI[i] == 1) nFilteredROIs++;
							
							if (!isNaN(customNumberToPlot) && customNumberToPlot > 0 && customNumberToPlot < (RoiC - nFilteredROIs)) {
								nFilteredROIs = (RoiC - customNumberToPlot);
							}
							sortArray = Array.rankPositions(passCount);
							sortArray = Array.reverse(sortArray);
							j = -1;
						}
						else if (sortChoice == "Individual") {
							sortArray = Array.getSequence(RoiC);
							resultArray = newArray(RoiC);
							for (ii = 0; ii < RoiC; ii++) resultArray[ii] = getResult(individualSortChoice, ii);
							resultArray = Array.rankPositions(resultArray);
							sortArray = Array.reverse(resultArray);
							lastSortChoice = sortChoice;
							nFilteredROIs = 0;
							j = -1;
						}
						else {
							sortArray = Array.getSequence(RoiC);
							individualSortChoice = "";
							lastSortChoice = sortChoice;
							nFilteredROIs = 0;
							j = -1;
						}
					}
					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					if (windowNumber != C && newWindow == 0){ 
						C = windowNumber - 1;
						j = RoiC;
					}
				}
				else{
					if (keyOpt == 2){
						roiManager("select", sortArray[j]);
						Roi.setStrokeColor("#80ff0000");
						roiManager("update");
						
						deletedROIsArray = split(deletedROIsString[grouplist[w]], "|");
						deletedROIsArray[sortArray[j]] = "1";
						deletedROIsString[grouplist[w]] = deletedROIsArray[0];
						for (i = 1; i < deletedROIsArray.length; i++) deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "|" + deletedROIsArray[i];

						if (currentRoiColor != "#80ff0000") {
							excludedNumber[grouplist[w]] = excludedNumber[grouplist[w]]+1;
							excludedNumberi[w] = excludedNumberi[w]+1;
						}
						if (currentRoiColor == "#4000ff00") {
							chosenNumber[grouplist[w]] = (chosenNumber[grouplist[w]])-1;
							chosenNumberi[w] = chosenNumberi[w]-1;
						}
						if (currentRoiColor == "#21e2e2e2") {
							skippedNumber[grouplist[w]] = (skippedNumber[grouplist[w]])-1;						
							skippedNumberi[w] = skippedNumberi[w]-1;
						}
					}
					else if (keyOpt == 3) {
						roiManager("select", sortArray[j]);
						Roi.setStrokeColor("#21e2e2e2");
						roiManager("update");
						
						deletedROIsArray = split(deletedROIsString[grouplist[w]], "|");
						deletedROIsArray[sortArray[j]] = "0";
						deletedROIsString[grouplist[w]] = deletedROIsArray[0];
						for (i = 1; i < deletedROIsArray.length; i++) deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "|" + deletedROIsArray[i];
						
//						if (getResult("overlap", sortArray[j]) == 0) roiManager("rename", "{" + toString(abs(getResult("distanceFromEdge", sortArray[j]))) + "|" + getResultString("VCdepth", sortArray[j]) + "}");
//						else roiManager("rename", "{-" + toString(abs(getResult("distanceFromEdge", sortArray[j]))) + "|" + getResultString("VCdepth", sortArray[j]) + "}");

//						tempString = toString(getResult("distanceFromEdge", sortArray[j])) + "|" + getResultString("VCdepth", sortArray[j]) + "*";
//						roiManager("rename", "{" + toString(abs(getResult("distanceFromEdge", sortArray[j]))) + "|" + getResultString("VCdepth", sortArray[j]) + "}");
						if (currentRoiColor != "#21e2e2e2"){ 
							skippedNumber[grouplist[w]] = (skippedNumber[grouplist[w]])+1;
							skippedNumberi[w] = skippedNumberi[w]+1;
						}
						if (currentRoiColor == "#4000ff00"){
							chosenNumber[grouplist[w]] = (chosenNumber[grouplist[w]])-1;
							chosenNumberi[w] = chosenNumberi[w]-1;
						}
						if (currentRoiColor == "#80ff0000") {
							excludedNumber[grouplist[w]] = excludedNumber[grouplist[w]]-1;
							excludedNumberi[w] = excludedNumberi[w]-1;
						}
					}
					else if (keyOpt == 4) {
						roiManager("select", sortArray[j]);
						Roi.setStrokeColor("#4000ff00");
						roiManager("update");
						
						deletedROIsArray = split(deletedROIsString[grouplist[w]], "|");
						deletedROIsArray[sortArray[j]] = "0";
						deletedROIsString[grouplist[w]] = deletedROIsArray[0];
						for (i = 1; i < deletedROIsArray.length; i++) deletedROIsString[grouplist[w]] = deletedROIsString[grouplist[w]] + "|" + deletedROIsArray[i];
						
//						if (getResult("overlap", sortArray[j]) == 0) roiManager("rename", "{" +toString(abs(getResult("distanceFromEdge", sortArray[j]))) + "|" + getResultString("VCdepth", sortArray[j]) + "}");
//						else roiManager("rename", "{-" + toString(abs(getResult("distanceFromEdge", sortArray[j]))) + "|" + getResultString("VCdepth", sortArray[j]) + "}");
						
//						tempString = toString(getResult("distanceFromEdge", sortArray[j])) + "|" + getResultString("VCdepth", sortArray[j]) + "*";
						if (currentRoiColor != "#4000ff00"){
							chosenNumber[grouplist[w]] = (chosenNumber[grouplist[w]])+1;
							chosenNumberi[w] = chosenNumberi[w]+1;
						}
						if (currentRoiColor == "#21e2e2e2"){
							skippedNumber[grouplist[w]] = (skippedNumber[grouplist[w]])-1;
							skippedNumberi[w] = skippedNumberi[w]-1;
						}
						if (currentRoiColor == "#80ff0000") {
							excludedNumber[grouplist[w]] = excludedNumber[grouplist[w]]-1;
							excludedNumberi[w] = excludedNumberi[w]-1;
						}
					}
				}
				lastViewChoice = viewChoice;
				lastRoiSelection = j;
				close(openList[w]);
			
				if (File.exists(pathPass[w] + "ROIs.zip")){
					deletesuccess = File.delete(pathPass[w] + "ROIs.zip");
					roiIndexes = Array.slice(roiSaveIndexes,WSaveStart[w],WSaveEnd[w]);
					roiManager("select", roiIndexes);
					roiManager("save selected", pathPass[w] + "ROIs.zip");
				}
			}
			newWindow = 0;
			if (j < -1) j = -1;
		}
		roiManager("reset");
		if (isOpen(titlet)) {
			selectWindow(titlet);
			close();
		}
		if (isOpen(allLinescans)) {
			selectWindow(allLinescans);
			close();
		}
		run("Clear Results");

		tempOptions = File.open(tempRevDirectory);
		print(tempOptions, xPlot1); //0
		print(tempOptions, yPlot1); //1
		print(tempOptions, xPlot2); //2
		print(tempOptions, yPlot2); //3
		print(tempOptions, lastSquareSize); //4
		print(tempOptions, zoom); //5
		print(tempOptions, AZzoom); //6
		print(tempOptions, dialogX); //7
		print(tempOptions, dialogY); //8
		print(tempOptions, dialogLoc); //9
		print(tempOptions, xWin); //10
		print(tempOptions, yWin); //11
		print(tempOptions, AZxWin); //12
		print(tempOptions, AZyWin); //13
		print(tempOptions, displayMode); //14
		print(tempOptions, activeChannels); //15
		print(tempOptions, blocksizeChoice); //16
		File.close(tempOptions);

		lastChoiceSettingsString = toString(lastChoiceSettings[0]);
		for (i = 1; i < lastChoiceSettings.length; i++) lastChoiceSettingsString = lastChoiceSettingsString + "," + toString(lastChoiceSettings[i]);
		if (File.exists(combinedFolder + "filterSettings" + repNumber + ".csv")) delete = File.delete(combinedFolder + "filterSettings" + repNumber + ".csv");
		tempOptions = File.open(combinedFolder + "filterSettings" + repNumber + ".csv");
		print(tempOptions, lastChoiceSettingsString);
		File.close(tempOptions);
		
		if (exitState == "Exit and Save") C = saveDirectorySubfolders.length;
		else if (C < -1) C = -1;
		else if (C > saveDirectorySubfolders.length - 2) C = -1;
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	for (errorLoop = 0; errorLoop < 1; errorLoop++) {
		Dialog.create("Exit?");
		choicesDelete = newArray("No", "Keep Unfiltered Synapses", "Yes", "Yes, & Unmarked Synapses", "Yes, & Unmarked/Skipped Synapses");
		saveOptions = newArray("Parallel", "Perpendicular");
		choicesReview = newArray("Yes", "Exit");
		Dialog.addChoice("Delete Bad ROIs? (Original ROIs NOT Deleted, Saved as Separate File)", choicesDelete, 0);
		Dialog.addNumber("ROIs per Condition Max: ", NaN);
		Dialog.addNumber("ROI Length:", finalLength);
		Dialog.addNumber("ROI Width:", finalWidth);
		Dialog.addChoice("Save as: ", saveOptions, "Perpendicular");
		Dialog.addChoice("Review again?", choicesReview, 0);
		Dialog.show();
		deleteOption = Dialog.getChoice();
		Cap = Dialog.getNumber();
		finalLength = Dialog.getNumber();
		finalWidth = Dialog.getNumber();
		saveOption = Dialog.getChoice();
		if (deleteOption == "Keep Unfiltered Synapses" && combinationPassedROIs.length == 0) {
			waitForUser("Error: No combination filter settings selected for this session");
			errorLoop = -1;
		}
	}

	b4 = getTime();
	if (deleteOption != "No"){
		countC = newArray(saveDirectorySubfolders.length);
		for (w = 0; w < openList.length; w++) {
			deletesuccess = File.delete(pathPass[w] + "finalROIs.zip");
			print("[" + toString(w) + "/" + toString(openList.length - 1) + "]");
//			print("\\Update:[" + toString(w) + "/" + toString(openList.length - 1) + "]");
			roiManager("reset");
			
			count = 0;
			if (File.exists(pathPass[w] + "ROIs.zip")){
				
				if (deleteOption == "Keep Unfiltered Synapses") {
					combinationPass = split(combinationPassedROIs[w], "|");
				}
				roiEdgeDistanceandDepth = split(roiEdgeDistanceandDepthString[w], "*");
			
				roiManager("open", pathPass[w] + "ROIs.zip");
				
				open(openListDir[w]+openList[w]);
				selectWindow(openList[w]);
//To add manual editing				blocksize = 30;	histogram_bins = 256;	maximum_slope = 3;	mask = "*None*";	fast = true;	process_as_composite = true;	run( "Enhance Local Contrast (CLAHE)", "blocksize=" + blocksize + " histogram=" + histogram_bins + " maximum=" + maximum_slope + " mask=" + mask + " fast_(less_accurate)" + " process_as_composite");
				RoiC = roiManager("count");
				print("Total :" + toString(RoiC));
				roisToDelete = newArray(RoiC);
				if (deleteOption == "Keep Unfiltered Synapses") {
					for (j = 0; j < RoiC; j++) {
						roiManager("select", j);
						roiColor = Roi.getStrokeColor;
						getLine(x1, y1, x2, y2, lineWidth);
						lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
						if (combinationPass[j] == "0" || roiColor == "#80ff0000" || isNaN(lineLength) || lineLength == 0 || countC[grouplist[w]] == Cap) roisToDelete[j] = 1;
						else {
							roisToDelete[j] = 0;
							roiManager("rename", "{" + roiEdgeDistanceandDepth[j] + "|" + repNumber + "}");
							count++;
							countC[grouplist[w]] = countC[grouplist[w]] + 1;
						}
					}
				}
				else {
					for (j = 0; j < RoiC; j++) {
						roiManager("select", j);
						roiColor = Roi.getStrokeColor;
						getLine(x1, y1, x2, y2, lineWidth);
						lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));

						if (countC[grouplist[w]] == Cap) roisToDelete[j] = 1;
						else if (deleteOption == "Yes" && roiColor == "#80ff0000") roisToDelete[j] = 1;
						else if (deleteOption == "Yes, & Unmarked/Skipped Synapses" && roiColor != "#4000ff00") roisToDelete[j] = 1;
						else if (deleteOption == "Yes, & Unmarked Synapses" && roiColor != "#4000ff00" && roiColor != "#21e2e2e2") roisToDelete[j] = 1;
						else if (isNaN(lineLength) || lineLength == 0) roisToDelete[j] = 1;
						else {
							roisToDelete[j] = 0;
							roiManager("rename", "{" + roiEdgeDistanceandDepth[j] + "|" + repNumber + "}");
							count++;
							countC[grouplist[w]] = countC[grouplist[w]] + 1;
						} 
					}
				}
				print("Kept: " + toString(count));

				cc = 0;
				roiIndexes = newArray(0);
				for (j = 0; j < RoiC; j++) {
					if (roisToDelete[j] == 0) {
						roiManager("select", j);
//To add manual editing					RoiTempName = Roi.getName;	if (matches(Roi.getName(), ".*EditAfter.*")){	////////////////////////MANUALLY EDITING ROIS	Dialog.createNonBlocking("Edit ROI #"+toString(j)+", then press OK");	selectWindow(openList[w]);	setBatchMode("show");	roiManager("select", j);	run("To Selection");	Stack.setDisplayMode("composite");	Stack.setActiveChannels("110");	Dialog.show();	roiManager("update");	selectWindow(openList[w]);	setBatchMode("hide");	roiManager("select", j);	roiManager("rename", "[H]");	RoiTempName = Roi.getName;	currentRoiColor = Roi.getStrokeColor;	getLine(x1, y1, x2, y2, lineWidth);	lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));	}
							if (saveOption == "Perpendicular"){
								getLine(x1, y1, x2, y2, lineWidth);
								lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
		
								F = ((finalLength - (lineLength))/2);
								F = (F/(lineLength));
								makeLine((x1+F*(x1-x2)), (y1+F*(y1-y2)), (x2+F*(x2-x1)), (y2+F*(y2-y1)), round(finalWidth / pixelWidth));
								roiManager("update");
								run("Rotate...", "  angle=90");
								roiManager("update");
								Roi.setStrokeColor(roiDefaultColor);
								roiManager("update");
							}
					}
					else if (roisToDelete[j] == 1) roiIndexes[cc++] = j;
				}
				selectWindow(openList[w]);
				close();
				if (cc > 0) {
					roiManager("select", roiIndexes);
					roiManager("delete");
				}
				if (roiManager("count") > 0) {
					roiManager("deselect");
					roiManager("save", pathPass[w] + "finalROIs.zip");
				}
				roiManager("reset");	 
			}
		}
	}
	for (i = 0; i < saveDirectorySubfolders.length; i++) print("Total kept Condition" + toString(i + 1) + ": " + toString(countC[i]));
	
	if (Dialog.getChoice() == "Yes") restart = 0;
	else restart = 2;
}


function shuffle(array) {
   s = array.length;
   while (s > 1) {
      r = randomInt(s);
      s--;
      temp = array[s];
      array[s] = array[r];
      array[r] = temp;
   }
}
function randomInt(s) {
   return s * random();
}

function getAngle(x1, y1, x2, y2) {
      q1=0; q2orq3=2; q4=3; //quadrant
      dx = x2-x1;
      dy = y1-y2;
      if (dx!=0)
          angle = atan(dy/dx);
      else {
          if (dy>=0)
              angle = PI/2;
          else
              angle = -PI/2;
      }
      angle = (180/PI)*angle;
      if (dx>=0 && dy>=0)
           quadrant = q1;
      else if (dx<0)
          quadrant = q2orq3;
      else
          quadrant = q4;
      if (quadrant==q2orq3)
          angle = angle+180.0;
      else if (quadrant==q4)
          angle = angle+360.0;
      return angle;
}

function autoAdjustBrightness(window){
	selectWindow(window);
	for (c = 0; c < 2; c++) {	
		Stack.setChannel(c+1);
		AUTO_THRESHOLD = 5000; 
		getRawStatistics(pixcount); 
		limit = pixcount/10; 
		threshold = pixcount/AUTO_THRESHOLD; 
		nBins = 256; 
		getHistogram(values, histA, nBins); 
		i = -1; 
		found = false; 
		do { 
		counts = histA[++i]; 
		if (counts > limit) counts = 0; 
		found = counts > threshold; 
		} while ((!found) && (i < histA.length-1)) 
		hmin = values[i]; 
		
		i = histA.length; 
		do { 
		counts = histA[--i]; 
		if (counts > limit) counts = 0; 
		found = counts > threshold; 
		} while ((!found) && (i > 0)) 
		hmax = values[i]; 

		setMinAndMax(hmin, hmax); 
	}
}

function cacheKey() {
	shiftKey = isKeyDown("shift");
	ctrlKey = isKeyDown("control");
}
function restoreKey() {
	if (shiftKey && ctrlKey) setKeyDown("shift,control");
	else if (shiftKey) setKeyDown("shift");
	else if (ctrlKey) setKeyDown("control");
}

//goal = 10;
//
//starting = 13;
//input = 14;
//x = calculateIndividualDeltaVals(goal, starting, input);
function calculateIndividualDeltaVals(thisGoal, startingDeltaValue, thisDeltaValue) {
	multiplierNegWithinGoal = 0.25;
	multiplierPosWithinGoal = 0.1;
	multiplierNegOutsideGoal = 3;
	if (startingDeltaValue < thisGoal) {																//if the starting delta value already reached the goal
		if (thisDeltaValue < thisGoal && ((startingDeltaValue - thisDeltaValue) >= 0)) outputDeltaVal = multiplierPosWithinGoal * (startingDeltaValue - thisDeltaValue);   //give it a fractional weight as long as it remains within the goal
		else if (thisDeltaValue < thisGoal && ((startingDeltaValue - thisDeltaValue) < 0)) outputDeltaVal = multiplierNegWithinGoal * (startingDeltaValue - thisDeltaValue);   //give it a fractional weight as long as it remains within the goal
		else outputDeltaVal = (multiplierNegWithinGoal * (startingDeltaValue - thisGoal)) + (multiplierNegOutsideGoal * (thisGoal - thisDeltaValue));		//double the negative weight if it no longer reaches the goal
	}
	else {																								//if the starting value has yet to reach its goal
		if (thisDeltaValue >= thisGoal) {
			outputDeltaVal = (startingDeltaValue - thisDeltaValue);									//and this value still hasn't, give it a normal weighting,
			if (outputDeltaVal < 0) outputDeltaVal = multiplierNegOutsideGoal * outputDeltaVal;								//unless the delta value got worse, in which case weight [insert] times the negative weight
		}
		else outputDeltaVal = (startingDeltaValue - thisGoal) + (multiplierPosWithinGoal * (thisGoal - thisDeltaValue));	//but if the current value has surpassed the goal, any further improvement(reduction) in delta value is less rewarding
	}
	return outputDeltaVal;
}
//print(x);