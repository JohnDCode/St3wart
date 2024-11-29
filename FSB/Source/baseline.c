#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <limits.h>
#include <time.h>
#include <math.h>



// Forward declare methods
void filterFilePaths(FILE *inputFile, FILE *exportFile);



// Get the files in the specified directory, and find files that have been added/modified wihtin such, based on the last baseline
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Path to directory to scan
    const char *directoryPath = "C:/Windows"; 

    // Path for all system files
    const char *systemPath = "./Output/system.csv";

    // Path to export filtered out files by c binary
    const char *filterPath = "./Output/filter.csv";



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




    // Sort out false positives based on file paths before even diff takes place
    filterFilePaths(systemFile, filterFileWrite);
    

    // Close all of the files used
    fclose(systemFile);
    fclose(filterFileWrite);
    



    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;


    // Print execution time
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
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




