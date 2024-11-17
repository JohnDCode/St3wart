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


void modifyHeader(const char *filename);
void baselineHashes(const char *filename);


// Add hashes to the baseline csv
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Csv to add hashes too
    const char *baselinePath = "baseline.csv";

    // Add collumn for hashes in baseline csv
    modifyHeader(baselinePath);

    // Add the hashes to the csv
    baselineHashes(baselinePath);


  
    // Record end time and use start time to get execution time
    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;


    // Print execution time
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
}




// Get the SHA256 hash of a file using https://github.com/B-Con/crypto-algorithms/tree/master
void calculateSHA256(const char *filePath, char *result) {

    // Open the file
    FILE *file = fopen(filePath, "rb");

    // Ensure the file could be opened
    if (!file) {
        // Write to console that the file couldn't be opened
        printf("Error opening file %s\n", filePath);

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




// Function to trim newline characters from strings
void trim_newline(char *str) {
    size_t len = strlen(str);
    if (len > 0 && str[len - 1] == '\n') {
        str[len - 1] = '\0';
    }
}




// Function to modify the header of the CSV file
void modifyHeader(const char *filename) {

    // Open the csv
    FILE *file = fopen(filename, "r+");
    if (!file) {
        perror("Unable to open file");
        exit(EXIT_FAILURE);
    }

    // Read the first line (header)
    char header[512];
    if (fgets(header, sizeof(header), file)) {

        // Add to the header
        trim_newline(header);
        strcat(header, ", Hashes\n");

        // Move the file pointer to the beginning and overwrite the header
        fseek(file, 0, SEEK_SET);
        fprintf(file, "%s", header);
    }

    // Close the baseline csv
    fclose(file);
}




// Function to concatenate each baseline entry with hash of the file
void baselineHashes(const char *filename) {

    // Open the baseline csv
    FILE *file = fopen(filename, "r");
    if (!file) {
        perror("Unable to open file");
        exit(EXIT_FAILURE);
    }

    // Temporary file to store the modified content
    FILE *temp_file = tmpfile();
    if (!temp_file) {
        perror("Unable to create temporary file");
        fclose(file);
        exit(EXIT_FAILURE);
    }

    char line[512];
    char name[256], path[256];
    int isFirstLine = 1;

    // Loop over the csv
    while (fgets(line, sizeof(line), file)) {

        // Skip the first line
        if (isFirstLine) {
            isFirstLine = 0;
            fprintf(temp_file, "%s", line); // Copy the header as is
            continue;
        }

        // Parse the CSV line
        sscanf(line, "\"%[^\"]\",\"%[^\"]", name, path);

        // Construct the full path
        char fullPath[512];
        snprintf(fullPath, sizeof(fullPath), "%s\\%s", path, name);

        // Get the hash with the full path
	trim_newline(fullPath);
        char fileHash[65];
        calculateSHA256(fullPath, fileHash);

        // Trim newline character, add the file hash in seperate collumn, add back new line character
        trim_newline(line);
        strcat(line, ", ");
	strcat(line, fileHash);
	strcat(line, "\n");

        // Write the modified line to the temporary file
        fprintf(temp_file, "%s", line);
    }

    // Close the main csv
    fclose(file);

    // Write the modified content back to the original file
    FILE *output_file = fopen(filename, "w");
    if (!output_file) {
        perror("Unable to open file for writing");
        fclose(temp_file);
        exit(EXIT_FAILURE);
    }

    rewind(temp_file); // Rewind the temporary file to the beginning

    while (fgets(line, sizeof(line), temp_file)) {
        fprintf(output_file, "%s", line);
    }

    // Close the files
    fclose(temp_file);
    fclose(output_file);
}
