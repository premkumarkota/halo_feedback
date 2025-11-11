# Publishing to pub.dev - Step-by-Step Guide

## 📋 Pre-Publication Checklist

Before publishing, ensure you have:

- [ ] Google account (for pub.dev login)
- [ ] Git repository (GitHub/GitLab) - **REQUIRED**
- [ ] All code tested and working
- [ ] README.md is complete
- [ ] CHANGELOG.md is updated
- [ ] LICENSE file is present
- [ ] pubspec.yaml has homepage/repository

---

## Step 1: Create GitHub Repository

### 1.1 Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `halo_feedback`
3. Description: "Cross-platform MDM feedback plugin for Flutter"
4. Choose Public or Private (Public recommended for pub.dev)
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

### 1.2 Initialize Git and Push

```bash
# Navigate to your plugin directory
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback"

# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial release v0.0.1"

# Add remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/halo_feedback.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Important:** Replace `YOUR_USERNAME` with your actual GitHub username!

---

## Step 2: Update pubspec.yaml

Update the `homepage` and `repository` fields in `pubspec.yaml`:

```yaml
name: halo_feedback
description: "Cross-platform MDM (Mobile Device Management) feedback plugin for Flutter..."
version: 0.0.1
homepage: https://github.com/YOUR_USERNAME/halo_feedback
repository: https://github.com/YOUR_USERNAME/halo_feedback
issue_tracker: https://github.com/YOUR_USERNAME/halo_feedback/issues
```

**Replace `YOUR_USERNAME` with your GitHub username!**

---

## Step 3: Verify Package Name Availability

### 3.1 Check if Name is Available

Visit: https://pub.dev/packages/halo_feedback

- If it shows "404 - Package not found" → ✅ Name is available
- If it shows a package page → ❌ Name is taken (choose different name)

### 3.2 If Name is Taken

If `halo_feedback` is taken, you can:
1. Choose a different name (e.g., `halo_mdm_feedback`, `halo_device_feedback`)
2. Contact the package owner to transfer ownership
3. Use a more specific name

**Update `name` in `pubspec.yaml` if you change it!**

---

## Step 4: Create pub.dev Account

### 4.1 Sign Up

1. Go to https://pub.dev
2. Click "Sign in" (top right)
3. Sign in with your **Google account**
4. Complete your profile:
   - Add your name
   - Add email (if not auto-filled)
   - Verify email if prompted

### 4.2 Verify Account

- Check your email for verification link
- Complete any required verification steps

---

## Step 5: Final Checks

### 5.1 Run Dry Run

```bash
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback"
flutter pub publish --dry-run
```

**Expected Output:**
- ✅ Should show "Package validation found X potential issues" (warnings are OK)
- ✅ Should show file list
- ❌ If it shows errors, fix them before proceeding

### 5.2 Fix Any Issues

Common issues and fixes:

**Issue: Missing homepage/repository**
```yaml
# Fix: Add to pubspec.yaml
homepage: https://github.com/YOUR_USERNAME/halo_feedback
repository: https://github.com/YOUR_USERNAME/halo_feedback
```

**Issue: LICENSE file empty**
- Ensure LICENSE file has MIT license text (already fixed)

**Issue: CHANGELOG.md has TODO**
- Update CHANGELOG.md with release notes (already fixed)

**Issue: Unused imports**
- These are warnings, not errors - OK to publish with warnings

### 5.3 Run Tests

```bash
flutter test
```

**Expected:** All tests should pass ✅

### 5.4 Run Analysis

```bash
flutter analyze
```

**Expected:** Only warnings (unused imports), no errors ✅

---

## Step 6: Publish to pub.dev

### 6.1 Final Dry Run

```bash
flutter pub publish --dry-run
```

Review the output:
- Check file list
- Verify no critical errors
- Warnings are acceptable

### 6.2 Actual Publish

```bash
flutter pub publish
```

**You will be prompted:**

1. **"Pub will upload your package to pub.dev. Do you want to continue? (y/N)"**
   - Type: `y` and press Enter

2. **"Uploading..."**
   - Wait for upload to complete

3. **"Package uploaded successfully!"**
   - ✅ Success!

### 6.3 If Authentication Required

If prompted for authentication:

1. You'll see a URL like: `https://accounts.google.com/o/oauth2/auth?...`
2. Copy the URL and open in browser
3. Sign in with Google account
4. Grant permissions
5. Copy the authorization code
6. Paste it back in terminal

---

## Step 7: Verify Publication

### 7.1 Check Package Page

1. Visit: https://pub.dev/packages/halo_feedback
2. Verify:
   - ✅ Package name is correct
   - ✅ Description is correct
   - ✅ Version is 0.0.1
   - ✅ README is displayed
   - ✅ All files are listed

