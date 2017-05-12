// Crop_And_Annotate.ijm
// ImageJ/Fiji macro by Theresa Swayne, tcs6@cumc.columbia.edu, 2017
// Allows user to provide annotation of each cell in a field, 
// and produce cropped versions with unique filenames containing annotation 
// Input: A stack (or single plane) and a set of point ROIs in the ROI manager 
// Output: A stack (or single plane) corresponding to 200x200 pixels centered on each point.
// 		Output images are saved in the same folder as the source image.
//		and named following the scheme: genotype, initials, Experiment, Stain, Fixed/live, Cell ID, Age
// 		e.g. WT_WP_E1_S1_F1_C8_A13 would be a WT cell, prepared by Wolfgang P., from the first dataset/Experiment submitted (E1), 
//		Fixed (F1), Cell number 8 (C8) and age 13 (A13)
//	A CSV file is also produced containing:
// 		0 cropped filename, 1 original filename, 2-3 center of crop box (XY), 4 genotype, 5 initials,
//		6 expt, 7 stain, 8 fixed/live, 9 cell ID, 10 age
//  And also an ROI set for the image
// 		
// Usage: Open an image. You should already know the age of each cell in the image, or be
// 		looking at it simultaneously in another program. Then run the macro. 
// Limitations: If the point is < 200 pixels from an edge the output image is not 200x200, but 
// 		but only goes to the edge of the image.

// sample images for testing
open("/Users/confocal/Desktop/input/confocal-series.tif");
// open("/Users/confocal/Desktop/input/RoiSet.zip"); 

// ------------- setup

path = getDirectory("image");
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);

roiManager("reset");

// PROMPT USER FOR DATA
// -- get the parameters that are constant for all images
// -- genotype, initials, Experiment, Stain, Fixed/live

// INTERACTIVE LOOP
// 	-- while not clicking 'done'

	// PROMPT USER TO CLICK ON CELL
	// -- catch errors like wrong tool
	
	// -- auto increment cell #
	
	// CAPTURE COORDINATES OF CLICK
	// 	-- save to mgr presumably
	
	// PROMPT USER FOR DATA
	// -- age
	
	// STORE DATA
	// -- append to csv file using the name of the file
	// -- roi mgr rename
	
	// MARK THE SPOT ON THE IMAGE
	// -- roiManager("Show All");

// 	WHEN THEY CLICK 'DONE' THEN CROP AND SAVE

// --------------- final cropping

// make sure nothing selected to begin with
selectImage(id);
roiManager("Deselect");
run("Select None");

numROIs = roiManager("count");
for(i=0; i<numROIs;i++) // loop through ROIs
	{ 
	selectImage(id); 
	cropName = basename+i; // TODO: INCLUDE ANNOTATION IN CROPNAME 
	roiManager("Select", i); 
	Roi.getCoordinates(x, y); // arrays; first point is all we need
	run("Specify...", "width=200 height=200 x="+x[0]+" y="+y[0]+" slice=1 centered"); // makes new rectangle ROI around point
	run("Duplicate...", "title=&cropName duplicate"); // creates the cropped stack
	selectWindow(cropName);
	saveAs("tiff", path+getTitle);
	close();
	}	
run("Select None");
