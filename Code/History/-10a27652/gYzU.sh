#!/bin/bash

# Get the current working directory from VS Code
# This finds the most recent .tex file opened in VS Code
tex_file=$(lsof -c code | grep '\.tex$' | awk '{print $9}' | head -1)

if [ -z "$tex_file" ]; then
    notify-send "No LaTeX file found" "Open a .tex file in VS Code first"
    exit 1
fi

# Get the directory and filename without extension
tex_dir=$(dirname "$tex_file")
tex_name=$(basename "$tex_file" .tex)

# Look for PDF in root or build directory
if [ -f "$tex_dir/$tex_name.pdf" ]; then
    pdf_file="$tex_dir/$tex_name.pdf"
elif [ -f "$tex_dir/build/$tex_name.pdf" ]; then
    pdf_file="$tex_dir/build/$tex_name.pdf"
else
    notify-send "PDF not found" "Compile the LaTeX file first"
    exit 1
fi

# Open with Zathura
zathura "$pdf_file" &