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
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *addFile);


// Add hashes to the baseline csv
int main() {

    // Record the start time of the script to measure execution time
    clock_t start_time = clock();

    // Csv to add hashes too (system files)
    const char *systemPath = "system.csv";

    // Csv from baseline
    const char *basePath = "baseline.csv";

    // Export file for added files
    const char *addPath = "added.txt";



    // Add collumn for hashes in system csv
    //modifyHeader(systemPath);

    // Add the hashes to the system csv
    //baselineHashes(systemPath);






    FILE *baseFile = fopen(basePath, "r");
    if (!baseFile) {
        perror("Unable to open base file");
        exit(EXIT_FAILURE);
    }


    FILE *sysFile = fopen(systemPath, "r");
    if (!sysFile) {
        perror("Unable to open sys file");
        exit(EXIT_FAILURE);
    }


    FILE *addFile = fopen(addPath, "w");
    if (!addFile) {
        perror("Unable to open add file");
        exit(EXIT_FAILURE);
    }


    // Baseline
    compareFiles(baseFile, sysFile, addFile);
    


  
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




// Remove any new line charcters from a string (used to format for comparison)
void removeNewline(char *str) {
    char *pos;
    if ((pos = strchr(str, '\n')) != NULL) {
        *pos = '\0';
    }
}



int containsString(FILE *file, const char *str) {
    if (file == NULL || str == NULL) {
        return 0;
    }

    size_t str_len = strlen(str);
    if (str_len == 0) {
        return 0;
    }

    // Allocate a buffer to read the file in chunks
    const size_t buffer_size = 1024;
    char buffer[buffer_size + 1]; // +1 for null terminator

    // Set the file position to the beginning
    fseek(file, 0, SEEK_SET);

    size_t read_len;
    while ((read_len = fread(buffer, 1, buffer_size, file)) > 0) {
        buffer[read_len] = '\0'; // Null-terminate the buffer

        // Check if the string is in the buffer
        if (strstr(buffer, str) != NULL) {
            return 1;
        }

        // Move the file position back to account for potential split of the target string across buffer boundaries
        if (read_len == buffer_size) {
            fseek(file, -((long)str_len - 1), SEEK_CUR);
        }
    }

    return 0;
}




// Function to compare system export and baseline, then write differences to proper files for logging
void compareFiles(FILE *baselineFile, FILE *systemFile, FILE *addFile) {

    // Write titles to added and modified exportation files
    fprintf(addFile, "Added Files from Baseline: \n\n");


    // Used to hold each path to the system files and the corresponding lines in the baseline
    char line[1000];
    int matchCheck;
    int isFirstLine = 1;


    // Read lines from the system files and check if each line is contained in the baseline
    while (fgets(line, sizeof(line), systemFile) != NULL) {
	
	if(isFirstLine) {
		isFirstLine = 0;
		continue;
	}

	// Counter for quotes
    	int quoteCount = 0;
    
    	// Iterate over the line to find the end of the second entry
    	for (int i = 0; line[i] != '\0'; i++) {
        	if (line[i] == '\"') {
            		quoteCount++;
            		if (quoteCount == 4) {
                		// Null-terminate the string after the second entry
                		line[i + 1] = '\0';
                		break;
            		}
        	}
    	}


        // Search for a match in the baseline
        matchCheck = containsString(baselineFile, line);

        // If no match is found
        if (matchCheck == 0) {

  		// Variables to hold the extracted parts
    		char firstEntry[256];
    		char secondEntry[256];
    		char filePath[512];
    
    		// Pointer to help with parsing
    		char *token;
    		const char *delimiter = "\",\"";
    
    		// Get the first entry
    		token = strtok(line, delimiter);
    		if (token != NULL) {
        		// Remove leading and trailing quotes from the first entry
        		strncpy(firstEntry, token + 1, strlen(token) - 2);
        		firstEntry[strlen(token) - 2] = '\0';
    		}

    		// Get the second entry
    		token = strtok(NULL, delimiter);
    		if (token != NULL) {
        		// Remove the trailing quote from the second entry
        		strncpy(secondEntry, token, strlen(token) - 1);
        		secondEntry[strlen(token) - 1] = '\0';
    		}

    		// Combine the entries into a single file path
    		snprintf(filePath, sizeof(filePath), "%s\\%s", secondEntry, firstEntry);
   

            	// Line is not contained in the baseline, write to the added output file
            	fprintf(addFile, "%s\n", filePath);

        }
    }
}