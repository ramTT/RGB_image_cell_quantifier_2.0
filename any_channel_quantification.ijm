/////////////////// INTRODUCTION ////////////////////////////
showMessageWithCancel("Welcome to the automatic cell quantifier!\nPress 'OK' to continue or 'Cancel' to exit."); 
showMessageWithCancel("The macro requires a multichannel stack. First select the stack, then adjust the settings in the next dialog box.\nPress 'OK' to select or 'Cancel' to exit macro.");

path = File.openDialog("Select file");
open(path);

/////////////////// USER INPUT ///////////////////
Dialog.create("Settings");
Dialog.addMessage("Select appropriate thresholds for cell characteristics:");
Dialog.addNumber("Cell size in pixels (min):", 30);
Dialog.addNumber("Cell size in pixels (max):", 1000);
Dialog.addNumber("Cell circularity (min)", 0);
Dialog.addNumber("Cell circularity (max)", 1);
Dialog.addMessage("Select one, two or three color channels:");
Dialog.addCheckboxGroup(3,1,newArray("Red channel","Green channel","Blue channel"), newArray("false","false","false"));
Dialog.show();
 
cell_size_min = Dialog.getNumber();
cell_size_max = Dialog.getNumber();
circularity_min = Dialog.getNumber();
circularity_max = Dialog.getNumber();
red_channel_logical = Dialog.getCheckbox();
green_channel_logical = Dialog.getCheckbox();
blue_channel_logical = Dialog.getCheckbox();

/////////////////// DEFINING FUNCTIONS FOR CASE HANDLING///////////////////
function one_channel(stack_title, color_use, color_discard1, color_discard2){
	selectWindow(stack_title+" ("+color_discard1+")");
	close();
	selectWindow(stack_title+" ("+color_discard2+")");
	close();	
	selectWindow(stack_title+" ("+color_use+")");
}

function two_channel(stack_title, color_use1, color_use2, color_discard){
	imageCalculator("multiply", stack_title+" ("+color_use1+")", stack_title+" ("+color_use2+")");
	selectWindow(stack_title+" ("+color_discard+")");
	close();
	selectWindow(stack_title+" ("+color_use1+")");
	close();
}

function three_channel(stack_title, color_use1, color_use2, color_use3){
	imageCalculator("multiply", stack_title+" ("+color_use1+")", stack_title+" ("+color_use2+")");
	imageCalculator("multiply", stack_title+" ("+color_use2+")", stack_title+" ("+color_use3+")");
	selectWindow(stack_title+" ("+color_use1+")");
	close();
	selectWindow(stack_title+" ("+color_use2+")");
	close();
}

/////////////////// SELECTING ACTION BASED ON USER INPUT ///////////////////
start_time = getTime();
title = getTitle();

//Zero channel case
if(red_channel_logical == 0 && blue_channel_logical == 0 && green_channel_logical == 0){
	selectWindow(title);
	close();
	exit("Error! No color channels were selected. Exiting macro.");
};

run("Split Channels");

//One channel cases
if(red_channel_logical == 1 && blue_channel_logical == 0 && green_channel_logical == 0){one_channel(title, "red", "blue", "green");};
if(green_channel_logical == 1 && red_channel_logical == 0 && blue_channel_logical == 0){one_channel(title, "green", "red", "blue");};
if(blue_channel_logical == 1 && green_channel_logical == 0 && red_channel_logical == 0){one_channel(title, "blue", "green", "red");};

//Two channel cases
if(red_channel_logical == 1 && green_channel_logical == 1 && blue_channel_logical == 0){two_channel(title, "red", "green", "blue");};
if(red_channel_logical == 1 && green_channel_logical == 0 && blue_channel_logical == 1){two_channel(title, "red", "blue", "green");};
if(red_channel_logical == 0 && green_channel_logical == 1 && blue_channel_logical == 1){two_channel(title, "green", "blue", "red");};

//Three channel case
if(red_channel_logical == 1 && green_channel_logical == 1 && blue_channel_logical == 1){three_channel(title, "green", "blue", "red");};

run("Make Binary", " ");
run("Watershed", " ");
run("Make Binary", " ");

active_window = getTitle();

/////////////////CELL COUNTING/////////////////
for (i=1; i<=nSlices; i++){
	showProgress(-i/nSlices);
	setSlice(i);
	run("Analyze Particles...", "size=cell_size_min-cell_size_max pixel circularity=circularity_min-circularity_max summarize");
}

/////////////////ADDING OVERLAY TO ORIGINAL IMAGE SEQUENCE/////////////////
run("Analyze Particles...", "size=cell_size_min-cell_size_max show=[Overlay Outlines] pixel [add to manager] circularity=circularity_min-circularity_max add stack");

run("To ROI Manager");
open(path);
selectWindow(title);
run("From ROI Manager");

/////////////////CLOSING WINDOWS/////////////////
selectWindow(active_window);
close();
selectWindow("ROI Manager");
run("Close");

showMessage("Cell quantification complete!\nRun time: " + toString((getTime()-start_time)/1000)+" seconds");

/////////////////SAVING OUTPUT/////////////////
if (getBoolean("Cell quantification complete! Do you want to save the stack?")==1){	
	saveAs("tiff");
} 

if (getBoolean("Do you want to save the summary table before exiting?\nAdd the extension '.csv' to the filename to save as comma separated value file.")){
	selectWindow("Summary of "+active_window);
	
	saveAs("results");
}

showMessage("Please make sure to verify the quantification before usage! Press 'OK' to exit macro");

