#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <limits.h>
#include <time.h>
#include <math.h>



// Forward declare methods
void removeNewline(char *str);
char *isLineContained(char *line, FILE *file);
void compareBaselines(FILE *baselineFile, FILE *systemFile, FILE *addFile);
void filterFilePaths(FILE *inputFile, FILE *exportFile);



// Get the files in the specified directory, and find files that have been added/modified wihtin such, based on the last baseline
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Path to directory to scan
    const char *directoryPath = "C:/Windows"; 

    // Path for all system files
    const char *systemPath = "./Output/system.csv";

    // Path for all baselined files
    const char *baselinePath = "./Baselines/baseline.csv";

    // Path to export filtered out files by c binary
    const char *filterPath = "./Output/filter.csv";

    // Path to export all added files between system and last baseline
    const char *addPath = "./Output/added.txt";


    // Open System CSV (to read)
    FILE *systemFile = fopen(systemPath, "r");
    if (systemFile == NULL) {
        perror("Error opening system file");
        exit(EXIT_FAILURE);
    }


    // Open Filter CSV (to write only here cause filtering first)
    FILE *filterFileWrite = fopen(filterPath, "w");
    if (filterFileWrite == NULL) {
        perror("Error opening filter file write");
        exit(EXIT_FAILURE);
    }


    // Open Baseline CSV (to read)
    FILE *baselineFile = fopen(baselinePath, "r");
    if (baselineFile == NULL) {
        perror("Error opening baseline file");
        exit(EXIT_FAILURE);
    }


    // Open ADD output txt (to write)
    FILE *addFile = fopen(addPath, "w");
    if (addFile == NULL) {
        perror("Error opening add file");
        exit(EXIT_FAILURE);
    }




    // Sort out false positives based on file paths before even diff takes place
    filterFilePaths(systemFile, filterFileWrite);
    fclose(filterFileWrite);



    // Open Filter CSV (to read this time, now using filter to diff)
    FILE *filterFileRead = fopen(filterPath, "r");
    if (filterFileRead == NULL) {
        perror("Error opening filter file read");
        exit(EXIT_FAILURE);
    }

    // Diff
    compareBaselines(baselineFile, filterFileRead, addFile);




    // Close all of the files used
    fclose(systemFile);
    fclose(filterFileRead);
    fclose(baselineFile);
    fclose(addFile);
    



    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;


    // Print execution time
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
}




// Remove any new line charcters from a string (used to format for comparison)
void removeNewline(char *str) {
    char *pos;
    if ((pos = strchr(str, '\n')) != NULL) {
        *pos = '\0';
    }
}




// Checks if a line is contained in a file
char *isLineContained(char *line, FILE *file) {

    // Buffer size to hold lines in memory
    char buffer[1000];

    // Reset file position to the beginning
    fseek(file, 0, SEEK_SET);

    // Remove newline character from the given line to compare properly
    removeNewline(line);

    while (fgets(buffer, sizeof(buffer), file) != NULL) {

        // Remove newline character from the line in the file
        removeNewline(buffer);

        // Check if line is contained in the file
        if (strstr(buffer, line) != NULL) {

            // Return the line found with the stirng
            char *result = (char *)malloc(strlen(buffer) + 1);
            strcpy(result, buffer);
            return result;
        }
    }


    // Line is not contained in the file so return NULL
    return NULL;
}



void filterFilePaths(FILE *inputFile, FILE *exportFile) {

    // Buffer to hold each line
    char line[2048];

    // Read each line from the input file
    while (fgets(line, sizeof(line), inputFile) != NULL) {

        // Check if the line contains the file path flags
        if ((strstr(line, "C:\\Windows\\servicing") == NULL) && (strstr(line, "C:\\Windows\\WinSxS") == NULL) && (strstr(line, "C:\\Windows\\SoftwareDistribution") == NULL) && (strstr(line, "C:\\Windows\\assembly\\NativeImages_") == NULL)) {

            // Write the line to the export file
            fprintf(exportFile, "%s", line);
        }
    }

}



void compareBaselines(FILE *baseFile, FILE *sysFile, FILE *addExportFile) {

    // Write title to added exportation file
    fprintf(addExportFile, "Added Files from Baseline: \n\n");


    // Used to hold each path to the system files and the corresponding lines in the baseline
    char line[1000];
    char *matchLine;


    // Read lines from the sys backup and check if each line is contained in the base backup
    while (fgets(line, sizeof(line), sysFile) != NULL) {

        // Search for a match in the base backup
        matchLine = isLineContained(line, baseFile);

        // If no match is found
        if (matchLine == NULL) {

            // Line is not contained in the baseline, write to the added output file
            fprintf(addExportFile, "%s\n", line);

        }

    }

}

