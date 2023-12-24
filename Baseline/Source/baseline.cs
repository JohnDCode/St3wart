using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.Threading;

namespace Baseline_Script
{
    class Program
    {

        private static readonly object ConsoleLock = new object();

        static void Main(string[] args)
        {
            string csvPath = "C:/baseline.csv";
            StreamWriter writer = new StreamWriter(csvPath);
            writer.WriteLine("File Path,Hash");


            string[] allFiles = GetAllFiles("C:/Windows");

            // Split the allFiles array into 4 chunks
            int chunkSize = (int)Math.Ceiling((double)allFiles.Length / 4);
            var fileChunks = Enumerable.Range(0, 4).Select(i => allFiles.Skip(i * chunkSize).Take(chunkSize).ToArray()).ToArray();

            // Process each chunk in parallel
            Parallel.ForEach(fileChunks, filesChunk =>
            {
                foreach (string filePath in filesChunk)
                {
                    lock (ConsoleLock)
                    {
                        writer.WriteLine(filePath + "," + CalculateSHA256(filePath));
                        Console.WriteLine($"Thread ID {Thread.CurrentThread.ManagedThreadId}: {filePath}");
                    }
                    
                }
            });


        }

        static string[] GetAllFiles(string rootDirectory)
        {
            List<string> allFilesList = new List<string>();

            GetAllFilesRecursive(rootDirectory, allFilesList);

            return allFilesList.ToArray();
        }

        static void GetAllFilesRecursive(string directory, List<string> filesList)
        {
            try
            {
                string[] files = Directory.GetFiles(directory);
                filesList.AddRange(files);

                string[] subdirectories = Directory.GetDirectories(directory);
                foreach (string subdirectory in subdirectories)
                {
                    GetAllFilesRecursive(subdirectory, filesList);
                }
            }
            catch (UnauthorizedAccessException ex)
            {
                Console.WriteLine($"Access to the path '{ex.Message}' is denied.");
                // Continue with other directories
            }
            catch (DirectoryNotFoundException ex)
            {
                Console.WriteLine($"Directory not found: '{ex.Message}'.");
                // Continue with other directories
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting files: {ex.Message}");
                // Continue with other directories
            }
        }

        static string CalculateSHA256(string filePath)
        {
            try
            {
                using (var sha256 = SHA256.Create())
                {
                    using (var stream = new BufferedStream(File.OpenRead(filePath), 1200000))
                    {
                        byte[] hashValue = sha256.ComputeHash(stream);
                        return BitConverter.ToString(hashValue).Replace("-", String.Empty);
                    }
                }
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine($"Access to the path '{filePath}' is denied. Returning null.");
                return "NULL";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating SHA-256 hash: {ex.Message}. Returning null.");
                return "NULL";
            }
        }


    }
}
