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
void exportFiles(const char *csvPath, const char *scanPath);
void exportFilesRecursively(FILE *csvFile, const char *currentPath);
void calculateSHA256(const char *filePath, char *result);
void removeNewline(char *str);
int isLineContained(char *line, FILE *file);
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *outputFile);


// Get the files in a directory and their hashes, export them to a CSV
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Paths to export and scanned directories
    const char *directoryPath = "C:/Windows"; 
    const char *systemPath = "systemFiles.txt";
    const char *baselinePath = "baseline.csv";
    const char *outputPath = "output.txt";


    // Export all files in C:/Windows and their hashes to a temporary txt
    exportFiles(systemPath, directoryPath);


    // Open the files to compare and use to output
    
    // Baseline
    FILE *baselineFile = fopen(baselinePath, "r");
    if (baselineFile == NULL) {
        perror("Error opening baseline");
        exit(EXIT_FAILURE);
    }

    
    // System
    FILE *systemFile = fopen(systemPath, "r");
    if (systemFile == NULL) {
        perror("Error opening system file");
        exit(EXIT_FAILURE);
    }

    // Output
    FILE *outputFile = fopen(outputPath, "w");
    if (outputFile == NULL) {
        perror("Error opening output file");
        exit(EXIT_FAILURE);
    }
    

    // Test-->
    //if(isLineContained("C:/Windows/addins/FXSEXT.ecf", baselineFile)) { printf("Found!"); }

    // Find what files are in the system files but not in the baseline
    compareFiles(baselineFile, systemFile, outputFile);

    fclose(baselineFile);
    fclose(systemFile);
    fclose(outputFile);
    

    
    

    


    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;


    // Print execution time and output csv
    printf("Scan results exported to %s\n", outputPath);
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
}




// Export all the files in a directory to a CSV
void exportFiles(const char *csvPath, const char *scanPath) {

    // Load baseline csv file into memory
    FILE *csvFile = fopen(csvPath, "w");

    // Ensure baseline csv opened
    if (csvFile == NULL) {
        perror("Error opening CSV file");
        return;
    }

    // Put header on the csv
    fprintf(csvFile, "FilePath\n");


    // Get files from the directory and add them to the csv
    exportFilesRecursively(csvFile, scanPath);

    // Close the csv file
    fclose(csvFile);
}




// Get the files from a directory and export, call recursivley to get all the files from subdirectories as well
void exportFilesRecursively(FILE *csvFile, const char *currentPath) {

    // Load the baseline directory into memory
    DIR *directory = opendir(currentPath);

    // Ensure the directory was opened
    if (directory == NULL) {
        perror("Error opening directory");
        return;
    }

    struct dirent *entry;

    while ((entry = readdir(directory)) != NULL) {

        // If the entry is a file
        if (entry->d_type == DT_REG) {
            
            // Assign the full file path to a variable
            char filePath[PATH_MAX];
            snprintf(filePath, sizeof(filePath), "%s/%s", currentPath, entry->d_name);

            // Write the full path to the output file
            if ((strstr(filePath, "C:/Windows/servicing") == NULL) && (strstr(filePath, "C:/Windows/WinSxS") == NULL)) {
                
                // Write the file path and hash to the CSV (FilePath, Hash)
                fprintf(csvFile, "%s\n", filePath);
                
            }

            


        // If the entry is a directory, get the files from that directory as well
        } else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            // If it's a directory (excluding '.' and '..'), recurse into it
            char nextPath[PATH_MAX];

            // Get the new subdirectory path
            snprintf(nextPath, sizeof(nextPath), "%s/%s", currentPath, entry->d_name);

            // Get the files from that subdirectory as well
            exportFilesRecursively(csvFile, nextPath);
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





void removeNewline(char *str) {
    char *pos;
    if ((pos = strchr(str, '\n')) != NULL) {
        *pos = '\0';
    }
}





// Checks if a line is contained in a file
int isLineContained(char *line, FILE *file) {
    char buffer[1000];
    fseek(file, 0, SEEK_SET);  // Reset file position to the beginning

    // Remove newline character from the given line
    removeNewline(line);

    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        // Remove newline character from the line in the file
        removeNewline(buffer);

        if (strstr(buffer, line) != NULL) {
            // Line is contained in the second file
            return 1;
        }
    }
    // Line is not contained in the second file
    return 0;
}



// Function to compare files and write differing lines to the output file
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *outputFile) {
    char line[1000];

    // Read lines from the first file and check if each line is contained in the second file
    while (fgets(line, sizeof(line), systemFile) != NULL) {
        if (!(isLineContained(line, baselineFile))) {
            // Line is not contained in the baseline, write to the output file
            fprintf(outputFile, "%s", line);
        }
    }
}