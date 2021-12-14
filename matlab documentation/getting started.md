# Readme
## Hello, and welcome to the Quinn-Lab help documentation folder.
### The purpose of this help documentation folder is to clearly atriculate how to use common functions within the lab, so that once you leave, you can easily contribute to this folder and potentially alleviate many issues associated with utilizing other people's code.

# Getting started
### To have access to this help documentation, add **only** the root folder to the path list within matlab. Adding subfolders is **not nessecary**.
### Once added, the custom documentation can be accessed within matlab's documentation

# Contributing to documentation
### New help documents can be added to this folder, and are relative easy to add. First, a new .json folder must be created and modified for the new function, and then it can be used to automatically generate a help document. For file creation and editing, I _**highly recommend**_ using [Visual Studio Code](https://code.visualstudio.com)

## Creating a .json file
### The first step to creating a .json file for a new function is to _**copy and not overwrite**_ the "template.json" file found within this folder. A [.json](https://en.wikipedia.org/wiki/JSON) file is a file that essentially only carries data about a function, and is releatively human readable. Here is a detailed explanation of the contents for the entire .json file that is needed for a function:
* Title: The name of the function, typically syntax is camel-case, or just all lower-case.
* Description: A broad description of the function. No matter what syntax you use, this is the outcome of using the function.
* Syntax: The way (or multiple ways) to call a function within code. Each different syntax has these sub-sections:
    - Code: The general line of code used to call a function, including all outputs and inputs
    - Description: A slightly more detailed explanation of the particular syntax, which will immediately follow the syntax, that addresses all of the inputs and output listed. For example: Y = abs(X) returns the absolute value Y for some input number X. 
    - Input: The set of all inputs listed.
        - Name: Name of the input as specified in the "code" line.
        - Type: Type of varialbe that can be passed in. Multiple type can be listed using square brackets ([]).
        - Purpose: The basic purpose of the input.
        - Description: A _very_ detailed description of the input.
    - Output: The set of all outputs listed. This data follows the same structure as the inputs.
* Examples: Common use cases for the function.
    - Title: A title for the example that briefly describes what is being achieved
    - Description: A slightly nore detailed explanation of the example. This is not necessary, and if not used, then replace with the `null` keyword.
    - Script: The group of lines that are going to be ran in the example. These will be ran at the time of auto-generation, and outputs (if desired) will show in the example.
        - beforeComment: A comment line (if desired) that will show before the line of code.
        - code: The line of code that will be ran, as well as shown in the example. Multiple lines of code can be ran at one time, and should be separated by a '\n'.
        - afterComment: A comment line (if desired) that will show after the line of code.
    - Additional notes:
        - Comments must be indicated starting with %%, and either finish the code line or end with a \n character.
* More About: More information about the function or math involved with the function
    - Title: A title for the sub-section
    - Description: All of the body information for the section. This section is a bit more involved html language wise, so examples are extremely helpful for this section.

## Updating the help documentation
### After a new .json file is created, it can be used to generate a new help document by calling the "generateHelpDoc.m" script that can be found within this folder. This script will check all .json files within this folder, and generate new help documents for .json files that have either been newly created or modified since the previous time this script has ben ran, except for template.json. Additionally, this script will automatically update the table of contents and welcome page to reflect the new documentation. 