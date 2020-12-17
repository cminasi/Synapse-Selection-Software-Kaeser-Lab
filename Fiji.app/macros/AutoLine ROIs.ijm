//AutoLine MACRO
//Optimal, standardized edge detection:
//Search for PSDs maxima (X [i.g. ~2] Standard Deviations 'Prominance')
//Start with high threshold and lower one by one, while using wand on maxima points
//Each thres lowering, knowing the maximum, (this being once its already gaussian distributed)...
//...note the point in which a particular maximum's object's perimeter point average...
//...is Y% [i.g. ~75%] of the maximum. Add that object for further analysis.
setOption("ExpandableArrays", true);
roiManager("reset");
startTime = getTime();
path = getArgument();
tempDirectory = getDirectory("imagej");
tempOptDirectory = tempDirectory + "ChrisMacroTempOptions.txt";
originalTitle = getTitle();
getPixelSize(unit, pixelWidth, pixelHeight);
debugmode = 0;
individualmode = 0;


print("\\Update4:|                    |");

if (File.exists(tempOptDirectory) && individualmode == 0) {
	filestring=File.openAsString(tempOptDirectory); 
	rows=split(filestring, "\n");

	var finalWidth;
	var finalLength;
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
}
else{
	minimumVClength = 0.3; //Minimum depth of vesicle cloud marker
	maximumVClength = 2; //Gets converted into area measurement, maximum size of vesicle cloud marker
	minimumAZlength = 0.20;
	maximumAZwidth = 0.4;
	AZaspectRatioMin = 1.5; //Minimum aspect ratio for active zone (length/width)
	maxInnerEdgeDistance = 0.05; //How far in should the AZ marker be relative to vesicle cloud?
	maxOuterEdgeDistance = 0.2; //How far from the edge of the vesicle cloud can the AZ marker be?
	scanLineLength = 1; //How far from an AZ should it scan to find a nearby vesicle cloud and its depth?
	scanningFraction = NaN; //Option to scan depth of VC marker based on fraction of AZ length. Set to NaN to turn off
	scanningMicrometers = 0.25; //Option to scan based on hard number (0.25 is default)
}

finalWidth = round(finalWidth / pixelWidth);
scanLineLength = scanLineLength * 2;
minimumVCarea = 0.25 * PI * pow(minimumVClength, 2);
maximumVCarea = 0.25 * PI * pow(maximumVClength, 2);
if (individualmode == 1) setBatchMode("hide");

minimumAZlength = minimumAZlength/pixelWidth;
maximumAZwidth = maximumAZwidth/pixelWidth;
//Split image into fractions then find local StdDevs
run("Set Measurements...", "mean standard redirect=None decimal=3");
imageWidth = getWidth();

var saveDirectory;
imageDir = getDirectory("image");
imageDir = substring(imageDir, 0, lengthOf(imageDir) - 1);
lastSlash = lastIndexOf(imageDir, File.separator);
saveDirectory = substring(imageDir, 0, lastSlash + 1);

////////////////////////////////local fractions AZ
micrometerSections = 10;
if (imageWidth*pixelWidth < micrometerSections) micrometerSections = imageWidth*pixelWidth;
segments = floor(imageWidth/(micrometerSections/pixelWidth));
localFractionWidth = imageWidth/segments;
localFractionsX = newArray(pow(segments*2, 2));
localFractionsY = newArray(pow(segments*2, 2));
localFracStd = newArray(pow(segments*2, 2));
localFracMean = newArray(pow(segments*2, 2));
count = 0;
Stack.setChannel(2);
for (x = 0; x < segments; x = x + 0.5) {
	for (y = 0; y < segments; y = y + 0.5) {
		X = x*localFractionWidth;
		Y = y*localFractionWidth;
		makeRectangle(X, Y, localFractionWidth, localFractionWidth);
		run("Measure");
		localFractionsX[count] = X + 0.5*localFractionWidth;
		localFractionsY[count] = Y + 0.5*localFractionWidth;
		localFracStd[count] = getResult("StdDev", 0);
		//--->
		localFracMean[count] = getResult("Mean", 0);
		count++;
		run("Clear Results");
	}
}

///////////////////////////LocalFractionsVC
micrometerSectionsVC = 45;
if (imageWidth*pixelWidth < micrometerSectionsVC) micrometerSectionsVC = imageWidth*pixelWidth;
segmentsVC = floor(imageWidth/(micrometerSectionsVC/pixelWidth));
localFractionWidthVC = imageWidth/segmentsVC;
localFractionsXVC = newArray(pow(segmentsVC*2, 2));
localFractionsYVC = newArray(pow(segmentsVC*2, 2));
localFracStdVC = newArray(pow(segmentsVC*2, 2));
//--->
localFracMeanVC = newArray(pow(segmentsVC*2, 2));
count = 0;
Stack.setChannel(1);
for (x = 0; x < segmentsVC; x = x + 0.5) {
	for (y = 0; y < segmentsVC; y = y + 0.5) {
		X = x*localFractionWidthVC;
		Y = y*localFractionWidthVC;
		makeRectangle(X, Y, localFractionWidthVC, localFractionWidthVC);
		run("Measure");
		localFractionsXVC[count] = X + 0.5*localFractionWidthVC;
		localFractionsYVC[count] = Y + 0.5*localFractionWidthVC;
		localFracStdVC[count] = getResult("StdDev", 0);
		//--->
		localFracMeanVC[count] = getResult("Mean", 0);
		count++;
		run("Clear Results");
	}
}
///////////////////////////LocalFractionsVC^
///////////////////////////LocalFractionsOverlapTestingVC

micrometerSectionsOTvc = 1;
segmentsOT = floor(imageWidth/(micrometerSectionsOTvc/pixelWidth));//how many pieces image is split into
divisorVC = imageWidth / segmentsOT;
//check magnitude of segments number:
for (i = 1; i < 1000; i++) {
	num = 1;
	for (ii = 1; ii <= i; ii++) {
		num = num * 10;
	}
	if (segmentsOT/num < 1) {
		magnitudeVC = num;
		i = 1000;
	}
}
yStepVC = 1/magnitudeVC;
///////////////////////////LocalFractionsOverlapTestingVC^
///////////////////////////LocalFractionsOverlapTestingAZ

