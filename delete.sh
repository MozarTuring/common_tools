echo $1 $2 # $2 is the filepath that contains filenames to be deleted separated by space
for fname in $(cat "$2"); do
    if [ -e "$1/$fname" ]; then
        echo "Deleting: $1/$fname"
        rm "$1/$fname"
    else
        echo "Not found: $1/$fname"
    fi
done
