passString = getArgument();
passArray = split(passString, "|");
path = passArray[0];
roiManager("reset");
roiManager("open", path + "finalROIs.zip");
open(path);
path = File.getParent(path);
group = File.getName(path);
dir = File.getParent(path) + File.separator + "Individual Synapses" + File.separator;
print(group);
print(dir);

tempDirectory = getDirectory("imagej");
tempOptDirectory = tempDirectory + "ChrisMacroTempOptions.txt";
run("Set Measurements...", "area mean centroid integrated redirect=None decimal=3");
id = getImageID(); 
title = getTitle();
getPixelSize(unit, pixelWidth, pixelHeight);
height = getHeight();
width = getWidth();

blendSquareSize = 88*pixelWidth;
//setBatchMode("hide");

for(j=0; j<roiManager("count"); j++){
	name = "Synapse" + j + title; 
	name = replace(name, "-", "_");
	name = replace(name, "\\+", "x");
	name = replace(name, "\\.lif", "");
	name = replace(name, "\\.tif", "");
	name = name + ".tif";
	selectImage(id);
	run("Select None");
	roiManager("Select", j);
	run("Measure");
	getLine(x1, y1, x2, y2, lineWidth);
	angle = getAngle(x1, y1, x2, y2);
	lineLength = getResult("Length", 0);
	XCoord = getResult("X", 0);
	YCoord = getResult("Y", 0);
	run("Clear Results");
	squareSize = blendSquareSize * 2;
	XCoord = ((XCoord/pixelWidth)-(blendSquareSize/pixelWidth));
	YCoord = ((YCoord/pixelHeight)-(blendSquareSize/pixelHeight));
	if (isNaN(lineLength) || lineLength == 0) continue;
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
	makeRectangle(XCoord, YCoord, (squareSize)/pixelWidth - widthAdjustment, (squareSize)/pixelHeight - heightAdjustment);
	run("Duplicate...", "duplicate channels=1-3");
	if (canvasPosition != 0) run("Canvas Size...", "width=" + (squareSize/pixelWidth) + " height=" + (squareSize/pixelHeight) + " position=" + canvasPosition + " zero");
	run("Rotate... ", "angle="+angle+" grid=1 interpolation=None");
	rotateImageWidth = getWidth();
	rotateImageHeight = getHeight();
	makeRectangle((rotateImageWidth/2)-((blendSquareSize/pixelWidth)/2), (rotateImageHeight/2)-((blendSquareSize/pixelHeight)/2), blendSquareSize/pixelWidth, blendSquareSize/pixelHeight);
	
	run("Duplicate...", "duplicate");
	titlet = getTitle();
	run("Split Channels");
	selectWindow("C1-"+titlet);
	saveAs("tiff", dir + group + File.separator + passArray[1] + File.separator + name);
	selectWindow("C2-"+titlet);
	saveAs("tiff", dir + group + File.separator + passArray[2] + File.separator + name);
	selectWindow("C3-"+titlet);
	saveAs("tiff", dir + group + File.separator + passArray[3] + File.separator + name);

	selectImage(id);
	close("\\Others");
}
//setBatchMode("exit and display");
roiManager("reset");

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