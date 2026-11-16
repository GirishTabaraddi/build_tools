pip install uv
uv python install 3.12 --install-dir "$DEST"

# normalize the versioned folder name to "python"
if [ ! -d "$DEST/python" ]; then
    mv "$DEST"/cpython-3.12.*-linux-* "$DEST/python"
fi
rm -f "$DEST"/cpython-3.12-linux-*   # drop the version alias symlink

"$DEST/python/bin/python3.12" --version