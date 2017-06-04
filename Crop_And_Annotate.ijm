// @File(label = "Image to crop:") sourceimage
// @File(label = "Output folder:", style = "directory") outputdir

// Note: DO NOT DELETE OR MOVE THE FIRST 2 LINES -- they supply essential parameters.

// Crop_And_Annotate.ijm
// ImageJ/Fiji macro
// Theresa Swayne, tcs6@cumc.columbia.edu, 2017
// Allows user to crop and annotate age of manually selected cells in an image, 
// and produce cropped versions with unique filenames containing annotation
//
// Input: An image (stack or single plane, 1 or more channels). 
// 		User clicks on desired cells, and provides annotation data.
// Output: 
//		1) A cropped image of 200x200 pixels centered on each point.
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
dataName = basename + "_data.csv"

run("Input/Output...", "file=.csv save_column"); // saves data as csv, preserves headers, doesn't save row number 

// set up data file
headers = "filename, genotype, initials, experiment, stainNum, fixed, cell number, XPos, YPos, age";
File.append(headers,outputdir  + File.separator+ dataName);

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

while (!complete) // keep showing the dialog until all entries are acceptable
	{
	Dialog.create("Enter experiment info");
	Dialog.addString("Genotype (enter D for delta):", "WT");
	Dialog.addString("Experimenter Initials:", "TS");
	Dialog.addNumber("Your Unique Experiment Number:", 1);  // TODO: change to 0 for actual use
	Dialog.addChoice("Stain:", stainChoices);
	Dialog.addChoice("Fixed/Live:",fixedChoices);
	Dialog.addNumber("Next Cell Number in Experiment:",1); // allows continuing expt on a different image
	selectWindow(title); // prevent error where window becomes unfocused
	Dialog.show();
	
	genotype = Dialog.getString();
	initials = Dialog.getString();
	experiment = Dialog.getNumber();
	stain = Dialog.getChoice();
	fixed = Dialog.getChoice();
	nextCellNum = Dialog.getNumber(); 
	
	if ((experiment == 0) | (d2s(experiment,0) == NaN)) // catches 0, letters, or empty field 
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
else  { // WGA 647
	stainNum = 2; }

if (fixed == "fixed") {
	fixedNum = 1; }
else { // live
	fixedNum = 0; }

// collect the parameters that are constant for all cells in the image
imageInfo = genotype+"_"+initials+"_E"+experiment+"_S"+stainNum+"_F"+fixedNum;
imageInfoList = newArray(title, genotype, initials, experiment, stainNum, fixedNum,0,0.0,0.0,0); // for each cell, fill in this list to generate CSV row

print("You entered:");
print(imageInfo);
print("and your next cell will be",nextCellNum);


// ------------- MARK AND ANNOTATE CELLS

moreCells = "Mark more";
cellCount = 0;
age = 0;
roiManager("reset");
setTool("point");
run("Point Tool...", "type=Hybrid color=Yellow size=Medium add label");

function getCellPosition(cellCount) 
	{
	// Lets user create a point ROI, which should correspond to a bud neck. 
	// Makes sure a point is actually clicked (but it may be > 1 point). 
	// cellCount: integer, number of cells marked previously
	// returns: the new cell count
	setTool("point");
	run("Point Tool...", "type=Hybrid color=Yellow size=Medium add label");
	while (roiManager("count") < (cellCount + 1)) // check if user clicked ok without marking a cell
		{
		waitForUser("Mark cell", "Click on a bud neck, then click OK");
		}
	newCount = cellCount + 1;
	return newCount;
	}

while (moreCells == "Mark more") 
	{
	cellNum = nextCellNum + cellCount; // cell number for annotation
	cellCount = getCellPosition(cellCount);  // prompt user to mark a cell

	// check for too many clicks
	numROIs = roiManager("count");
	//print("There are",numROIs,"ROIs after your clicking, and there should be",cellCount);

	if (numROIs > cellCount) // user clicked too many times
		{
		cellCount--; // return count to previous value

		// delete extra ROIs
		while (roiManager("count") > cellCount)
			{
			lastROI = roiManager("count")-1; // most recent ROI
			print("deleting ROI",lastROI);
			roiManager("Select",lastROI); 
			roiManager("Delete");
			}

		// try marking again
		showMessage("Multiple clicks detected. Deleted last points.\nPlease mark cell again.");
		cellCount = getCellPosition(cellCount); 
		}

	// collect valid age
	ageInput = false;
	while (!ageInput) 
		{
		Dialog.create("Enter age");
		Dialog.addNumber("Age of this cell:", 1); // TODO: replace with 0 for actual use
		Dialog.addMessage("Mark more cells in this image,\nor crop and save all cells?");
		Dialog.addChoice("", newArray("Mark more","Crop and save"), "Crop and save"); // TODO: replace with Mark More for actual use
		selectWindow(title); // prevents unresponsive dialog
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
		} // end of age input loop

	print("Cell number",cellNum,"is",age,"generations old.");
	
	// store annotations in ROI name
	numROIs = roiManager("count");
	roiManager("Select",numROIs-1); // most recent ROI
	roiManager("rename", imageInfo+"_C"+cellNum+"_A"+age);
	
	// TODO: grab cell number, X and Y, and age, and append to imageInfoList, then append to the csv
	// TODO: figure out how to append properly using array... probably need to append strings and commas instead...
	
	imageInfoList = newArray(title, genotype, initials, experiment, stainNum, fixedNum,0,0.0,0.0,0); // for each cell, fill in this list to generate CSV row
	//Array.print(imageInfoList);
	imageInfoList[6] = cellNum;
	Roi.getCoordinates(x, y); // x and y are arrays
	imageInfoList[7] = x[0]; // first point in ROI array is all we need
	imageInfoList[8] = y[0];
	imageInfoList[9] = age;
	print("array is:");
	Array.print(imageInfoList);

	// construct a string from the array
	imageInfoString = "";
	for (i=0; i<imageInfoList.length; i++) {
          imageInfoString = imageInfoString + imageInfoList[i] + ",";
	}
	// remove final comma
	imageInfoString = substring(imageInfoString, 0, lengthOf(imageInfoString)-1);
	print("ImageInfoString",imageInfoString);
	File.append(imageInfoString,outputdir  + File.separator+ dataName);
	
	roiManager("Show All");

	
	} // end of "mark more" loop
		
// --------------- CROP AND SAVE

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
	Roi.getCoordinates(x, y); // x and y are arrays

	// make new rectangle ROI centered on the point
	run("Specify...", "width=&CROPSIZE height=&CROPSIZE x="+x[0]+" y="+y[0]+" slice=1 centered"); // first point in ROI coord array

	run("Duplicate...", "title=&cropName duplicate"); 
	selectWindow(cropName);
	saveAs("tiff", outputdir+File.separator+getTitle);
	close(); // cropped image
	}
run("Select None");

// save ROIs to show location of each cell
roiManager("save",outputdir+File.separator+roiName);

// --------  FINISH
print("All files saved.");
close(); // original image
roiManager("reset");