micrometerSectionsOTaz = 0.25;
segmentsOT = floor(imageWidth/(micrometerSectionsOTaz/pixelWidth));//how many pieces image is split into
divisorAZ = imageWidth / segmentsOT;
//check magnitude of segments number:
for (i = 1; i < 1000; i++) {
	num = 1;
	for (ii = 1; ii <= i; ii++) {
		num = num * 10;
	}
	if (segmentsOT/num < 1) {
		magnitudeAZ = num;
		i = 1000;
	}
}
yStepAZ = 1/magnitudeAZ;
///////////////////////////LocalFractionsOverlapTestingAZ^

//setBatchMode("exit and display");
//setBatchMode("hide");

////////////////////////////////////////////////////////////////////////////////////////////////v
//Creates ROIs for VC then use the final ROIs to create an image with values of 255 filled in//


selectWindow(originalTitle);
for (i = 0; i < 5; i++) {
	Stack.setChannel(i);
	setMinAndMax(0, 255);
}
getPixelSize(unit, pixelWidth, pixelHeight);
run("Select All");
run("Duplicate...", "duplicate channels=1");
rename("VC Window");
vcTempTitle = getTitle();
getStatistics(area, mean, min, max, std);

run("Gaussian Blur...", "sigma=0.05 scaled");
run("Set Measurements...", "mean redirect=None decimal=0");
//Stime = getTime();
for (i = 3.5; i >= 1; i = i - 0.5) {
	run("Find Maxima...", "prominence="+ (std*i) +" exclude output=[Maxima Within Tolerance]");
	run("Select None");
	run("Analyze Particles...", "size=" + toString(minimumVCarea) + "-" + toString(maximumVCarea) + " exclude include" + " add");
	close();
	selectWindow(vcTempTitle);
	run("Select None");
}

RoiC = roiManager("count");
roiSlope = newArray(RoiC);
for (j = 0; j < RoiC ; j++) {
	run("Clear Results");
	roiManager("select", j);
	getSelectionCoordinates(xpoints, ypoints);
	run("Enlarge...", "enlarge=-0.05");
	getSelectionCoordinates(sxpoints, sypoints);
	roiManager("select", j);
	run("Enlarge...", "enlarge=0.05");
	getSelectionCoordinates(lxpoints, lypoints);

	
	sXpoints = Array.concat(xpoints,sxpoints);
	sYpoints = Array.concat(ypoints,sypoints);
	lXpoints = Array.concat(xpoints,lxpoints);
	lYpoints = Array.concat(ypoints,lypoints);
	makeSelection("freehand", sXpoints, sYpoints);
	run("Measure");
	makeSelection("freehand", lXpoints, lYpoints);
	run("Measure");
	
	edgeSlope = getResult("Mean", 0) - getResult("Mean", 1);
	roiSlope[j] = edgeSlope;
}

