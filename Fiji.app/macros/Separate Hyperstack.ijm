// Choose folder that 
pathPassString = getArgument();
pathPass = split(pathPassString, "|");
pathPass = Array.delete(pathPass, "");
if (pathPass.length < 1) exit("No Images Open");
setOption("ExpandableArrays", true);

openListDir = newArray(pathPass.length);
openList = newArray(pathPass.length);
for (w = 0; w < pathPass.length; w++) {
	index = lastIndexOf(pathPass[w], File.separator);
	indexB = lastIndexOf(pathPass[w], "/");
	if (indexB > index) index = indexB;
	openListDir[w] = substring(pathPass[w], 0, index + 1);
	openList[w] = substring(pathPass[w], index + 1, lengthOf(pathPass[w]));
}

count = 0;
titleDir = newArray(0);
titleList = newArray(0);
lifSeries = newArray(0);
lifName = newArray(0);
run("Bio-Formats Macro Extensions");
for (w = 0; w < openList.length; w++) {
	if (endsWith(openList[w], ".lif")) {
		path = openListDir[w] + openList[w];
		Ext.setId(path);
		Ext.getCurrentFile(file);
		Ext.getSeriesCount(seriesCount);

		for (s=0; s < seriesCount; s++) {
			Ext.setSeries(s);
			Ext.getSeriesName(seriesName);
			if (s == 0) Ext.getEffectiveSizeC(channelN);
			titleDir[count] = openListDir[w];
			titleList[count] = openList[w];
			lifSeries[count] = s;
			lifName[count] = seriesName;
			count++;
		}
	}
	else if (endsWith(openList[w], ".tif")) {
		titleDir[count] = openListDir[w];
		titleList[count] = openList[w];
		lifSeries[count] = NaN;
		lifName[count] = NaN;
		count++;
	}
}

if (isNaN(lifSeries[0])) {
	open(titleDir[0]+titleList[0]);
	selectWindow(titleList[0]);
	getDimensions(w, h, channelN, slices, frames);
	close();
}

setBatchMode("hide");

imageDir = getDirectory("'Condition#1', 'Condition#2', etc. folders will be added and individual images will be sorted according to group");
Dialog.createNonBlocking("");
Dialog.addNumber("Number of Conditions", 2);
Dialog.addNumber("Number of Repetitions (Cultures)", 3);
Dialog.show();
noC = Dialog.getNumber();
noR = Dialog.getNumber();

for (l = 0; l < 2; l++) {
	l = 0;
	Dialog.createNonBlocking("Condition Names");
	Dialog.addMessage("Names of each condition");
	for (i = 0; i < noC; i++) Dialog.addString("", "Condition#" + toString(i + 1));
	
	Dialog.addMessage("Names of each repetition (culture)");
	for (i = 0; i < noR; i++) Dialog.addString("", "Repetition#" + toString(i + 1));
	
	channelchoices = newArray("N/A", "Vesicle Cloud Associated Marker", "Active Zone Associated Marker", "Target Marker");
	Dialog.addCheckbox("Adjust Colors", 0);
	Dialog.addMessage("Check above to change AZ channel to *Red*, VC channel to *Blue*, & Target channel to *Green*");
	for (i = 0; i < channelN; i++) Dialog.addChoice("Channel " + toString(i + 1), channelchoices, 1);
	html = "<html>"
		+"<h2>Image Sorting Help</h2>"
		+"<head>"
		+"<body aria><strong>   </strong><br />"
		+"    <br />"
		+"</html>";
	Dialog.addHelp(html);
	run("Hide Console Pane");
	Dialog.show();
	
	conditionArray = newArray(noC);
	repetitionsArray = newArray(noR);
	for (i = 0; i < noC; i++) {
		conditionArray[i] = Dialog.getString();
		conditionArray[i] = replace(conditionArray[i], '/', '-');
//		conditionArray[i] = replace(conditionArray[i], '-', '_');
//		conditionArray[i] = replace(conditionArray[i], '+', 'x');
	}
	for (i = 0; i < noR; i++) {
		repetitionsArray[i] = Dialog.getString();
		repetitionsArray[i] = replace(repetitionsArray[i], '/', '-');
//		repetitionsArray[i] = replace(repetitionsArray[i], '-', '_');
//		repetitionsArray[i] = replace(repetitionsArray[i], '+', 'x');
	}
	changeColors = Dialog.getCheckbox();
	channelArray = newArray(channelN);
	VCCount = 0;
	AZCount = 0;
	TGCount = 0;
	for (i = 0; i < channelN; i++) {
		channelArray[i] = Dialog.getChoice();
		if (channelArray[i] == "Vesicle Cloud Associated Marker") VCCount = VCCount + 1;
		if (channelArray[i] == "Active Zone Associated Marker") AZCount = AZCount + 1;
		if (channelArray[i] == "Target Marker") TGCount = TGCount + 1;
	}
	if (VCCount != 1 || AZCount != 1 || TGCount != 1) {
		waitForUser("Warning! Must Select One of Each Type of Marker!");
		continue;
	}
	else l = 2;
}

