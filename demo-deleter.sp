#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo =
{
    name = "TF2 Demo Deleter",
    author = "Fuko",
    description = "Deletes *.dem files in the main tf/ directory on server startup.",
    version = PLUGIN_VERSION,
    url = "https://www.fullbuff.gg/"
};

public void OnPluginStart()
{
    LogMessage("[DEM Deleter] Plugin starting, initiating DEM file cleanup in tf/ directory...");

    // Get the path to the tf/ directory
    char tfDirPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, tfDirPath, sizeof(tfDirPath), "../../"); // Navigate from /addons/sourcemod/ to /tf/
    
    LogMessage("[DEM Deleter] Scanning directory: %s", tfDirPath);
    
    // First: Log all files in the directory to see what's actually there
    DirectoryListing dirList = OpenDirectory(tfDirPath);
    if (dirList != null)
    {
        char filename[PLATFORM_MAX_PATH];
        FileType fileType;
        //LogMessage("[DEM Deleter] Files in directory:");
        
        while (dirList.GetNext(filename, sizeof(filename), fileType))
        {
            if (fileType == FileType_File)
            {
                LogMessage("[DEM Deleter] Found file: %s", filename);
            }
        }
        
        delete dirList;
    }
    
    // Now proceed with deletion
    DirectoryListing dir = OpenDirectory(tfDirPath);
    
    if (dir == null)
    {
        LogError("[DEM Deleter] Failed to open directory: %s. Cannot delete DEM files.", tfDirPath);
        return;
    }

    char filename[PLATFORM_MAX_PATH];
    FileType fileType;
    int deletedCount = 0;
    int failedCount = 0;

    // Loop through all entries in the directory
    while (dir.GetNext(filename, sizeof(filename), fileType))
    {
        // We only care about files
        if (fileType == FileType_File)
        {
            int len = strlen(filename);
            
            // Better check for .dem extension - using string comparison
            if (len > 4)
            {
                char ext[5];
                strcopy(ext, sizeof(ext), filename[len-4]); // Get last 4 characters
                
                //LogMessage("[DEM Deleter] File extension check: %s has ext '%s'", filename, ext);
                
                if (StrEqual(ext, ".dem", false))
                {
                    char fullPath[PLATFORM_MAX_PATH];
                    // Construct the full path to the file
                    Format(fullPath, sizeof(fullPath), "%s%s", tfDirPath, filename);

                    //LogMessage("[DEM Deleter] Attempting to delete DEM file: %s", fullPath);

                    // Attempt to delete the file
                    if (DeleteFile(fullPath))
                    {
                        LogMessage("[DEM Deleter] Successfully deleted: %s", filename);
                        deletedCount++;
                    }
                    else
                    {
                        LogError("[DEM Deleter] Failed to delete: %s (Error: %d)", filename);
                        failedCount++;
                    }
                }
            }
        }
    }

    // Close the directory handle
    delete dir;

    LogMessage("[DEM Deleter] Cleanup finished. Deleted %d DEM files, failed to delete %d files.", deletedCount, failedCount);
}

/**
 * @brief Called on the next server frame after being requested.
 * Handles the actual unloading of this plugin.
 */
public void Frame_UnloadSelf()
{
    LogMessage("[DEM Deleter AU] Executing deferred self-unload.");
    
    // Execute the unload command via the server console
    LogMessage("[DEM Deleter AU] Issuing server command to unload self");
    ServerCommand("sm plugins unload demo-deleter.smx");

    // Execution effectively stops here for this plugin instance, as it has just
    // requested its own unloading from the SourceMod core.
}
// No other functions are needed for this specific task.