#!/bin/bash

folder_name="data"

# Attempt to create the folder
mkdir "$folder_name" 2>/dev/null

scrapy runspider ./scripts/grades.py --nolog &
scrapy runspider ./scripts/gpa.py --nolog &