/**
 * C program to list all files and sub-directories in a directory.
 */

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>


void listFiles(const char *path);

int main()
{


    listFiles("C:/Windows/System32");

    return 0;
}


/**
 * Lists all files and sub-directories at given path.
 */
void listFiles(const char *path)
{
    struct dirent *dp;
    DIR *dir = opendir(path);

    // Unable to open directory stream
    if (!dir) 
        return; 

    while ((dp = readdir(dir)) != NULL)
    {
        printf("%s\n", dp->d_name);
    }

    // Close directory stream
    closedir(dir);
}