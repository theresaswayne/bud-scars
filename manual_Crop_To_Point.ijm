// manual_Crop_To_Point.ijm
// ImageJ/Fiji macro by Theresa Swayne, tcs6@cumc.columbia.edu, 2017
// Input: A stack (or single plane) and a set of point ROIs in the ROI manager 
// Output: A stack (or single plane) corresponding to 200x200 pixels centered on each point.
// 		Output images are numbered from 0 to the number of ROIs, 
//		and are saved in the same folder as the source image.
//		Non-rectangular ROIs are cropped to their bounding box.
// Usage: Open an image. Select the Point (not multi-point) tool. 
//		Double-click the point tool icon and set option to Add to Manager. 
//		Click on each cell you want to crop out. 
//		Then run the macro. 
// Limitations: If the point is < 200 pixels from an edge the output image is not 200x200, but 
// 		but only goes to the edge of the image.

// sample images for testing
open("/Users/confocal/Desktop/input/confocal-series.tif");
open("/Users/confocal/Desktop/input/RoiSet.zip"); // ### TODO: make interactive -- click, enter info, continue

path = getDirectory("image");
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);

// make sure nothing selected to begin with
selectImage(id);
roiManager("Deselect");
run("Select None");

numROIs = roiManager("count");
for(i=0; i<numROIs;i++) // loop through ROIs
	{ 
	selectImage(id); 
	cropName = basename+i; // TODO: enter data and name file following the annotation scheme
	roiManager("Select", i); 
	Roi.getCoordinates(x, y); // arrays; first point is all we need
	run("Specify...", "width=200 height=200 x="+x[0]+" y="+y[0]+" slice=1 centered"); // makes new rectangle ROI around point
	run("Duplicate...", "title=&cropName duplicate"); // creates the cropped stack
	selectWindow(cropName);
	saveAs("tiff", path+getTitle);
	close();
	}	
run("Select None");
