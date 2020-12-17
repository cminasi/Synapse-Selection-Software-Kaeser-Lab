minimumVClength = 0.3;
maximumVClength = 2;
minimumVCarea = PI * pow(minimumVClength/2, 2);
maximumVCarea = (PI * pow(maximumVClength/2,2));

run("Clear Results");
setOption("ExpandableArrays", true);
openList = getList("image.titles");
CREMeans = newArray(0);
dCreMeans = newArray(0);

dCrecount = 0;
CREcount = 0;
for (I = 0; I < openList.length; I++) {
	//showProgress(I, openList.length-1);
	
	selectWindow(openList[I]);
	setBatchMode("hide");
	roiManager("reset");
	getPixelSize(unit, pixelWidth, pixelHeight);
	run("Set Measurements...", "mean standard redirect=None decimal=3");
	imageWidth = getWidth();
	///////////////////////////LocalFractionsVC
	micrometerSectionsVC = 45;
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

	///////////////////////////LocalFractionsOverlapTesting
	micrometerSectionsOT = 3;
	segmentsOT = floor(imageWidth/(micrometerSectionsOT/pixelWidth));
	localFractionWidthOT = imageWidth/segmentsOT;
	localFractionsXOT = newArray(pow(segmentsOT*2, 2));
	localFractionsYOT = newArray(pow(segmentsOT*2, 2));
	count = 0;
	Stack.setChannel(1);
	for (x = 0; x < segmentsOT; x = x + 0.5) {
		for (y = 0; y < segmentsOT; y = y + 0.5) {
			X = x*localFractionWidthOT;
			Y = y*localFractionWidthOT;
			localFractionsXOT[count] = X + 0.5*localFractionWidthOT;
			localFractionsYOT[count] = Y + 0.5*localFractionWidthOT;
			count++;
		}
	}
	///////////////////////////LocalFractionsOverlapTesting^
	
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
		if ((mean - stdDev) < (localMean + localStd)) {
			ROIsToDeleteArray[j] = 1;
		}
	}


	RoiC = roiManager("count");
	roiSection = newArray(RoiC);
	for (j = 0; j < RoiC; j++) {
		if (ROIsToDeleteArray[j] == 1) continue;
		x1 = roiCentroidX[j];
		y1 = roiCentroidY[j];
		distanceLength = newArray(localFractionsXOT.length);
		for (ii = 0; ii < localFractionsXOT.length; ii++) {
			x2 = localFractionsXOT[ii];
			y2 = localFractionsYOT[ii];
			distanceLength[ii] = (sqrt(pow((x2-x1), 2) + pow((y2-y1),2)));
			if (ii == 0) minimumIndex = ii;
			else if (distanceLength[ii] < distanceLength[ii-1]) minimumIndex = ii;
		}
		roiSection[j] = minimumIndex;
	}
	//print(Stime - getTime());

	roiManager("deselect");
	for (j = 0; j < RoiC; j++) {
		if (ROIsToDeleteArray[j] == 1) continue;
		for (jj = 0; jj < RoiC; jj++) {
			if (ROIsToDeleteArray[jj] == 0 && j != jj && (roiSection[j] == roiSection[jj] || roiSection[j] == roiSection[jj] - 1
				|| roiSection[j] == roiSection[jj] + 1 || roiSection[j] == roiSection[jj] + segmentsOT 
				|| roiSection[j] == roiSection[jj] - segmentsOT)){
				roiManager("select", newArray(j,jj));
				roiManager("AND");
			    if (selectionType>-1) {
			    	competingES = roiSlope[jj];
			    	edgeSlope = roiSlope[j];
			    	if (competingES > edgeSlope){
			    		ROIsToDeleteArray[j] = 1;
			    		jj = RoiC;
			    	}
			    	else if (competingES < edgeSlope){
			    		ROIsToDeleteArray[jj] = 1;
			    	}
			    }
			}
		}
		lastRoiC = roiManager("count");
	}
	//print(Stime - getTime());
	
	roiManager("deselect");
	for (j = RoiC - 1; j >= 0; j--) {
		if (ROIsToDeleteArray[j] == 1){
			roiManager("select", j);
			roiManager("delete");
		}
	}
	
	selectWindow(vcTempTitle);
//	run("Show Overlay");
//	setBatchMode("show");
//	waitForUser("x");
	close();
	selectWindow(openList[I]);
	run("Duplicate...", "duplicate channels=4");
	rename("Target Window");
	targetTitle = getTitle();
	run("Set Measurements...", "mean redirect=None decimal=5");
	roiManager("deselect");
	roiManager("multi-measure append");
	run("Summarize");
	if (matches(openList[I], ".*CRE.*")) CREMeans[CREcount++] = getResult("Mean", nResults - 4);
	else if (matches(openList[I], ".*dCre.*")) dCreMeans[dCrecount++] = getResult("Mean", nResults - 4);
	roiManager("reset");
	run("Clear Results");

	selectWindow(targetTitle);
	close();
	selectWindow(openList[I]);
	close();
}

print("dCre");
Array.print(dCreMeans);
Array.getStatistics(dCreMeans, min, max, mean, stdDev);
print(mean + " StdDev: " + stdDev);
print("CRE:");
Array.print(CREMeans);
Array.getStatistics(CREMeans, min, max, mean, stdDev);
print(mean + " StdDev: " + stdDev);