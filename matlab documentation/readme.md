# matlab documentation
The goal of this folder was to solve the problem of assorted matlab functions coming from multiple sources that have varying levels of documentation. 

# How does it work?
The entire process is more clearly outlined in the "getting started.md" file. Briefly, for each matlab function within a folder a [.json](https://en.wikipedia.org/wiki/JSON) file is created by filling in the "template.json" file for a particular function. These files are highly flexible and allow for as mich information as necessary for a function. Additionally, html formatted code can be added within fields to help with visibility or explanation of complex problems.

Once a new .json file is created, the user only needs to run the "generateHelpDoc.m" matlab script, which will compile any and all .json files into a help documentation that can be accessed within matlab's native help documentation.