run("Set Measurements...", "mean standard centroid redirect=None decimal=3");
roiCentroidX = newArray(RoiC);
roiCentroidY = newArray(RoiC);
ROIsToDeleteArray = newArray(RoiC);
for (j = 0; j < RoiC; j++) {
	run("Clear Results");
	roiManager("select", j);
	roiManager("measure");
	x1 = getResult("X", 0)/pixelWidth;
	y1 = getResult("Y", 0)/pixelWidth;
	roiCentroidX[j] = x1;
	roiCentroidY[j] = y1;
	mean = getResult("Mean", 0);
	stdDev =  getResult("StdDev", 0);
	for (ii = 0; ii < localFractionsXVC.length; ii++) {
		x2 = localFractionsXVC[ii];
		y2 = localFractionsYVC[ii];
		distanceLength = (sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
		if (distanceLength <= sqrt(2*pow(localFractionWidthVC * 0.5, 2))){
			localStd = localFracStdVC[ii];
			localMean = localFracMeanVC[ii];
			ii = localFractionsXVC.length;
		}
	}
	if ((mean - stdDev) < (localMean + localStd) || isNaN(roiSlope[j])) {
		ROIsToDeleteArray[j] = 1;
	}
}

roiSection = newArray(RoiC);
for (j = 0; j < RoiC; j++) {
	if (ROIsToDeleteArray[j] == 1) continue;
	x1 = roiCentroidX[j];
	y1 = roiCentroidY[j];
	roiSection[j] = round(x1 / divisorVC) + ((round(y1 / divisorVC)) / magnitudeVC);
}

//print(RoiC);
counti = 0;
tempROIIndex = newArray(0);
for (i = 0; i < ROIsToDeleteArray.length; i++) {
	if (ROIsToDeleteArray[i] == 0) tempROIIndex[counti++] = i;
}
//print(counti);
print("\\Update4:||||                  |");
//counter = 0;
//posCounter = 0;
roiManager("deselect");
//before = getTime();
for (j = 0; j < counti; j++) {
	jIndex = tempROIIndex[j];
	loop1Segment = roiSection[jIndex];
	for (jj = j+1; jj < counti; jj++) {
		jjIndex = tempROIIndex[jj];
		if (ROIsToDeleteArray[jjIndex] == 1) continue;
		loop2Segment = roiSection[jjIndex];
		if (loop1Segment == loop2Segment || loop1Segment == loop2Segment - 1 || loop1Segment == loop2Segment + 1 
			|| loop1Segment == loop2Segment + yStepVC || loop1Segment == loop2Segment - 1 + yStepVC || loop1Segment == loop2Segment + 1 + yStepVC
			|| loop1Segment == loop2Segment - yStepVC || loop1Segment == loop2Segment - 1 - yStepVC || loop1Segment == loop2Segment + 1 - yStepVC){
			if (abs(roiCentroidX[jIndex] - roiCentroidX[jjIndex]) < (0.2/pixelWidth) && abs(roiCentroidY[jIndex] - roiCentroidY[jjIndex]) < (0.2/pixelWidth)) pass = 1;
			else {
				pass = 0;
				roiManager("select", newArray(jIndex,jjIndex));
				roiManager("AND");
//				counter++;
			}
		    if (pass == 1 || selectionType > -1) {
//		    	if (pass == 0) posCounter++;
		    	competingES = roiSlope[jjIndex];
		    	edgeSlope = roiSlope[jIndex];
		    	if (competingES > edgeSlope){
		    		ROIsToDeleteArray[jIndex] = 1;
		    		jj = counti;
		    	}
		    	else if (competingES <= edgeSlope){
		    		ROIsToDeleteArray[jjIndex] = 1;
		    	}
		    }
		}
	}
}
//print(toString((getTime() - before)/1000));
//print("counter:" + toString(counter) + " and " + toString(posCounter));
//waitForUser("x");
print("\\Update4:|||||||                |");

roiManager("deselect");
for (j = RoiC - 1; j >= 0; j--) {
	if (ROIsToDeleteArray[j] == 1){
		roiManager("select", j);
		roiManager("delete");
	}
}

	
selectWindow(vcTempTitle);

RoiC = roiManager("count");
run("Select All");
setBackgroundColor(0, 0, 0);
run("Clear", "slice");
vcImageTitle = getTitle();

roiManager("deselect");
setForegroundColor(255, 255, 255);
roiManager("fill");
roiManager("reset");
run("Select None");


//setBatchMode("show all");
//run("To ROI Manager");
//////////////////////////////////////////////////////////////////////////////////////^
//exit();



////////////////////////////////////////////////////////////////////////////////////////////////v
//Creates ROIs for AZ to create ROIs//


selectWindow(originalTitle);
getPixelSize(unit, pixelWidth, pixelHeight);
run("Select All");
run("Duplicate...", "duplicate channels=2");
rename("AZ Window");
azImageTitle = getTitle();
getStatistics(area, mean, min, max, std);

run("Gaussian Blur...", "sigma="+ toString(0.03) +" scaled");
lastRoiC = 0;

//Stime = getTime();
for (i = 3.5; i >= 1; i = i - 0.5) {
	run("Find Maxima...", "prominence="+ (std*i) +" exclude output=[Maxima Within Tolerance]");
	run("Select None");
	run("Analyze Particles...", "size=" + "0.02-1" + " exclude include" + " add");
	close();
	selectWindow(azImageTitle);
	run("Select None");
}
print("\\Update4:||||||||||              |");

RoiC = roiManager("count");
run("Set Measurements...", "mean standard centroid redirect=None decimal=3");
roiCentroidX = newArray(RoiC);
roiCentroidY = newArray(RoiC);
ROIsToDeleteArray = newArray(RoiC);
var surroundingMean;
surroundingMean =  newArray(RoiC);
var surroundingStDv;
surroundingStDv = newArray(RoiC);
var AZarea;
AZarea = newArray(RoiC);
var AZmean;
AZmean = newArray(RoiC);
var AZstDv;
AZstDv = newArray(RoiC);
for (j = 0; j < RoiC; j++) {
	run("Clear Results");
	roiManager("select", j);
	roiManager("measure");
	x1 = getResult("X", 0)/pixelWidth;
	y1 = getResult("Y", 0)/pixelWidth;
	roiCentroidX[j] = x1;
	roiCentroidY[j] = y1;
	mean = getResult("Mean", 0);
	stdDev =  getResult("StdDev", 0);
	for (ii = 0; ii < localFractionsX.length; ii++) {
		x2 = localFractionsX[ii];
		y2 = localFractionsY[ii];
		distanceLength = sqrt(pow((x2-x1), 2) + pow((y2-y1),2));
		if (distanceLength <= sqrt(2*pow(localFractionWidth * 0.5, 2))){
			localStd = localFracStd[ii];
			localMean = localFracMean[ii];
			ii = localFractionsX.length;
		}
	}
	
	if ((mean - stdDev) < (localMean + localStd)) {
		ROIsToDeleteArray[j] = 1;
	}
	else {
		surroundingMean[j] = localMean;
		AZmean[j] = mean;
		surroundingStDv[j] = localStd;
		AZstDv[j] = stdDev;
		run("Set Measurements...", "area redirect=None decimal=3");
		run("Clear Results");
		roiManager("select", j);
		roiManager("measure");
		AZarea[j] = getResult("Area", 0);
		run("Set Measurements...", "mean standard centroid redirect=None decimal=3");
	}
}
print("\\Update4:|||||||||||||            |");


run("Set Measurements...", "mean redirect=None decimal=0");
roiSlope = newArray(RoiC);
for (j = 0; j < RoiC ; j++) {
	if (ROIsToDeleteArray[j] == 1) continue;
	run("Clear Results");
	roiManager("select", j);
	getSelectionCoordinates(xpoints, ypoints);
	run("Enlarge...", "enlarge=-0.05");
	getSelectionCoordinates(sxpoints, sypoints);
	roiManager("select", j);
	run("Enlarge...", "enlarge=0.05");
	getSelectionCoordinates(lxpoints, lypoints);

	
	sXpoints = Array.concat(xpoints,sxpoints);
	sYpoints = Array.concat(ypoints,sypoints);
	lXpoints = Array.concat(xpoints,lxpoints);
	lYpoints = Array.concat(ypoints,lypoints);
	makeSelection("freehand", sXpoints, sYpoints);
	run("Measure");
	makeSelection("freehand", lXpoints, lYpoints);
	run("Measure");
	
	edgeSlope = getResult("Mean", 0) - getResult("Mean", 1);
	if (isNaN(edgeSlope)) ROIsToDeleteArray[j] = 1;
	else roiSlope[j] = edgeSlope;
}

roiSection = newArray(RoiC);
for (j = 0; j < RoiC; j++) {
	if (ROIsToDeleteArray[j] == 1) continue;
	x1 = roiCentroidX[j];
	y1 = roiCentroidY[j];
	roiSection[j] = round(x1 / divisorAZ) + ((round(y1 / divisorAZ)) / magnitudeAZ);
}


//print(RoiC);
counti = 0;
tempROIIndex = newArray(0);
for (i = 0; i < ROIsToDeleteArray.length; i++) {
	if (ROIsToDeleteArray[i] == 0) tempROIIndex[counti++] = i;
}
//print(counti);
print("\\Update4:||||||||||||||||          |");

//counter = 0;
//posCounter = 0;
roiManager("deselect");
//before = getTime();
for (j = 0; j < counti; j++) {
	jIndex = tempROIIndex[j];
	loop1Segment = roiSection[jIndex];
	for (jj = j+1; jj < counti; jj++) {
		jjIndex = tempROIIndex[jj];
		if (ROIsToDeleteArray[jjIndex] == 1) continue;
		loop2Segment = roiSection[jjIndex];
		if (loop1Segment == loop2Segment || loop1Segment == loop2Segment - 1 || loop1Segment == loop2Segment + 1 
			|| loop1Segment == loop2Segment + yStepAZ || loop1Segment == loop2Segment - 1 + yStepAZ || loop1Segment == loop2Segment + 1 + yStepAZ
			|| loop1Segment == loop2Segment - yStepAZ || loop1Segment == loop2Segment - 1 - yStepAZ || loop1Segment == loop2Segment + 1 - yStepAZ){
			if (abs(roiCentroidX[jIndex] - roiCentroidX[jjIndex]) < (0.2/pixelWidth) && abs(roiCentroidY[jIndex] - roiCentroidY[jjIndex]) < (0.2/pixelWidth)) pass = 1;
			else {
				pass = 0;
				roiManager("select", newArray(jIndex,jjIndex));
				roiManager("AND");
//				counter++;
			}
		    if (pass == 1 || selectionType > -1) {
//		    	if (pass == 0) posCounter++;
		    	competingES = roiSlope[jjIndex];
		    	edgeSlope = roiSlope[jIndex];
		    	if (competingES > edgeSlope){
		    		ROIsToDeleteArray[jIndex] = 1;
		    		jj = counti;
		    	}
		    	else if (competingES <= edgeSlope){
		    		ROIsToDeleteArray[jjIndex] = 1;
		    	}
		    }
		}
	}
}
//print(toString((getTime() - before)/1000));
//print("counter:" + toString(counter) + " and " + toString(posCounter));
//waitForUser("x");
selectWindow(azImageTitle);
close();
print("\\Update4:|||||||||||||||||||        |");

RoiC = roiManager("count");
closeIfZero(RoiC);

//setBatchMode("show all");
//run("To ROI Manager");
//////////////////////////////////////////////////////////////////////////////////////^
//exit();


selectWindow(vcImageTitle);

run("Set Measurements...", "fit redirect=None decimal=5");
roiManager("deselect");

selectWindow("Results");
setLocation(-1000, -1000);

var ROIindexConversion = newArray(0);
count = 0;
for (j = 0; j < RoiC; j++) {
	if (ROIsToDeleteArray[j] == 1) continue;
	run("Clear Results");
	roiManager("select", j);
	roiManager("measure");
	centroidX = roiCentroidX[j];
	centroidY = roiCentroidY[j];
	majorLength = (getResult("Major", 0))/pixelWidth;
	minorLength = (getResult("Minor", 0))/pixelWidth;
	ellipseAngle = getResult("Angle", 0);
	if (majorLength >= minimumAZlength && minorLength < maximumAZwidth && majorLength/minorLength > AZaspectRatioMin){
		makeLineC (centroidX, centroidY, majorLength, minorLength, ellipseAngle);
		roiManager("add");
		ROIindexConversion[count++] = j;
	}
}
run("Clear Results");
print("\\Update4:||||||||||||||||||||||      |");

//roiManager("Select", Array.getSequence(RoiC));
//roiManager("delete");

tempRoiC = roiManager("count");
tempArray = Array.getSequence(tempRoiC);
indexes = Array.slice(tempArray,RoiC,tempRoiC);
if(File.exists(path + "ROIs.zip")) deletesuccess = File.delete(path + "ROIs.zip");
roiManager("select", indexes);
roiManager("save selected", path + "ROIs.zip");
roiManager("reset");
roiManager("open", path + "ROIs.zip");


var originalRoiC;
originalRoiC = RoiC;
RoiC = roiManager("count");
closeIfZero(RoiC);

var VCdepth = newArray(originalRoiC);
var distanceFromEdge = newArray(originalRoiC);
var distanceFromCenter = newArray(originalRoiC);
var VCcenterX = newArray(originalRoiC);
var VCcenterY = newArray(originalRoiC);
var VCarea = newArray(originalRoiC);
var VCmean = newArray(originalRoiC);
var VCstDv = newArray(originalRoiC);


selectWindow(originalTitle);
run("Select All");
run("Duplicate...", "duplicate channels=1");
rename("VC Original Channel");
vcOriginalChannelTitle = getTitle();
selectWindow(vcImageTitle);


run("Set Measurements...", "mean standard area redirect=None decimal=3");
for (j = 0; j < RoiC; j++) {
	run("Clear Results");
	if (ROIsToDeleteArray[ROIindexConversion[j]] == 1) continue;
	roiManager("select", j);
	run("Rotate...", "  angle=90");
	roiManager("add");
	
	roiManager("select", RoiC);
	getLine(x1, y1, x2, y2, lineWidth);
	lineHalfWidth = (lineWidth * pixelWidth) / 2;
	if (!isNaN(scanningFraction)){
		lineLength = (sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
		changeLength(x1, y1, x2, y2, scanLineLength, (lineLength*scanningFraction));
	}
	else changeLength(x1, y1, x2, y2, scanLineLength, scanningMicrometers);
	profileInitial = getProfile();
	halfPoint = round(profileInitial.length/2);

	currentROIdistance = NaN;
	trigger = 0;
	VCmeasurement = 0;
	rotateROI = 0;
	innerROI = 0;

	for (i = 1; i < halfPoint - 1; i++) {
		if (trigger == 0){
			inPoint = profileInitial[halfPoint - i];
			outPoint = profileInitial[halfPoint + i];
			if (inPoint < 60 && outPoint < 60) continue;
			else if (inPoint > 180 && outPoint > 180){
				VCmeasurement = VCmeasurement++;
				continue;
			}
			else if (inPoint < 60 && outPoint > 180){
				VCmeasurement++;
				currentROIdistance = i*pixelWidth;
				rotateROI = 1;
				trigger = 1;
			}
			else if (inPoint > 180 && outPoint < 60){
				VCmeasurement++;
				currentROIdistance = i*pixelWidth;
				trigger = 1;
			}
		}
		else{
			if (rotateROI == 0) inPoint = profileInitial[halfPoint - i];
			else inPoint = profileInitial[halfPoint + i];
			
			if (inPoint < 180){
				i = halfPoint;
				continue;
			}
			else VCmeasurement++;
		}
	}

	negOrPos = 1;
	if (profileInitial[halfPoint] > 50) {
		VCmeasurement++;
		distanceEval = maxInnerEdgeDistance;
		negOrPos = -1;
	}
	else distanceEval = maxOuterEdgeDistance;
	
	VCmeasurement = VCmeasurement*pixelWidth;

	roiManager("select", RoiC);
	getLine(x1, y1, x2, y2, lineWidth);
	midPointX = (x1 + x2)/2;
	midPointY = (y1 + y2)/2;
	if (rotateROI == 1) {
		endX = x2;
		endY = y2;
	}
	else {
		endX = x1;
		endY = y1;
	}
	lineLength = scanLineLength;
	roiManager("delete");
	
	if (isNaN(currentROIdistance) || (currentROIdistance - (negOrPos * lineHalfWidth)) >  distanceEval || VCmeasurement < minimumVClength){
		if (debugmode == 1) print("VC:"+toString(VCmeasurement)+"Dist:"+toString(currentROIdistance));
		ROIsToDeleteArray[ROIindexConversion[j]] = 1;
		continue;
	}
	
	if (rotateROI == 1){
		roiManager("select", j);
		run("Rotate...", "  angle=180");
		roiManager("update");
	}
	VCdepth[ROIindexConversion[j]] = VCmeasurement;
	distanceFromEdge[ROIindexConversion[j]] = negOrPos * (currentROIdistance - (negOrPos * lineHalfWidth));
	distanceFromCenter[ROIindexConversion[j]] = negOrPos * (currentROIdistance);
	wandFractionFromCenter = ((negOrPos * currentROIdistance) + (VCmeasurement/2))/(lineLength/2); //unit = fraction of line from center
	
	if (midPointX < endX){
		VCcenterX[ROIindexConversion[j]] = midPointX + (abs(midPointX - endX))*wandFractionFromCenter;
	}
	else if (midPointX == endX){
		VCcenterX[ROIindexConversion[j]] = midPointX;
	}
	else {
		VCcenterX[ROIindexConversion[j]] = midPointX - (abs(midPointX - endX))*wandFractionFromCenter;
	}
	
	if (midPointY < endY){
		VCcenterY[ROIindexConversion[j]] = midPointY + (abs(midPointY - endY))*wandFractionFromCenter;
	}
	else if (midPointY == endY){
		VCcenterY[ROIindexConversion[j]] = midPointY;
	}
	else {
		VCcenterY[ROIindexConversion[j]] = midPointY - (abs(midPointY - endY))*wandFractionFromCenter;
	}

	doWand(VCcenterX[ROIindexConversion[j]], VCcenterY[ROIindexConversion[j]], 0.0, "4-connected");
	if (selectionType() != -1){
		getSelectionCoordinates(xpoints, ypoints);
		selectWindow(vcOriginalChannelTitle);
		makeSelection("freehand", xpoints, ypoints);
		run("Measure");
		VCarea[ROIindexConversion[j]] = getResult("Area", 0);
		VCmean[ROIindexConversion[j]] = getResult("Mean", 0);
		VCstDv[ROIindexConversion[j]] = getResult("StdDev", 0);
		selectWindow(vcImageTitle);
	}
	else {
		print("Shouldn't be possible, but ROI#" + toString(j) + " associated vesicle cloud couldn't be identified, so it was deleted");
		ROIsToDeleteArray[ROIindexConversion[j]] = 1;
	}

}
print("\\Update4:|||||||||||||||||||||||||    |");

selectWindow(vcOriginalChannelTitle);
close();

var ROIindex2ndConversion = newArray(0);
count = 0;
for (j = 0; j < RoiC; j++) {
	if (ROIsToDeleteArray[ROIindexConversion[j]] == 0){
		ROIindex2ndConversion[count++] = ROIindexConversion[j];
	}
}

roiManager("deselect");
for (j = RoiC - 1; j >= 0; j--) {
	if (ROIsToDeleteArray[ROIindexConversion[j]] == 1){
		roiManager("select", j);
		roiManager("delete");
	}
}
RoiC = roiManager("count");


selectWindow(originalTitle);
var pixelShift;
pixelShift = newArray(RoiC);
for (j = 0; j < RoiC; j++) {
	roiManager("select", j);
	getLine(x1, y1, x2, y2, Width);
	run("Rotate...", "  angle=90");
	getLine(x3, y3, x4, y4, na);
	roiManager("add");
	roiManager("select", RoiC);
	lineLength = pixelWidth*(sqrt(pow((x4-x3), 2) + pow((y4-y3),2)));
	F = (finalLength-lineLength)/2;
	F = F/lineLength;
	makeLine((x3+F*(x3-x4)), (y3+F*(y3-y4)), (x4+F*(x4-x3)), (y4+F*(y4-y3)));
	roiManager("update");
	Roi.setStrokeWidth(finalWidth);
	roiManager("update");
	Stack.setPosition(2, 0, 0);
	profile = getProfile();
	roiManager("select", RoiC);
	getLine(x3, y3, x4, y4, na);
	roiManager("delete");
	
	rollingAvgProfile = profile;
	for (i = 2; i < rollingAvgProfile.length - 2; i++) {
		rollingAvgProfile[i] = (profile[i-2] + profile[i-1] + profile[i] + profile[i+1] + profile[i+2]) / 5;
	}

	tempRollingAvgProfile = Array.slice(rollingAvgProfile,((rollingAvgProfile.length * 0.5) - (0.2 / pixelWidth)),((rollingAvgProfile.length * 0.5) + (0.2 / pixelWidth)));
	Array.getStatistics(tempRollingAvgProfile, min2, max2, mean2, na);
	profile2Max = Array.findMaxima(rollingAvgProfile, (0.4 * (max2 - min2)), 0);
	if (profile2Max.length == 0) profile2Max = newArray(0,0,0);
	
	if (profile2Max.length > 1) {
		stop = 0;
		if ((profile2Max[0] > ((rollingAvgProfile.length * 0.5) + (0.2 / pixelWidth))) || (profile2Max[0] < ((rollingAvgProfile.length * 0.5) - (0.2 / pixelWidth)))){
			for (ii = 1; ii < profile2Max.length; ii++) {
				if ((profile2Max[ii] < ((rollingAvgProfile.length * 0.5) + (0.2 / pixelWidth))) && (profile2Max[ii] > ((rollingAvgProfile.length * 0.5) - (0.2 / pixelWidth))) && stop == 0){
					holdVar = profile2Max[0];
					max2 = rollingAvgProfile[profile2Max[ii]];
					profile2Max[0] = profile2Max[ii];
					profile2Max[ii] = holdVar;
					stop = 1;
				}
			}
		}
	}
	else if (profile2Max.length <= 1) {
		if ((profile2Max[0] > ((rollingAvgProfile.length * 0.5) + (0.2 / pixelWidth))) || (profile2Max[0] < ((rollingAvgProfile.length * 0.5) - (0.2 / pixelWidth)))){
			profile2Max[0] = round(rollingAvgProfile.length * 0.5);
		}
	}
	pixelShift[j] = profile2Max[0] - (rollingAvgProfile.length * 0.5);

	roiManager("select", j);
	shiftLine (x1, y1, x2, y2, x3, y3, x4, y4, pixelShift[j], Width);
}

print("\\Update4:||||||||||||||||||||||||||||  |");

if (individualmode == 1) {
	roiManager("show all");
	setBatchMode("show all");
	selectWindow(originalTitle);
	for (j = 0; j < RoiC; j++) {
		printStuff(j);	
	}
	if (RoiC > 0) {
		run("To ROI Manager");
		waitForUser("Done!");
	}
	else print("No ROIs");
}
else {
	selectWindow(vcImageTitle);
	close();
	selectWindow(originalTitle);
	if(File.exists(path + "ROIs.zip")) deletesuccess = File.delete(path + "ROIs.zip");
	if (roiManager("count") > 0){
		roiManager("deselect");
		roiManager("save", path + "ROIs.zip");
		analyzeROIs(path, originalTitle);
		roiManager("reset");
	}
	else //print("All ROIs filtered from" + originalTitle);
	selectWindow(originalTitle);
	close();
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////functions

function closeIfZero (RoiCount) {
	if (RoiCount == 0) {
		run("Close All");
		exit();
	}
}

function makeLineC (centerX, centerY, length, width, angle) {
    angle = -angle * PI / 180;
    dX = cos(angle) * length / 2;
    dY = sin(angle) * length / 2;

    makeLine(centerX - dX, centerY - dY, centerX + dX, centerY + dY, width);
}

function changeLength (x1, y1, x2, y2, newLength, newWidth){
	Width = newWidth/pixelWidth;
	lineLength = (sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
	tempLength = newLength/pixelWidth;
	F = tempLength/2 - lineLength/2;
	F = F/lineLength;
	makeLine((x1+F*(x1-x2)), (y1+F*(y1-y2)), (x2+F*(x2-x1)), (y2+F*(y2-y1)), Width);
	roiManager("update");
}

function shiftLine (x1, y1, x2, y2, x3, y3, x4, y4, pixShift, Width){
	lineLength = (sqrt(pow((x4-x3), 2) + pow((y4-y3),2)));
	F = pixShift/lineLength;
	makeLine((x1-F*(x3-x4)), (y1-F*(y3-y4)), (x2+F*(x4-x3)), (y2+F*(y4-y3)), Width);
	roiManager("update");
}


function analyzeROIs(ROIpath, imageTitle){
	// Analyze and save ROI data -----------------------------------------------------------------------------
	run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column save_row");
	selectWindow(imageTitle);
	getPixelSize(unit, pixelWidth, pixelHeight);
	getDimensions(width, height, channels, slices, frames);
	
	
	RoiC = roiManager("count");
	run("Set Measurements...", "mean modal centroid redirect=None decimal=3");
	run("Clear Results");
	roiManager("deselect");
	roiManager("multi-measure");
	
	setOption("ExpandableArrays", true);
	profile1 = newArray(0);
	profile2 = newArray(0);
	profile3 = newArray(0);
	indexEnd1 = newArray(RoiC+1);
	indexEnd1[0] = -1;
	halfMaxWidthVM = newArray(RoiC);
	halfMaxWidthAZ = newArray(RoiC);
	maxVM = newArray(RoiC);
	maxAZ = newArray(RoiC); 
	overlap = newArray(RoiC);
	halfMaxWidthVMminusOverlap = newArray(RoiC);
	noiseVM = newArray(RoiC);
	noiseAZ = newArray(RoiC);
	lengthArray = newArray(RoiC);
	for (i = 0; i < RoiC; i++){
		showProgress(i, RoiC-1);
		extraPeak = 0;
		roiManager("select", i);
		run("Rotate...", "  angle=90");
		roiManager("add");
		Stack.setPosition(1, 0, 0);
		roiManager("select", RoiC);
		getLine(x1, y1, x2, y2, lineWidth);
		lineLength = pixelWidth*(sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
		lengthArray[i] = lineLength;
		F = (finalLength-lineLength)/2;
		F = F/lineLength;
		makeLine((x1+F*(x1-x2)), (y1+F*(y1-y2)), (x2+F*(x2-x1)), (y2+F*(y2-y1)));
		roiManager("update");
		Roi.setStrokeWidth(finalWidth);
		roiManager("update");
		roiManager("select", RoiC);
		Stack.setPosition(1, 0, 0);
		profileTemp1 = getProfile();

		profile1 = Array.concat(profile1, profileTemp1);
		indexEnd1[i + 1] = profile1.length;
		
		roiManager("select", RoiC);
		Stack.setPosition(2, 0, 0);
		profileTemp2 = getProfile();
		profile2 = Array.concat(profile2, profileTemp2);

		roiManager("select", RoiC);
		Stack.setPosition(3, 0, 0);
		profileTemp3 = getProfile();
		profile3 = Array.concat(profile3, profileTemp3);
		
		roiManager("select", RoiC);
		roiManager("delete");
		
		//Calculate Half Max Width of profile1 & profile2
		tempAvgProfile = Array.slice(profileTemp2,((profileTemp2.length * 0.5) - (0.2 / pixelWidth)),((profileTemp2.length * 0.5) + (0.2 / pixelWidth)));
		Array.getStatistics(tempAvgProfile, null, max2, null1, null2);
		
		Array.getStatistics(profileTemp1, min1, max1, mean1, stdDev);
		Array.getStatistics(profileTemp2, min2, null, mean2, stdDev);
		profile1Max = Array.findMaxima(profileTemp1, 10, 0);
		profile2Max = Array.findMaxima(profileTemp2, (0.4 * (max2 - min2)), 0);
		if (profile1Max.length == 0) profile1Max = newArray(0,0,0);
		if (profile2Max.length == 0) profile2Max = newArray(0,0,0);

		
		if (profile2Max.length > 1) {
			count = 1;
			stop = 0;
			if ((profile2Max[0] > ((profileTemp2.length * 0.5) + (0.2 / pixelWidth))) || (profile2Max[0] < ((profileTemp2.length * 0.5) - (0.2 / pixelWidth)))){
				for (ii = 1; ii < profile2Max.length; ii++) {
					if ((profile2Max[ii] < ((profileTemp2.length * 0.5) + (0.2 / pixelWidth))) && (profile2Max[ii] > ((profileTemp2.length * 0.5) - (0.2 / pixelWidth))) && stop == 0){
						holdVar = profile2Max[0];
						max2 = profileTemp2[profile2Max[ii]];
						profile2Max[0] = profile2Max[ii];
						profile2Max[ii] = holdVar;
						if ((profile2Max[ii] < ((profileTemp2.length * 0.5) - (0.2 / pixelWidth)))) extraPeak = count++;
						stop = 1;
					}
					else if ((profile2Max[ii] < ((profileTemp2.length * 0.5) - (0.2 / pixelWidth)))) extraPeak = count++;
				}
			}
			else {
				for (ii = 1; ii < profile2Max.length; ii++) {
					if ((profile2Max[ii] < ((profileTemp2.length * 0.5) - (0.2 / pixelWidth)))){
						extraPeak = count++;
					}
				}
			}
		}
		else if (profile2Max.length <= 1) {
			if ((profile2Max[0] > ((profileTemp2.length * 0.5) + (0.2 / pixelWidth))) || (profile2Max[0] < ((profileTemp2.length * 0.5) - (0.2 / pixelWidth)))){
				profile2Max[0] = round (profileTemp2.length * 0.5);
			}
		}
		
		
		halfMax1 = newArray(2);
		stopVar = 0;
		for (ii = profile1Max[0]; ii <= profileTemp1.length - 1; ii++) {
			if ((profileTemp1[ii] <= ((0.5 * (max1 - min1)) + min1) || ii == profileTemp1.length - 1) && stopVar == 0){
				halfMax1[0] = ii;
				if (ii >= profileTemp1.length/2)  overlapTemp = abs(ii - round(profileTemp1.length/2));
				else overlapTemp = 0;
				stopVar = 1;
			}
		}
		stopVar = 0;
		for (ii = profile1Max[0]; ii >= 0; ii--) {
			if ((profileTemp1[ii] <= ((0.5 * (max1 - min1)) + min1) || ii == 0) && stopVar == 0){
				halfMax1[1] = ii;
				stopVar = 1;
			}
		}
		
		halfMax2 = newArray(2);
		stopVar = 0;
		for (ii = profile2Max[0]; ii < profileTemp2.length - 1; ii++) {
			if ((profileTemp2[ii] <= ((0.5 * (max2 - min2)) + min2) || ii == profileTemp2.length-1) && stopVar == 0){
				halfMax2[0] = ii;
				stopVar = 1;
			}
		}
		stopVar = 0;
		for (ii = profile2Max[0]; ii >= 0; ii--) {
			if ((profileTemp2[ii] <= ((0.5 * (max2 - min2)) + min2) || ii == 0) && stopVar == 0){
				halfMax2[1] = ii;
				stopVar = 1;
			}
		}

		for (ii = profileTemp1.length-1; ii >= 0; ii--) {
			if (profileTemp1[ii] == 0) {
				profileTemp2[ii] = NaN;
			}
			else ii = -1;
		}
		for (ii = profileTemp2.length-1; ii >= 0; ii--) {
			if (profileTemp2[ii] == 0) {
				profileTemp2[ii] = NaN;
			}
			else ii = -1;
		}
		
		noisevm = 0;
		counter1 = 0;
		for (ii = halfMax1[0]; ii <= profileTemp1.length-1; ii++) {
			if (!isNaN(profileTemp1[ii])) {
				noisevm = profileTemp1[ii] + noisevm;
				counter1++;
			}
		}
		noiseaz = 0;
		counter2 = 0;
		for (ii = halfMax2[0]; ii < profileTemp2.length-1; ii++) {
			if (!isNaN(profileTemp2[ii])) {
				noiseaz = profileTemp2[ii] + noiseaz;
				counter2++;
			}
		}
		for (ii = halfMax2[1] - 1; ii >= 0; ii--) {
			if (!isNaN(profileTemp2[ii])) {
				noiseaz = profileTemp2[ii] + noiseaz;
				counter2++;
			}
		}
		
		noiseVM[i] = noisevm/counter1;
		noiseAZ[i] = noiseaz/counter2;
		halfMaxWidthVM[i] = (halfMax1[0]-halfMax1[1])*(finalLength / profileTemp1.length);
		halfMaxWidthAZ[i] = (halfMax2[0]-halfMax2[1])*(finalLength / profileTemp2.length);
		overlap[i] = (overlapTemp)*(finalLength / profileTemp1.length);
		halfMaxWidthVMminusOverlap[i] = halfMaxWidthVM[i] - abs(overlap[i]);
		setResult("halfMaxWidthVM", i, halfMaxWidthVM[i]);
		setResult("halfMaxWidthAZ", i, -abs(halfMaxWidthAZ[i]));
		setResult("halfMaxWidthVMminusOverlap", i, halfMaxWidthVMminusOverlap[i]);
		setResult("overlap", i, -abs(overlap[i]));
		setResult("noiseVM", i, -abs(noiseVM[i]));
		setResult("noiseAZ", i, -abs(noiseAZ[i]));
		setResult("Length", i, (lengthArray[i]));
					
		
		//Calculate Distance Between fit peaks
		//Caclulate Distance Between Half point of HalfMax values
		
		//Calculate Height of Vesicle Marker at -___nm

		//Calculate Max to Remove Outliers within Image
		maxVM[i] = max1;
		maxAZ[i] = max2;
		backVM = (profileTemp1[2]/max1);
		setResult("maxVM", i, maxVM[i]);
		setResult("maxAZ", i, maxAZ[i]);
		setResult("backVM", i, backVM);
		setResult("SnVM", i, max1/(noiseVM[i]));
		setResult("SnAZ", i, max2/(noiseAZ[i]));
		setResult("extraPeak", i, -abs(extraPeak));
		setResult("VCarea", i, VCarea[ROIindex2ndConversion[i]]);
		setResult("VCmean", i, VCmean[ROIindex2ndConversion[i]]);
		setResult("VCstDv", i, VCstDv[ROIindex2ndConversion[i]]);
		setResult("surroundingMean", i, surroundingMean[ROIindex2ndConversion[i]]);
		setResult("surroundingStDv", i, surroundingStDv[ROIindex2ndConversion[i]]);
		setResult("AZarea", i, AZarea[ROIindex2ndConversion[i]]);
		setResult("AZmean", i, AZmean[ROIindex2ndConversion[i]]);
		setResult("AZstDv", i, AZstDv[ROIindex2ndConversion[i]]);
		setResult("VCdepth", i, VCdepth[ROIindex2ndConversion[i]]);
		setResult("distanceFromEdge", i, distanceFromEdge[ROIindex2ndConversion[i]]);
		setResult("distanceFromCenter", i, distanceFromCenter[ROIindex2ndConversion[i]] - (pixelShift[i]*pixelWidth));
	}
	
	updateResults();
	selectWindow("Results");
	saveAs("results", saveDirectory + "ROI Data" + File.separator + imageTitle + "ROIinfo.csv");

	print("\\Update4:||||||||||||||||||||||||||||||||");
	run("Clear Results");
	//if exists ROIplots combination file, open it,
	//otherwise we're about to make it
	combinedFolder = saveDirectory + "ROI Data" + File.separator + "Combination" + File.separator;
	if (!File.exists(combinedFolder)) File.makeDirectory(combinedFolder);
	if (File.exists(combinedFolder + "Combined_plots.csv")) run("Results... ", "open=[" + combinedFolder +"Combined_plots.csv]");
	for (i = 0; i < profile1.length; i++) setResult("profile1" + imageTitle, i, profile1[i]);
	for (i = 0; i < profile2.length; i++) setResult("profile2" + imageTitle, i, profile2[i]);
	for (i = 0; i < profile3.length; i++) setResult("profile3" + imageTitle, i, profile3[i]);
	for (i = 0; i < indexEnd1.length; i++) setResult("indexEnd1" + imageTitle, i, indexEnd1[i]);
	selectWindow("Results");
//	saveAs("results", saveDirectory + "ROI Data" + File.separator + imageTitle + "ROIplots.csv");
	saveAs("results", combinedFolder +"Combined_plots.csv");

	roiManager("reset");
}

function printStuff(j) {
	print("ROI#" + toString(j + 1));
	print("VCarea:" + toString(VCarea[ROIindex2ndConversion[j]]));
	print("VCmean:" + toString(VCmean[ROIindex2ndConversion[j]]));
	print("VCstDv:" + toString(VCstDv[ROIindex2ndConversion[j]]));
	print("surroundingMean:" + toString(surroundingMean[ROIindex2ndConversion[j]]));
	print("surroundingStDv:" + toString(surroundingStDv[ROIindex2ndConversion[j]]));
	print("AZarea:" + toString(AZarea[ROIindex2ndConversion[j]]));
	print("AZmean:" + toString(AZmean[ROIindex2ndConversion[j]]));
	print("AZstDv:" + toString(AZstDv[ROIindex2ndConversion[j]]));
	print("VCdepth:" + toString(VCdepth[ROIindex2ndConversion[j]]));
	print("distanceFromEdge:" + toString(distanceFromEdge[ROIindex2ndConversion[j]]));
	print("VCcenterX:" + toString(VCcenterX[ROIindex2ndConversion[j]]));
	print("VCcenterY:" + toString(VCcenterY[ROIindex2ndConversion[j]]));	
}