for (i = 0; i < noC; i++) {
	File.makeDirectory(imageDir + conditionArray[i] +File.separator);
}

setBatchMode(false);
run("Close All");
setBatchMode(true);

counter = 0;
imageTitleList = newArray(0);

for (t = 0; t < titleList.length; t++) {
	print("\\Update0:[" + toString(t + 1) + "/" + toString(titleList.length) + "]");
	if (isNaN(lifSeries[t])) {
		open(titleDir[t]+titleList[t]);
		selectWindow(titleList[t]);
		currentImageName = getTitle();
	}
	else if (lifSeries[t] % 60 == 0){
		seriesString =  " series_" + toString(lifSeries[t] + 1);
		for (i = 1; i < lifSeries.length; i++) {
			if ((t + i < lifSeries.length) && (lifSeries[t + i] % 60 != 0) && (lifSeries[t + i] != 0) && (!isNaN(lifSeries[t + i]))) seriesString = seriesString + " series_" + toString(lifSeries[t + i] + 1);
			else i = lifSeries.length;
		}
		run("Bio-Formats Importer", "open=["+ titleDir[t] + titleList[t] +"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack" + seriesString);
		findingLifsList = getList("image.titles");
		currentImageName = "Separate Hyperstack- Error1";
		for (i = 0; i < findingLifsList.length; i++) {
			if (endsWith(findingLifsList[i], lifName[t])) currentImageName = findingLifsList[i];
		}
	}
	else {
		currentImageName = "Separate Hyperstack- Error2";
		for (i = 0; i < findingLifsList.length; i++) {
			if (endsWith(findingLifsList[i], lifName[t])) currentImageName = findingLifsList[i];
		}
	}

	for (i = 0; i < channelN; i++) {
		if (channelArray[i] == "Vesicle Cloud Associated Marker") {
			selectWindow(currentImageName);
			run("Select All");
			run("Duplicate...", "duplicate channels=" + toString(i + 1));
			rename("VC Channel" + toString(t * i));
			CVC = getTitle();
			if(changeColors == 1) run("Blue");
		}
		else if (channelArray[i] == "Active Zone Associated Marker") {
			selectWindow(currentImageName);
			run("Select All");
			run("Duplicate...", "duplicate channels=" + toString(i + 1));
			rename("AZ Channel" + toString(t * i));
			CAZ = getTitle();
			if(changeColors == 1) run("Red");
		}
		else if (channelArray[i] == "Target Marker") {
			selectWindow(currentImageName);
			run("Select All");
			run("Duplicate...", "duplicate channels=" + toString(i + 1));
			rename("TG Channel" + toString(t * i));
			CTM = getTitle();
			if(changeColors == 1) run("Green");
		}
	}

	selectWindow(currentImageName);
	close();

	currentImageName = replace(currentImageName, '/', '-');
//	currentImageName = replace(currentImageName, '-', '_');
//	currentImageName = replace(currentImageName, '+', 'x');
	run("Merge Channels...", "c1=["+CVC+"] c2=["+CAZ+"] c3=["+CTM+"] create");
	rename(currentImageName);
	imageTitleList[counter++] = currentImageName;
}

