#!/bin/sh
# This command will rename the files in cwd by replace ".", " " with "-" and
# change uppercase characters to lowercase.

# URL: https://bbs.archlinux.org/viewtopic.php?id=36305
# URL: https://unix.stackexchange.com/questions/56771/replace-dots-with-underscores-in-filenames-leaving-extension-intact
# URL: http://blog.mc-thias.org/?title=rename-files-from-upper-case-filename-to&more=1&c=1&tb=1&pb=1
ls | while read -r file
do
    #mv -v "$FILE" `echo $FILE | tr ' ' '_' | tr -d '[{}(),\!]' | tr -d "\'" | tr '[A-Z]' '[a-z]' | sed 's/_-_/_/g'`;
    newname=$(echo $file | tr [:upper:] [:lower:] | tr '.' '_' | tr ' ' '_' | sed 's/\(.*\)_\([^_]*\)$/\1.\2/g')
    [ "$newname" != "$file" ] && mv "$file" "$newname"
done

ls;
exit;
