using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.Threading;
using System.Text;
using System.Diagnostics;


namespace Baseline_Script
{
    class Program
    {

        private static readonly object ConsoleLock = new object();

        static void Main(string[] args)
        {

            // Create a new Stopwatch
            Stopwatch stopwatch = new Stopwatch();

            // Start the stopwatch
            stopwatch.Start();

            string baselinePath = "C:/baseline.csv";

            string addPath = "C:/added.txt";
            string modPath = "C:/modified.txt";

            using (StreamWriter writer = new StreamWriter(addPath, true)) { writer.WriteLine("Added Files: \n\n"); }
            using (StreamWriter writer = new StreamWriter(modPath, true)) { writer.WriteLine("Modified Files: \n\n"); }


            string[] allFiles = GetAllFiles("C:/Windows");



            
            // Split the allFiles array into 6 chunks
            int chunkSize = (int)Math.Ceiling((double)allFiles.Length / 6);
            var fileChunks = Enumerable.Range(0, 6).Select(i => allFiles.Skip(i * chunkSize).Take(chunkSize).ToArray()).ToArray();

            // Process each chunk in parallel
            Parallel.ForEach(fileChunks, filesChunk =>
            {
                foreach (string filePath in filesChunk)
                {
                    lock (ConsoleLock)
                    {
                        Console.WriteLine($"Thread ID {Thread.CurrentThread.ManagedThreadId}: {filePath}");

                        string csvMatch = GetCSVLine(baselinePath, filePath);

                        if (csvMatch == "NULL") {
                            using (StreamWriter writer = new StreamWriter(addPath, true)) { writer.WriteLine(filePath + "\n"); }

                        } else {
                            string hash = csvMatch.Substring(csvMatch.IndexOf(',') + 1);
                            if(hash == "NULL") {
                                using (StreamWriter writer = new StreamWriter(modPath, true)) { writer.WriteLine(filePath + "   - no hash to compare from baseline \n"); }
                            } else if (hash != CalculateSHA256(filePath)) {
                                using (StreamWriter writer = new StreamWriter(modPath, true)) { writer.WriteLine(filePath + "\n"); }
                            }



                        }

                    }

                }
            });

            // Stop the stopwatch
            stopwatch.Stop();

            // Get the elapsed time
            TimeSpan elapsedTime = stopwatch.Elapsed;

            // Output the elapsed time
            using (StreamWriter writer = new StreamWriter(addPath, true)) { writer.WriteLine($"Execution Time: {elapsedTime.TotalMilliseconds} milliseconds"); }




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

        static string GetCSVLine(string filePath, string searchString)
        {
            try
            {
                using (StreamReader reader = new StreamReader(filePath))
                {
                    while (!reader.EndOfStream)
                    {
                        string line = reader.ReadLine();
                        if (line != null)
                        {
                            string[] fields = line.Split(',');
                            if (fields.Length > 0 && fields[0] == searchString)
                            {
                                return line;
                            }
                        }
                    }
                }
                return "NULL";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred: {ex.Message}");
                return "NULL";
            }
        }


    }


}






    
