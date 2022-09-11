# Original by Daniel L. Greenwald
# https://www.dlgreenwald.com/misc/capitalizing-titles-in-bibtex
# Modified by Garrett Dash Nelson and Michele Wiseman
# Converts bibtex entries to title case

# Additional notes:
# You may encounter an error with the new regex version. This code works with pip install regex==2022.3.2
# Assuming files are defined in the correct path, run with: python bibTitleCase.py


import re
from titlecase import titlecase

# Input and output files
my_file = 'library.bibtex'  # change as needed
new_file = 'library-capitalized.bibtex' # in case you don't want to overwrite

# Match title, Title, booktitle, Booktitle fields
pattern = re.compile(r'(\W*)(title|journal)\s*=\s*{(.*)},')

# Read in old file
with open(my_file, 'r') as fid:
    lines = fid.readlines()

# Search for title strings and replace with titlecase
newlines = []
for line in lines:
    # Check if line contains title
    match_obj = pattern.match(line)
    if match_obj is not None:
        # Need to "escape" any special chars to avoid misinterpreting them in the regular expression.
        oldtitle = re.escape(match_obj.group(3))

        # Apply titlecase to get the correct title.
        newtitle = titlecase(match_obj.group(3))

        # Replace and add to list
        p_title = re.compile(oldtitle)
        newline = p_title.sub(newtitle, line)
        newlines.append(newline)
    else:
        # If not title, add as is.
        newlines.append(line)

# Print output to new file
with open (new_file, 'w') as fid:
    fid.writelines(newlines)
