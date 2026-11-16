# Curator release packaging

Every GitHub release, including prereleases, must ship a full versioned addon ZIP. Include the latest fixes, the TOC, all required Lua/XML files and media, and the addon notices. A player must be able to extract the ZIP into an empty `Interface/AddOns` and load Curator without any previous download.

Build with `tools/package_release.py` and verify the ZIP before publishing. Keep the optional bilingual gallery and SoftSpoken voice pack as separate downloads. Link the complete ZIP from both README files and describe the changes in both languages in the release notes.
