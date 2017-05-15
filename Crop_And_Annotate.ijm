// Crop_And_Annotate.ijm
// ImageJ/Fiji macro by Theresa Swayne, tcs6 at cumc.columbia.edu, 2017
// Allows user to provide annotation of each cell in a field, 
// and produce cropped versions with unique filenames containing annotation 
// Input: A stack (or single plane) image. 
// User clicks on desired cells, and provides annotation data.
// Output: A stack (or single plane) of 200x200 pixels centered on each point.
// 		Output images are saved in the same folder as the source image.
//		and named following the scheme: 
// 		genotype, initials, Experiment, Stain, Fixed/live, Cell ID, Age
// 		e.g. WT_WP_E1_S1_F1_C8_A13 
//		wild-type cell, prepared by Wolfgang P., from the first dataset submitted (E1), 
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

// FUTURE: Image loop so you can do multiple images in an expt

// ------------- SETUP

CROPSIZE = 30;

// sample images for testing

// LAB
// open("/Users/confocal/Desktop/input/confocal-series.tif");
// open("/Users/confocal/Desktop/input/RoiSet.zip"); 

// HOME
open("/Users/theresa/Desktop/input/confocal-series.tif");
// open("/Users/theresa/Desktop/input/RoiSet.zip"); 

// get file info TODO: use script parameters
path = getDirectory("image");
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);

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

Dialog.create("Enter experiment info");

Dialog.addString("Genotype (enter D for delta):", "WT");
Dialog.addString("Experimenter Initials:", "TS");
Dialog.addNumber("Your Unique Experiment Number:", 0);
Dialog.addChoice("Stain:", stainChoices);
Dialog.addChoice("Fixed/Live:",fixedChoices);
Dialog.addNumber("Next Cell Number in Experiment:",1); // allows continuing expt
Dialog.show();

genotype = Dialog.getString(); // first text field
initials = Dialog.getString();
experiment = Dialog.getNumber();
stain = Dialog.getChoice();
fixed = Dialog.getChoice();
nextCellNum = Dialog.getNumber(); 

// TODO: raise errors if wrong type of input or no input

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

imageInfo = genotype+"_"+initials+"_E"+experiment+"_S"+stainNum+"_F"+fixedNum;

print("You entered:");
print(imageInfo);
print("and your next cell will be",nextCellNum);

// TODO: create CSV file

done = true;
cellCount = 0;
setTool("point");
run("Point Tool...", "type=Hybrid color=Yellow size=Medium add label");
age = 0;

// INTERACTIVE LOOP

	// while done == false:
		
	cellNum = nextCellNum + cellCount;
	waitForUser("Mark cell", "Click on a bud neck, then click OK");
	
	// TODO: catch errors like making more than one click, or using the wrong tool
	
	Dialog.create("Enter age");
	Dialog.addNumber("Age of this cell:", 0);
	Dialog.show();
	age = Dialog.getNumber();
	print("Cell number",cellNum,"is",age," generations old.");
	
	// TODO: catch errors: decimal, zero, strings, null
	// TODO: show a confirmation and chance to correct errors
	
	numROIs = roiManager("count");
	roiManager("Select",numROIs-1); // select the most recent ROI
	roiManager("rename", imageInfo+"_C"+cellNum+"_A"+age);

	roiManager("Show All");
	
	// TODO: append to csv file including the name of the image file

	// TODO: ask if they have another cell (while loop)

	// TODO: consolidate the dialogs more elegantly

// --------------- CROP AND SAVE

// make sure nothing selected to begin with
selectImage(id);
roiManager("Deselect");
run("Select None");

// loop through ROIs
numROIs = roiManager("count");
for(i=0; i<numROIs;i++) 
	{ 
	selectImage(id); 
	roiManager("Select", i); 
	
	cropName = call("ij.plugin.frame.RoiManager.getName", i); // filename will be roi name
	Roi.getCoordinates(x, y); // x and y are arrays; first point is all we need

	// make new rectangle ROI around point
	run("Specify...", "width=&CROPSIZE height=&CROPSIZE x="+x[0]+" y="+y[0]+" slice=1 centered"); 
	// create and save the cropped stack
	run("Duplicate...", "title=&cropName duplicate"); 
	selectWindow(cropName);
	saveAs("tiff", path+getTitle);
	close();
	}	
run("Select None");

// ---  FINISHING
close();
roiManager("reset");

