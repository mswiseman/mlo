# Original by Daniel L. Greenwald
# http://dlgreenwald.weebly.com/blog/capitalizing-titles-in-bibtex
# Modified by Garrett Dash Nelson
# Converts bibtex entries to title case

import re
from titlecase import titlecase

# Input and output files
my_file = 'library.bibtex'
new_file = 'library-capitalized.bibtex' # in case you don't want to overwrite

# Match title, Title, booktitle, Booktitle fields
pattern = re.compile(r'(\W*)([Bb]ook)?([Tt]itle = {+)(.*)(}+,)')

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
        oldtitle = re.escape(match_obj.group(4))

        # Apply titlecase to get the correct title.
        newtitle = titlecase(match_obj.group(4))

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
