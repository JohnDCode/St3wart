#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <limits.h>
#include <time.h>

void listFiles(const char *dirPath, const char *outputFile);
int isLinePresent(const char *line, FILE *file);
void compareFiles(const char *file1, const char *file2, const char *outputFile);

int main() {
    clock_t start_time = clock();


    const char *directoryPath = "C:/Windows";  // Replace with the path to your directory
    const char *systemFilePath = "system.txt";
    const char *baselineFilePath = "baseline.txt";
    const char *outputFilePath = "output.txt";

    listFiles(directoryPath, systemFilePath);
    
    printf("Finished collecting system files");

    compareFiles(systemFilePath, baselineFilePath, outputFilePath);

    clock_t end_time = clock();
    double elapsed_time = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;

    printf("File paths exported to %s\n", systemFilePath);
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
            if ((strstr(filePath, "C:/Windows/servicing") == NULL) && (strstr(filePath, "C:/Windows/WinSxS") == NULL)) {
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












// Function to check if a line is present in the second file
int isLinePresent(const char *line, FILE *file) {
    char buffer[1000];
    fseek(file, 0, SEEK_SET);  // Reset file position to the beginning
    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        if (strcmp(line, buffer) == 0) {
            // Line is present in the second file
            return 1;
        }
    }
    // Line is not present in the second file
    return 0;
}





// Function to compare files and write differing lines to the output file
void compareFiles(const char *file1, const char *file2, const char *outputFile) {
    FILE *fp1, *fp2, *outFile;
    char line[1000];

    // Open the input files
    fp1 = fopen(file1, "r");
    if (fp1 == NULL) {
        perror("Error opening file 1");
        exit(EXIT_FAILURE);
    }

    fp2 = fopen(file2, "r");
    if (fp2 == NULL) {
        perror("Error opening file 2");
        fclose(fp1);
        exit(EXIT_FAILURE);
    }

    // Open the output file
    outFile = fopen(outputFile, "w");
    if (outFile == NULL) {
        perror("Error opening output file");
        fclose(fp1);
        fclose(fp2);
        exit(EXIT_FAILURE);
    }

    // Read lines from the first file and check if each line is present in the second file
    while (fgets(line, sizeof(line), fp1) != NULL) {
        if (!isLinePresent(line, fp2)) {
            // Line is not present in the second file, write to the output file
            fprintf(outFile, "%s", line);
        }
    }

    // Close the files
    fclose(fp1);
    fclose(fp2);
    fclose(outFile);
}