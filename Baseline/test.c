#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/types.h>
#include <string.h>
#include "C:\Program Files\OpenSSL-Win64\include\openssl\sha.h"
#include "C:\Program Files\OpenSSL-Win64\include\openssl\macros.h"

void listFilesRecursively(const char *basePath) {
    char path[1000];
    struct dirent *en;
    DIR *dr = opendir(basePath);

    if (!dr) {
        return;
    }

    while ((en = readdir(dr)) != NULL) {
        if (strcmp(en->d_name, ".") == 0 || strcmp(en->d_name, "..") == 0) {
            continue; // Skip current directory and parent directory entries
        }
        
        snprintf(path, sizeof(path), "%s/%s", basePath, en->d_name);

        if (en->d_type == DT_DIR) {
            // If it's a directory, recursively list files in it
            listFilesRecursively(path);
        } else if (en->d_type == DT_REG) {
            // If it's a regular file, print its path
            printf("%s\n", path);
        }
    }

    closedir(dr);
}

int main() {
    // Define as "C:/" to get proper full file path for input file path
    listFilesRecursively("C:/Users/CCD/Desktop"); // Start listing files recursively from the current directory
    return 0;
}