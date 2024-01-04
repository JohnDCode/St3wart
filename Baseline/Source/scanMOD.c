#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <limits.h>
#include <time.h>
#include <math.h>
#include "sha256.h"

// Buffer size to hold files in memory
#define BUFFER_SIZE 2048


// Forward declare methods
void exportFiles(const char *exportPath, const char *scanPath);
void exportFilesRecursively(FILE *exportFile, const char *currentPath);
void calculateSHA256(const char *filePath, char *result);
void removeNewline(char *str);
char *isLineContained(char *line, FILE *file);
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *addFile, FILE *modFile);



// Get the files in the specified directory, and find files that have been added/modified wihtin such, based on the last baseline
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Path to directory to scan
    const char *directoryPath = "C:/Windows"; 

    // Path to export all files on the system too
    const char *systemPath = "system.txt";

    // Last baseline csv to reference with files and hashes
    const char *baselinePath = "baseline.csv";

    // Path to export all added files between system and last baseline
    const char *addPath = "added.txt";

    // Path to export all modified files between system and last baseline (based on SHA-256 hashing)
    const char *modPath = "modified.txt";


    // Export all files in C:/Windows to the system txt file
    exportFiles(systemPath, directoryPath);



    // Open the files used to scan
    
    // Open Baseline CSV (to read)
    FILE *baselineFile = fopen(baselinePath, "r");
    if (baselineFile == NULL) {
        perror("Error opening baseline");
        exit(EXIT_FAILURE);
    }

    // Open System TXT (to read)
    FILE *systemFile = fopen(systemPath, "r");
    if (systemFile == NULL) {
        perror("Error opening system file");
        exit(EXIT_FAILURE);
    }

    // Open Output (added) Log (to write)
    FILE *addFile = fopen(addPath, "w");
    if (addFile == NULL) {
        perror("Error opening added output file");
        exit(EXIT_FAILURE);
    }

     // Open Output (mod) Log (to write)
    FILE *modFile = fopen(modPath, "w");
    if (modFile == NULL) {
        perror("Error opening modified output file");
        exit(EXIT_FAILURE);
    }
    

    // Compare the last baseline to the system files and export results
    compareFiles(baselineFile, systemFile, addFile, modFile);


    // Close all of the files used
    fclose(baselineFile);
    fclose(systemFile);
    fclose(addFile);
    fclose(modFile);
    
    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;



    // Print execution time and output files
    printf("Scan results exported to %s", addPath);
    printf(" and %s\n", modPath)
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
}




// Export all files in a directory to a file
void exportFiles(const char *exportPath, const char *scanPath) {

    // Load the exporting file into memory
    FILE *exportFile = fopen(exportPath, "w");

    // Ensure exporting file opened
    if (exportFile == NULL) {
        perror("Error opening exportation file");
        return;
    }

    // Put header on the csv
    fprintf(exportFile, "FilePath\n");


    // Get files from the directory and add them to the csv
    exportFilesRecursively(exportFile, scanPath);

    // Close the csv file
    fclose(exportFile);
}




// Get the files from a directory and export, call recursivley to get all the files from subdirectories as well
void exportFilesRecursively(FILE *exportFile, const char *currentPath) {

    // Load the directory to scan into memory
    DIR *directory = opendir(currentPath);

    // Ensure the directory was opened
    if (directory == NULL) {
        perror("Error opening directory");
        return;
    }

    struct dirent *entry;

    // Loop through entries within the directory
    while ((entry = readdir(directory)) != NULL) {

        // If the entry is a file
        if (entry->d_type == DT_REG) {
            
            // Assign the full file path to a variable
            char filePath[PATH_MAX];
            snprintf(filePath, sizeof(filePath), "%s/%s", currentPath, entry->d_name);

            // Ensure the file path is not from the excluded directories
            if ((strstr(filePath, "C:/Windows/servicing") == NULL) && (strstr(filePath, "C:/Windows/WinSxS") == NULL)) {
                
                // Write the file path to the exportation file
                fprintf(exportFile, "%s\n", filePath);
                
            }

            


        // If the entry is a directory, get the files from that directory as well
        } else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            // If it's a directory (excluding '.' and '..'), recurse into it
            char nextPath[PATH_MAX];

            // Get the new subdirectory path
            snprintf(nextPath, sizeof(nextPath), "%s/%s", currentPath, entry->d_name);

            // Get the files from that subdirectory as well
            exportFilesRecursively(exportFile, nextPath);
        }
    }


    // Close the directory
    closedir(directory);
}




// Get the SHA256 hash of a file using https://github.com/B-Con/crypto-algorithms/tree/master
void calculateSHA256(const char *filePath, char *result) {

    // Open the file
    FILE *file = fopen(filePath, "rb");

    // Ensure the file could be opened
    if (!file) {
        // Write to console that the file couldn't be opened
        fprintf(stderr, "Error opening file %s\n", filePath);

        // Return and set the hash to "NULL" ("NULL" will be written to the CSV as well)
        strcpy(result, "NULL");
        return;
    }

    // Use sha256.c to get the file hash
    SHA256_CTX sha256Context;
    sha256_init(&sha256Context);

    char buffer[BUFFER_SIZE];
    size_t bytesRead;

    while ((bytesRead = fread(buffer, 1, BUFFER_SIZE, file)) > 0) {
        sha256_update(&sha256Context, buffer, bytesRead);
    }


    // Close the file
    fclose(file);

    unsigned char hash[SHA256_BLOCK_SIZE];
    sha256_final(&sha256Context, hash);

    // Convert the binary hash to a hexadecimal string
    for (int i = 0; i < SHA256_BLOCK_SIZE; i++) {
        sprintf(result + 2 * i, "%02x", hash[i]);
    }

    // Null-terminate the hexadecimal string
    result[64] = '\0';  
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




// Function to compare system export and baseline, then write differences to proper files for logging
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *addFile, FILE *modFile) {

    // Write titles to added and modified exportation files
    fprintf(addFile, "Added Files from Baseline: \n\n");
    fprintf(modFile, "Modified Files from Baseline: \n\n");


    // Used to hold each path to the system files and the corresponding lines in the baseline
    char line[1000];
    char *matchLine;


    // Read lines from the system files and check if each line is contained in the baseline
    while (fgets(line, sizeof(line), systemFile) != NULL) {

        // Search for a match in the baseline
        matchLine = isLineContained(line, baselineFile)

        // If no match is found
        if (matchLine == NULL) {

            // Line is not contained in the baseline, write to the added output file
            fprintf(addFile, "%s", line);

        // Match was found, check to see if modified (using SHA-256)
        } else {

            // Get the system file hash
            char fileHash[65];
            calculateSHA256(line, fileHash);

            // Check to see if the system file hash is equivalent to the baseline file hash (by splitting the baseline entry into just the hash)
            if(!(fileHash == strdup(strchr(matchLine, ',') + 1))) {

                // File is modified, write to the modified output file
                fprintf(modFile, "%s", line);
            }

        }
    }
}
