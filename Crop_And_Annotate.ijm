// REMOVE ME TO RESTORE SCRIPT PARAMETERS

// @File(label = "Image to crop:") sourceimage
// @File(label = "Output folder:", style = "directory") outputdir

// Note: DO NOT DELETE OR MOVE THE FIRST 2 LINES -- they supply essential parameters.

// Crop_And_Annotate.ijm
// ImageJ/Fiji macro
// Theresa Swayne, tcs6@cumc.columbia.edu, 2017
// Allows user to crop and annotate age of manually selected cells in an image, 
// and produce cropped versions with unique filenames containing annotation
//
// Input: A stack (or single plane) image. 
// 		User clicks on desired cells, and provides annotation data.
// Output: 
//		1) A stack (or single plane) of 200x200 pixels centered on each point.
//		2) An ROIset of the points chosen.
// 		Output images are saved in the same folder as the source image.
//		and named following the scheme: 
// 		genotype, initials, _E_xperiment, _S_tain, _F_ixed/live, _C_ell ID, _A_ge
// 		e.g. WT_WP_E1_S1_F1_C8_A13 
//		wild-type cell, prepared by Wolfgang P., from the first dataset submitted (E1), 
//		Fixed (F1), Cell number 8 (C8), age 13 (A13)
//
//	TODO: A CSV file will also be produced containing:
// 		0 cropped filename, 1 original filename, 2-3 center of crop box (XY), 4 genotype, 5 initials,
//		6 expt, 7 stain, 8 fixed/live, 9 cell ID, 10 age
// 		
// Usage: Open an image. You should already know the age of each cell in the image, or be
// 		looking at it simultaneously in another program. 
//		Then run the macro. 
//
// Limitations: If the point is < 200 pixels from an edge the output image is not 200x200,  
// 		but only goes to the edge of the image.


// --------------- sample images for testing

// LAB
sourceimage = "/Users/confocal/Desktop/input/confocal-series.tif";
outputdir = "/Users/confocal/Desktop/output";

// HOME
// sourceimage = "/Users/theresa/Desktop/input/confocal-series.tif";
// outputdir = "/Users/theresa/Desktop/output";

// --------------- end sample image section


// ------------- SETUP

// maximum width and height of the final cropped image, in pixels
CROPSIZE = 200;

// get file info 

open(sourceimage);
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);
roiName = basename + "_roiset.zip";

roiManager("reset");

// get the parameters that are constant for all cells in the image

genotype = "";
initials = "";
experiment = 0;
stain = "";
stainNum = 5;
fixed = "";
fixedNum = 2;
stainChoices = newArray("Calcofluor","WGA 488", "WGA 647");
fixedChoices = newArray("fixed","live");
nextCellNum = 0;
imageInfo = "";

complete = false;

while (!complete)
	{
	Dialog.create("Enter experiment info");
	
	Dialog.addString("Genotype (enter D for delta):", "WT");
	Dialog.addString("Experimenter Initials:", "TS");
	Dialog.addNumber("Your Unique Experiment Number:", 0);
	Dialog.addChoice("Stain:", stainChoices);
	Dialog.addChoice("Fixed/Live:",fixedChoices);
	Dialog.addNumber("Next Cell Number in Experiment:",1); // allows continuing expt on a different image
	selectWindow(title); // prevent unfocused window
	Dialog.show();
	
	genotype = Dialog.getString();
	initials = Dialog.getString();
	experiment = Dialog.getNumber();
	stain = Dialog.getChoice();
	fixed = Dialog.getChoice();
	nextCellNum = Dialog.getNumber(); 
	
	if ((experiment == 0) | (d2s(experiment,0) == NaN)) // catches 0, letters, and empty field 
		{
		showMessage("You must enter an integer for the experiment number.");
		}
	else if ((nextCellNum == 0) | (d2s(nextCellNum,0) == NaN))
		{
		showMessage("You must enter an integer for the next cell number.");
		}
	else
		{
		complete = true;
		}
	}
	
// turn choices into codes
if (stain == "Calcofluor") {
	stainNum = 0; }
else if (stain == "WGA 488") {
	stainNum = 1; }
else  { // 647
	stainNum = 2; }

if (fixed == "fixed") {
	fixedNum = 1; }
else { // live
	fixedNum = 0; }

// constant image info for all cells
imageInfo = genotype+"_"+initials+"_E"+experiment+"_S"+stainNum+"_F"+fixedNum;

print("You entered:");
print(imageInfo);
print("and your next cell will be",nextCellNum);

// TODO: create CSV file

moreCells = "Mark more";
cellCount = 0;
setTool("point");
run("Point Tool...", "type=Hybrid color=Yellow size=Medium add label");
age = 0;

// INTERACTIVE LOOP: MARKING AND ANNOTATING CELLS

while (moreCells == "Mark more") 
	{
	cellNum = nextCellNum + cellCount;
	waitForUser("Mark cell", "Click on a bud neck, then click OK");
	
	// TODO: catch errors like no clicks, >1 click
	// check for numROIs being too high or low relative to cellCount. 
	// too many clicks: delete ROIs from end so there are the right number, ask to select cell again
	// not enough clicks: ask to select cell again

	ageInput = false;
	while (!ageInput) // collect valid age info
		{
		Dialog.create("Enter age");
		Dialog.addNumber("Age of this cell:", 0);
		Dialog.addMessage("Mark more cells in this image,\nor crop and save all cells?");
		Dialog.addChoice("", newArray("Mark more","Crop and save"), "Mark more");
		selectWindow(title); // prevents unresponsive age box when user hits Enter instead of clicking OK
		Dialog.show();
		age = Dialog.getNumber();
		moreCells = Dialog.getChoice();
	
		if ((age == 0) | (d2s(age,0) == NaN))
			{
			showMessage("You must enter an integer for the age.");
			}
		else
			{
			ageInput = true;
			}
		}

	print("Cell number",cellNum,"is",age," generations old.");
	
	// store annotations in ROI name
	numROIs = roiManager("count");
	roiManager("Select",numROIs-1); // select the most recent ROI
	roiManager("rename", imageInfo+"_C"+cellNum+"_A"+age);
	roiManager("Show All");



	// TODO: append to lists or csv file including the name of the image file
	
	cellCount ++;
	}
		
// --------------- CROP AND SAVE


// TODO: show a confirmation and chance to correct errors in age
	
// make sure nothing is selected to begin with
selectImage(id);
roiManager("Deselect");
run("Select None");

// crop
numROIs = roiManager("count");
for(i=0; i<numROIs;i++) 
	{ 
	selectImage(id); 
	roiManager("Select", i); 
	
	cropName = call("ij.plugin.frame.RoiManager.getName", i); // filename will be roi name
	Roi.getCoordinates(x, y); // x and y are arrays; first point is all we need

	// TODO: collect data for CSV file

	// make new rectangle ROI centered on the point
	run("Specify...", "width=&CROPSIZE height=&CROPSIZE x="+x[0]+" y="+y[0]+" slice=1 centered"); 
	run("Duplicate...", "title=&cropName duplicate"); 
	selectWindow(cropName);
	saveAs("tiff", outputdir+File.separator+getTitle);
	close(); // cropped image
	}
run("Select None");
roiManager("save",outputdir+File.separator+roiName);

// TODO: write to CSV file

// ---  FINISH UP
print("All files saved.");
close(); // original image
roiManager("reset");