### 7.2 Test Installation

Create a test project:

```bash
# Create test project
flutter create test_halo_feedback
cd test_halo_feedback

# Add dependency
# Edit pubspec.yaml and add:
# dependencies:
#   halo_feedback: ^0.0.1

flutter pub get
```

If `flutter pub get` succeeds, publication was successful! ✅

---

## Step 8: Post-Publication

### 8.1 Create Git Tag

```bash
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback"
git tag v0.0.1
git push --tags
```

### 8.2 Create GitHub Release (Optional)

1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Tag: `v0.0.1`
4. Title: `v0.0.1 - Initial Release`
5. Description: Copy from CHANGELOG.md
6. Click "Publish release"

### 8.3 Update README Badge

Update README.md with pub.dev badge:

```markdown
[![pub package](https://img.shields.io/pub/v/halo_feedback.svg)](https://pub.dev/packages/halo_feedback)
```

---

## 🎯 Complete Command Sequence

Here's the complete sequence of commands:

```bash
# 1. Navigate to plugin directory
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback"

# 2. Initialize git (if not done)
git init
git add .
git commit -m "Initial release v0.0.1"

# 3. Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/halo_feedback.git
git branch -M main
git push -u origin main

# 4. Test everything
flutter test
flutter analyze
flutter pub publish --dry-run

# 5. Publish
flutter pub publish

# 6. Create tag
git tag v0.0.1
git push --tags
```

---

## ⚠️ Important Notes

### Before Publishing

1. **Package Name**: Must be unique on pub.dev
2. **Version**: Follow semantic versioning (MAJOR.MINOR.PATCH)
3. **Homepage/Repository**: Must be valid URLs
4. **LICENSE**: Must be present and valid
5. **README.md**: Will be displayed on pub.dev - make it good!

### After Publishing

1. **Version Updates**: You cannot change published versions
2. **Breaking Changes**: Increment MAJOR version (1.0.0, 2.0.0, etc.)
3. **New Features**: Increment MINOR version (0.1.0, 0.2.0, etc.)
4. **Bug Fixes**: Increment PATCH version (0.0.2, 0.0.3, etc.)

### Versioning Rules

- **0.0.1** → **0.0.2**: Bug fixes
- **0.0.1** → **0.1.0**: New features (backward compatible)
- **0.0.1** → **1.0.0**: Breaking changes

---

## 🐛 Troubleshooting

### Error: Package name already exists

**Solution:**
- Choose a different name
- Update `name` in `pubspec.yaml`
- Update all documentation

### Error: Missing required files

**Solution:**
- Ensure README.md exists
- Ensure CHANGELOG.md exists
- Ensure LICENSE exists

### Error: Invalid pubspec.yaml

**Solution:**
- Run `flutter pub publish --dry-run` to see specific errors
- Fix syntax errors
- Ensure all required fields are present

### Error: Unauthorized

**Solution:**
- Ensure you're logged in to pub.dev
- Check Google account permissions
- Try logging out and back in

### Error: Repository not found

**Solution:**
- Ensure GitHub repository exists
- Check repository URL in pubspec.yaml
- Ensure repository is public (or you have proper access)

---

## 📝 Example: Complete Publishing Session

```bash
# Step 1: Navigate
cd "C:\Users\Prem Kumar Kota\Desktop\halo_feedback"

# Step 2: Test
flutter test
# Output: All tests passed!

# Step 3: Analyze
flutter analyze
# Output: Only warnings (OK)

# Step 4: Dry run
flutter pub publish --dry-run
# Output: Package validation found X potential issues (warnings OK)

# Step 5: Publish
flutter pub publish
# Prompt: "Do you want to continue? (y/N)"
# Type: y
# Output: "Package uploaded successfully!"

# Step 6: Verify
# Visit: https://pub.dev/packages/halo_feedback
# ✅ Should see your package!

# Step 7: Tag
git tag v0.0.1
git push --tags
```

---

## 🎉 Success!

Once published, your package will be available at:
**https://pub.dev/packages/halo_feedback**

Users can install it with:
```yaml
dependencies:
  halo_feedback: ^0.0.1
```

---

## 📚 Additional Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [Flutter Package Publishing](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#publish)

---

## 🔄 Updating the Package

When you need to publish an update:

1. Update version in `pubspec.yaml` (e.g., `0.0.1` → `0.0.2`)
2. Update `CHANGELOG.md` with new changes
3. Commit changes: `git commit -m "Release v0.0.2"`
4. Publish: `flutter pub publish`
5. Create tag: `git tag v0.0.2 && git push --tags`

---

Good luck with your publication! 🚀

