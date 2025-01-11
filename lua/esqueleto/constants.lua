local M = {}

-- OS-specific ignoring files, obtained from gitignore.io
-- `https://www.toptal.com/developers/gitignore/api/windows,macos,linux`
-- Index: Thu Sep 28 20:45:56 BST 2023
M.ignored_os_patterns = {
  "*~",
  "%.fuse_hidden*",
  "%.directory",
  "%.Trash-*",
  "%.nfs*",
  "%.DS_Store",
  "%.AppleDouble",
  "%.LSOverride",
  "Icon",
  -- "%._*",
  "%.DocumentRevisions-V100",
  "%.fseventsd",
  "%.Spotlight-V100",
  "%.TemporaryItems",
  "%.Trashes",
  "%.VolumeIcon%.icns",
  "%.com%.apple%.timemachine%.donotpresent",
  "%.AppleDB",
  "%.AppleDesktop",
  "Network Trash Folder",
  "Temporary Items",
  "%.apdisk",
  "*%.icloud",
  "Thumbs%.db",
  "Thumbs%.db:encryptable",
  "ehthumbs%.db",
  "ehthumbs_vista%.db",
  "*%.stackdump",
  "[Dd]esktop%.ini",
  "$RECYCLE%.BIN/",
  "*%.cab",
  "*%.msi",
  "*%.msix",
  "*%.msm",
  "*%.msp",
  "*%.lnk",
}

return M
