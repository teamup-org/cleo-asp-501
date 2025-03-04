#!/bin/bash

folder_name="data"

# Attempt to create the folder
mkdir "$folder_name" 2>/dev/null

python3 scripts/grades.py
python3 scripts/gpa.py