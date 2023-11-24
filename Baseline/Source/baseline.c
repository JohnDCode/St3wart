#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <limits.h>
#include <time.h>

void listFiles(const char *dirPath, const char *outputFile);

int main() {
    clock_t start_time = clock();


    const char *directoryPath = "C:/Windows";  // Replace with the path to your directory
    const char *outputFilePath = "baseline.txt";

    listFiles(directoryPath, outputFilePath);

    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;

    printf("File paths exported to %s\n", outputFilePath);
    printf("Time taken: %.4f seconds\n", elapsed_time);

    return 0;
}

void listFiles(const char *dirPath, const char *outputFile) {
    DIR *dir;
    struct dirent *entry;

    // Open the directory
    dir = opendir(dirPath);

    // Check if the directory can be opened
    if (dir == NULL) {
    	perror("Error opening directory");
    	printf("Directory path: %s\n", dirPath);
    	return;
    }


    // Open or create the output file for writing
    FILE *outputFilePtr = fopen(outputFile, "a");  // Open in append mode
    if (outputFilePtr == NULL) {
        perror("Error opening output file");
        closedir(dir);
        exit(EXIT_FAILURE);
    }

    // Traverse the directory and write file paths to the output file
    while ((entry = readdir(dir)) != NULL) {
        // Ignore "." and ".." directories
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            // Construct the full path of the file
            char filePath[PATH_MAX];
            snprintf(filePath, sizeof(filePath), "%s/%s", dirPath, entry->d_name);

            // Write the full path to the output file
            if (((strstr(filePath, ".exe") != NULL) || (strstr(filePath, ".bat") != NULL) || (strstr(filePath, ".com") != NULL) || (strstr(filePath, ".msi") != NULL) || (strstr(filePath, ".js") != NULL) || (strstr(filePath, ".vbs") != NULL) || (strstr(filePath, ".ps1") != NULL) || (strstr(filePath, ".zip") != NULL) || (strstr(filePath, ".rar") != NULL) || (strstr(filePath, ".tar") != NULL) || (strstr(filePath, ".7z") != NULL) || (strstr(filePath, ".lnk") != NULL) || (strstr(filePath, ".mp3") != NULL) || (strstr(filePath, ".mp4") != NULL) || (strstr(filePath, ".avi") != NULL)) && ((strstr(filePath, "C:/Windows/servicing") == NULL) && (strstr(filePath, "C:/Windows/WinSxS") == NULL))) {
               	fprintf(outputFilePtr, "%s\n", filePath);
            }
 

            // If the entry is a directory, recursively call listFiles
            if (entry->d_type == DT_DIR) {
                listFiles(filePath, outputFile);
            }
        }
    }

    // Close the directory and the output file
    closedir(dir);
    fclose(outputFilePtr);
}
