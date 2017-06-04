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

