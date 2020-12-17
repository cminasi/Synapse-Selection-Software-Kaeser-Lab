//Blend Images MACRO 
tempDirectory = getDirectory("imagej");
tempOptDirectory = tempDirectory + "ChrisMacroTempOptions.txt";
mainDir = getArgument();

run("Close All");
print("\\Clear");

if (File.exists(tempOptDirectory)) {
	filestring=File.openAsString(tempOptDirectory); 
	rows=split(filestring, "\n");
}

//setBatchMode("hide");
setOption("ExpandableArrays", true);
list1 = getFileList(mainDir);
list1Array = newArray(0);
c = 0;
for (i=0; i<list1.length; i++) {
	if (endsWith(list1[i], "/")  && (!matches(list1[i], ".*Averaged Images/.*"))){
		list1Array[c] = list1[i];
		c++;
	}
}

File.makeDirectory(mainDir + "Averaged Images" + File.separator);
overlayDir = mainDir + "Averaged Images" + File.separator + "Raw" + File.separator;
File.makeDirectory(overlayDir);
group = newArray(list1Array.length);
for (k = 0; k < list1Array.length; k++) {
	channel = newArray(3);
	imageFinalPoints = newArray(0);
	for (kk = 0; kk < 3; kk++) {
		run("Clear Results");
		currentCount = 0;
		imageCounter = 0;
		dir = mainDir + list1Array[k] + rows[kk + 12] + File.separator;
		group[k] = File.getParent(dir);
		group[k] = File.getName(group[k]);
		channel[kk] = File.getName(dir);
		count = 0;
		countFiles(dir);
		
		list = getFileList(dir);
		if (list.length == 0) waitForUser("Error: No Chosen ROIs for one of the conditions");
		open(dir+list[0]);
		toOverlayWidth = getWidth();
		toOverlayHeight = getHeight();
		rename("ToOverlay");
		run("Select All");
		run("Clear", "slice");
		
		opac = count;
		var averageArray;
		averageArray = newArray(toOverlayWidth * toOverlayHeight);
		processFiles(dir);
		
		selectWindow("ToOverlay");
		getPixelSize(unit, pixelWidth, pixelHeight);
		averageCount = 0;
		for (x = 0; x < toOverlayWidth; x++) {
			for (y = 0; y < toOverlayHeight; y++) {
				setPixel(x, y, averageArray[averageCount++]);
			}
		}
		
		
		individualProfileLength = getResult("profileLength", 0);
		blendedProfile = newArray(individualProfileLength);
		for (ip = 0; ip < individualProfileLength; ip++) {
			averagingArray = newArray(imageCounter);
			for (imageLoop = 0; imageLoop < imageCounter; imageLoop++){
				averagingArray[imageLoop] = getResult("individualProfile#"+toString(imageLoop), ip);
			}
			Array.getStatistics(averagingArray, min, max, mean);
			blendedProfile[ip] = mean;
		}
		matchPoints = newArray(imageCounter);
		for (imageLoop = 0; imageLoop < imageCounter; imageLoop++){
			totalPoints = 0;
			for (ip = 0; ip < blendedProfile.length; ip++) {
				diff = abs(getResult("individualProfile#"+toString(imageLoop), ip) - blendedProfile[ip]);
				if (diff < blendedProfile[ip]) totalPoints = totalPoints + pow(((blendedProfile[ip] - diff)/blendedProfile[ip]), 2);
				else totalPoints = totalPoints - (diff/255);
			}
			matchPoints[imageLoop] = totalPoints;
		}
		closestIndexes = Array.rankPositions(matchPoints);
		closestIndexes = Array.reverse(closestIndexes);
		//print(group[k] + "-" + channel[kk]);
		valueCounter = 0;
		indexValue = newArray(imageCounter);
		for (imageLoop = 0; imageLoop < imageCounter; imageLoop++) {
			currentInd = closestIndexes[imageLoop];
			indexValue[currentInd] = valueCounter++;
		}
		if (imageFinalPoints.length == 0) imageFinalPoints = newArray(imageCounter);
		for (imageLoop = 0; imageLoop < imageCounter; imageLoop++) {
			//print(getResultString("nameOfImage", imageLoop) + "---" + indexValue[imageLoop]);
			imageFinalPoints[imageLoop] = imageFinalPoints[imageLoop] + indexValue[imageLoop];
		}

		
		selectWindow("ToOverlay");
		run("8-bit");
		run("Enhance Contrast", "saturated=0.35");
		save(overlayDir + group[k] + "-" + channel[kk] + "-overlay.tif");
		run("Close All");
	}
	print(group[k]);
	rankedImagePositions = Array.rankPositions(imageFinalPoints);
	for (imageLoop = 0; imageLoop < imageCounter; imageLoop++) {
		RIP = rankedImagePositions[imageLoop];
		stringToPrint = getResultString("nameOfImage", RIP);
		print(stringToPrint);
	}
	
	channelTitle = newArray(3);
	for (kk = 0; kk < 3; kk++){ 
		open(overlayDir + group[k] + "-" + channel[kk] + "-overlay.tif");
		channelTitle[kk] = getTitle();
	}
	run("Merge Channels...", "c1=" + channelTitle[0] + " c2=" + channelTitle[2] + " c3=" + channelTitle[1] + " create");
	save(overlayDir + group[k] + "-allOverlay.tif");
	run("Close All");
}
selectWindow("Log");
saveAs("Text", mainDir + "Ranking for Best Individual Representative Images");

