# Windows Build Error Fix - Path Length Limit

## Problem

Windows has a 260-character path length limit that causes build failures when project paths are too long.

**Error:**
```
error MSB3491: Path exceeds the OS max path limit. The fully qualified file name must be less than 260 characters.
```

---

## Solutions (Choose One)

### ✅ Solution 1: Enable Long Path Support in Windows (Recommended)

This allows Windows to handle paths longer than 260 characters.

#### Steps:

1. **Open Registry Editor** (Run as Administrator):
   - Press `Win + R`
   - Type `regedit` and press Enter
   - Click "Yes" when prompted

2. **Navigate to:**
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem
   ```

3. **Enable Long Path Support:**
   - Find `LongPathsEnabled` (if it doesn't exist, create it)
   - Right-click → New → DWORD (32-bit) Value
   - Name it: `LongPathsEnabled`
   - Set value to: `1`
   - Click OK

4. **Restart your computer**

5. **Verify:**
   ```powershell
   # Run in PowerShell (as Admin)
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
   ```

#### Alternative: Use Group Policy (Windows 10 Pro/Enterprise)

1. Press `Win + R`, type `gpedit.msc`
2. Navigate to: `Computer Configuration → Administrative Templates → System → Filesystem`
3. Enable: **"Enable Win32 long paths"**
4. Restart computer

---

### ✅ Solution 2: Move Project to Shorter Path (Quick Fix)

Move your project to a shorter path:

#### Option A: Move to C:\dev
```powershell
# Create shorter path
New-Item -ItemType Directory -Path "C:\dev" -Force

# Move project
Move-Item "C:\Users\Prem Kumar Kota\Desktop\halo_feedback" "C:\dev\halo_feedback"
```

#### Option B: Use Shorter Folder Names
```powershell
# Rename to shorter names
Rename-Item "halo-files" "halo"
Rename-Item "halo_feedback" "halo_fb"
```

**New path:** `C:\dev\halo_fb\halo` (much shorter!)

---

### ✅ Solution 3: Clean Build and Retry

Sometimes cleaning the build folder helps:

```powershell
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback\halo-files"
flutter clean
flutter pub get
flutter run -d windows
```

---

### ✅ Solution 4: Use PowerShell with Long Path Support

Run PowerShell with long path support enabled:

```powershell
# Run PowerShell as Administrator
# Then run:
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Restart PowerShell and try build again
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback\halo-files"
flutter clean
flutter run -d windows
```

---

## Recommended Approach

**For immediate fix:** Use Solution 2 (move to shorter path)

**For permanent fix:** Use Solution 1 (enable long path support)

---

## Verification

After applying a solution, verify the build works:

```powershell
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback\halo-files"
flutter clean
flutter pub get
flutter run -d windows
```

---

## Notes

- **Long path support** requires Windows 10 version 1607 or later
- **Admin rights** are required to enable long path support
- **Restart** is required after enabling long path support
- **Shorter paths** are always better for compatibility

---

## Quick Command to Enable Long Paths (Run as Admin)

```powershell
# Run PowerShell as Administrator, then:
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Type DWORD -Force
Restart-Computer
```

After restart, your build should work!

