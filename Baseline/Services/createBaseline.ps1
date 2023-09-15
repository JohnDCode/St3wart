$services = Get-Service | Select-Object Name, DisplayName, Status, ServiceType, StartType, ProcessId, Description, DependentServices, ServicesDependedOn, MachineName, CanPauseAndContinue, CanShutdown, CanStop, Site, RequiredServices, CanHandlePowerEvent, CanHandleSessionChangeEvent, CanHandleSuspendResume, CanHandleSessionChange, ExitCode, StartName, SiteName, PathName, PagedMemorySize, PeakPagedMemorySize, PrivateMemorySize, PeakVirtualMemorySize, PeakWorkingSet, VirtualMemorySize, WorkingSet, StartTime


$services | Export-Csv -Path ".\export.csv" -NoTypeInformation