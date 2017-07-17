// insert script parameters here

// fake_cells.ijm
// IJ1 macro to generate simulated cell profiles 
// output: a set of images, 200x200, to be used for testing the Fit_And_Rotate.ijm macro
// each image has at least 1 ellipse and up to 4 ellipses
// some are touching each other, overlapping to various degrees
// none are really far apart or really highly overlapping

// randomize within constraints:
// major and minor lengths -- limit the aspect ratio to a certain window
// center -- neck is center of image so one pole of the ellipse is likely to be close to the center of the image.
//	what does that say about the centers of ellipses?
//  angle -- no constraints
// do a large ellipse first and then 0-3 smaller ones based on the size of the large.

// the images will mimic segmented, fitted ellipses
// setup

// image specs
NUM_IMAGES = 1; // number of random images to generate
IMAGE_SIZE = 200; // length and width of image

// ellipse specs
NUM_ELLIPSES_MAX =  4; // maximum number of ellipses (minimum is 1)
LENGTH_MAX = 100; // maximum axis length
ASPECT_MAX = 2; // maximum aspect ratio (minimum is 1)



// multiple images loop
for (i = 1; i < (NUM_IMAGES+1); i++);
	{
	// image creation loop

	// 
	// create image
	newImage("rando_"+i+", "8-bit white", "+IMAGE_SIZE+","+IMAGE_SIZE+", 1);
	print("image",i,"created");
	}