//for (i = 0; i < imageTitleList.length; i++) print(imageTitleList[i]);
//print(imageTitleList.length);
//waitForUser;

blankArray = newArray("No Match- Manually Select");
conditionArrayChoices = Array.concat(blankArray,conditionArray);
repetitionsArrayChoices = Array.concat(blankArray,repetitionsArray);
conditionChoiceArray = newArray(imageTitleList.length);
repetitionsChoiceArray = newArray(imageTitleList.length);
lmax = -floor(-(imageTitleList.length/20));
for (l = 1; l <= lmax; l++) {
	Dialog.create("Condition/Repetition(Culture) Confirmation (Page " + toString(l) + "/" + toString(lmax) + ")");
	if (l == lmax) tmax = imageTitleList.length;
	else tmax = 20 * l;
	for (t = 20*(l-1); t < tmax; t++) {
		matched = 0;
		for (i = 0; i < noC; i++) {
			if (matches(imageTitleList[t], ".*" + conditionArray[i] + ".*")) {
				Dialog.addChoice(imageTitleList[t], conditionArrayChoices, conditionArray[i]);
				matched = 1;
				i = noC;
			}
		}
		if (matched == 0) Dialog.addChoice(imageTitleList[t], conditionArrayChoices, 1);

		matched = 0;
		Dialog.addToSameRow();
		for (i = 0; i < noR; i++) {
			if (matches(imageTitleList[t], ".*" + repetitionsArray[i] + ".*")) {
				Dialog.addChoice(imageTitleList[t], repetitionsArrayChoices, repetitionsArray[i]);
				matched = 1;
				i = noR;
			}
		}
		if (matched == 0) Dialog.addChoice("", repetitionsArrayChoices, 1);
	}
	run("Hide Console Pane");
	Dialog.show();
	
	for (i = 20*(l-1); i < tmax; i++) {
		conditionChoiceArray[i] = Dialog.getChoice();
		repetitionsChoiceArray[i] = Dialog.getChoice();
	}
}

for (t = 0; t < imageTitleList.length; t++) {
selectWindow(imageTitleList[t]);
setBatchMode("hide");
}

run("Clear Results");
for (t = 0; t < imageTitleList.length; t++) if (repetitionsChoiceArray[t] != "No Match- Manually Select"  && conditionChoiceArray[t] != "No Match- Manually Select") setResult(repetitionsChoiceArray[t], 0, 0);
for (t = 0; t < imageTitleList.length; t++) {
	if (conditionChoiceArray[t] != "No Match- Manually Select") {
		selectWindow(imageTitleList[t]);
		saveAs("tiff", imageDir + conditionChoiceArray[t] + File.separator + imageTitleList[t]);
		close();
	}
	else {
		print(imageTitleList[t] + " not transfered, no condition selected");
		selectWindow(imageTitleList[t]);
		close();
	}

	if (repetitionsChoiceArray[t] != "No Match- Manually Select" && conditionChoiceArray[t] != "No Match- Manually Select") {
		resultNumber = nResults;
		while(getResult(repetitionsChoiceArray[t], resultNumber - 1) == 0 && resultNumber > 0) resultNumber--;
		setResult(repetitionsChoiceArray[t], resultNumber, imageTitleList[t]);
	}
}
if (!File.exists(imageDir + "ROI Data" + File.separator)) File.makeDirectory(imageDir + "ROI Data" + File.separator);
if (!File.exists(imageDir + "ROI Data" + File.separator + "Combination" + File.separator)) File.makeDirectory(imageDir + "ROI Data" + File.separator + "Combination" + File.separator);
if (File.exists(imageDir + "ROI Data" + File.separator + "Combination" + File.separator + "Repetitions.csv")) deletesuccess = File.delete(imageDir + "ROI Data" + File.separator + "Combination" + File.separator + "Repetitions.csv");
saveAs("results", imageDir + "ROI Data" + File.separator + "Combination" + File.separator + "Repetitions.csv");
run("Clear Results");
setBatchMode("exit and display");