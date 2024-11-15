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


// Get the files in a directory and their hashes, export them to a CSV
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Paths to export and scanned directories
    const char *directoryPath = "C:/Windows"; 
    const char *outputFilePath = "baseline.csv";


    // Export all files in C:/Windows and their hashes to the csv
    exportFiles(outputFilePath, directoryPath);


    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;


    // Print execution time and output csv
    printf("File paths exported to %s\n", outputFilePath);
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
    fprintf(csvFile, "FilePath, Hash\n");


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
            if ((strstr(filePath, "C:/Windows/servicing") == NULL) && (strstr(filePath, "C:/Windows/WinSxS") == NULL) && (strstr(filePath, "C:/Windows/SoftwareDistribution") == NULL) && (strstr(filePath, "C:/Windows/assembly/NativeImages_") == NULL)) {
                

                // Get the SHA-256 hash of the file
                //char sha256[65];
                //calculateSHA256(filePath, sha256);


                // Write the file path and hash to the CSV (FilePath, Hash)
                fprintf(csvFile, "%s,%s\n", filePath, "no hash");
                
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