setBatchMode(false);
newImage("null", "8-bit", 1, 1, 1);
run("Close All");

windowList = newArray(list1Array.length);
for (k = 0; k < list1Array.length; k++){
	open(overlayDir + group[k] + "-allOverlay.tif");
	windowList[k] = getTitle();
}

overlayDir = mainDir + "Averaged Images" + File.separator + "Adjusted LUTs" + File.separator;
File.makeDirectory(overlayDir);
colorChoices = newArray("Color", "Grayscale");

for (i = 0; i < 3; i++) {
	i = 0;
	Dialog.createNonBlocking("Edit LUTs Then Press 'Okay' to Save");
	Dialog.addNumber("Select Channel (0 for All)", 0);
	Dialog.addCheckbox("Ready to Exit and Save", 0);
	Dialog.addChoice("Save single channel images as:", colorChoices, 0)
	Dialog.show();
	channelToShow = Dialog.getNumber();
	exitAndSaveChoice = Dialog.getCheckbox();
	colorChoice = Dialog.getChoice();
	
	if (exitAndSaveChoice == 1) i = 3;
	else{
		for (k = 0; k < list1Array.length; k++) {
			selectWindow(windowList[k]);
			if (channelToShow == 0) Stack.setDisplayMode("Composite");
			else if (channelToShow > 0 && channelToShow <= 3){
				Stack.setDisplayMode("Color");
				Stack.setChannel(channelToShow);
			}
		}
		continue;
	}
}
for (i = 0; i < windowList.length; i++) {
	selectWindow(windowList[i]);
	Stack.setDisplayMode("Composite");
	Stack.setActiveChannels("111");
}
if (list1Array.length != windowList.length) waitForUser("Warning: Must Keep All Images Open to Save");
for (k = 0; k < windowList.length; k++){
	
	selectWindow(windowList[k]);
	run("Select None");
	run("RGB Color");
	save(overlayDir + group[k] + "-" + "-allOverlay.tif");
	close();
	
	selectWindow(windowList[k]);
	run("Select None");
	Stack.setChannel(1);
	run("Apply LUT");
	resetMinAndMax;
	run("Duplicate...", "duplicate channels=1");
	if (colorChoice == "Grayscale") run("8-bit");
	save(overlayDir + group[k] + "-" + channel[1] + "-overlay.tif");
	close();
	
	selectWindow(windowList[k]);
	run("Select None");
	Stack.setChannel(2);
	resetMinAndMax;
	run("Duplicate...", "duplicate channels=2");
	if (colorChoice == "Grayscale") run("8-bit");
	save(overlayDir + group[k] + "-" + channel[2] + "-overlay.tif");
	close();
	close();
}




function countFiles(dir) {
  list = getFileList(dir);
  for (i=0; i<list.length; i++) {
      if (endsWith(list[i], "/"))
          countFiles(""+dir+list[i]);
      else
          count++;
  }
}

function processFiles(dir) {
  list = getFileList(dir);
  for (i=0; i<list.length; i++) {
      if (endsWith(list[i], ".tif")){
         path = dir+list[i];
         processFile(path);
      }
  }
}

function processFile(path) {
	if (endsWith(path, ".tif")) {
		open(path);
		run("Canvas Size...", "width=" + toString(toOverlayWidth) + " height=" + toString(toOverlayHeight) + " position=Center zero");
		title = getTitle(); 
		getPixelSize(unit, pixelWidth, pixelHeight);
		individualWidth = getWidth();
		individualHeight = getHeight();
		averageCount = 0;
		for (x = 0; x < individualWidth; x++) {
			for (y = 0; y < individualHeight; y++) {
				averageArray[averageCount] = averageArray[averageCount] + (getPixel(x, y) / opac);
				averageCount++;
			}
		}
//		selectWindow("ToOverlay");
//		run("Add Image...", "image=[" + title + "] x="+ toString((OverlayWidthWithBoarder/2)-(individualWidth/2)) +" y="+ toString((OverlayHeightWithBoarder/2)-(individualHeight/2)) +" opacity=" + toString(opac));
		selectWindow(title);
		makeLine((individualWidth/2)-(0.5/pixelWidth), individualHeight/2, (individualWidth/2)+(0.3/pixelWidth), individualHeight/2, 0.25/pixelWidth);
		individualProfile = getProfile();
		currentCount = imageCounter++;
		setResult("nameOfImage", currentCount, title);
		for (ip = 0; ip < individualProfile.length; ip++) setResult("individualProfile#"+toString(currentCount), ip, individualProfile[ip]);
		setResult("profileLength", 0, individualProfile.length);
		close();
	}
}