#!/usr/bin/env bash
#############################################################################
#███████╗ █████╗ ██╗   ██╗    ██╗    ██╗██╗  ██╗ █████╗ ████████╗██████╗ ██╗#
#██╔════╝██╔══██╗╚██╗ ██╔╝    ██║    ██║██║  ██║██╔══██╗╚══██╔══╝╚════██╗██║#
#███████╗███████║ ╚████╔╝     ██║ █╗ ██║███████║███████║   ██║     ▄███╔╝██║#
#╚════██║██╔══██║  ╚██╔╝      ██║███╗██║██╔══██║██╔══██║   ██║     ▀▀══╝ ╚═╝#
#███████║██║  ██║   ██║       ╚███╔███╔╝██║  ██║██║  ██║   ██║     ██╗   ██╗#
#╚══════╝╚═╝  ╚═╝   ╚═╝        ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝     ╚═╝   ╚═##
#############################################################################
#Title:		Say What
#Author:	Brian Zamorano

START_OFF_POINT=""
END_POINT=""
READING_SPEED=260

usage(){
  echo '[DESCRIPTION]
Convert your epub/mobi/pdf/txt files to MP3 for "reading" on the go! (Mac OSX only) 

[PARAMETERS]
-f MANDATORY: provide FILE to convert into an "audiobook"

-s Indicates a starting point for your "audiobook". When using this option, please enter your text between quotation " marks. 

-e Set end point to finish reading. Helpful when you only want to listen to a few chapters at a time. When using this option please enter your text between quotation marks.

-r Sets the reading speed (default value is 260) - Recommended values are between 250-300.

-h Prints out this usage message summarizing these command-line options, then exits

[EXAMPLE USAGE]
$ ./say-what.sh -f "EBOOK.mobi" -r 275 -s "Perry sat on the couch" -e "Chapter 13"

[TODO]
- Better error handling
- Linux support'
}

speed_warning(){
  echo "[ERROR] Invalid reading speed provided."
  usage
  exit 1
}

while getopts :f:s:h:e:r: opt; do
  case $opt in
    f)
      FILE="$OPTARG"
      SANITIZED=${FILE//[^a-zA-Z0-9_]/}
      BASE=(`basename ${SANITIZED%%.*}-bkp`)
      ;;
    s)
      START_OFF_POINT="$OPTARG"
      ;;
    e)
      END_POINT="$OPTARG"
      ;;
    r)
      if [[ $OPTARG -eq $OPTARG ]]; then
        if [[ $OPTARG -gt 0 ]]; then
          READING_SPEED=$OPTARG
        else
          speed_warning
        fi
      else
        speed_warning
      fi
      ;;
    h)
      usage
      ;;
    \?)
      echo "[ERROR] Invalid option: -$OPTARG. Displaying help options." >&2
      usage
      exit 1
      ;;
    :)
      echo "[ERROR] Option -$OPTARG requires an argument. Displaying help options." >&2
      usage
      exit 1
      ;;
    esac
done
shift $(( OPTIND - 1 ));

# Bare minimum sanity check.
if [[ -z "$FILE" ]]; then
  usage
  exit 1
fi

check_prereqs_mac_osx(){
  echo "[INFO] Checking prerequisites [Mac OSX] ..."
  if [ "$(uname)" != "Darwin" ]; then
    echo "[ERROR] Say-What will only sucessfully run on Mac OSX"
    exit 1
  fi
}

check_prereqs_lame(){
  echo "[INFO] Checking prerequisites [lame] ..."
  command -v lame >/dev/null 2>&1 || { echo >&2 "[ERROR] Say-What requires Lame to be installed in order to create MP3s but it is either not installed or we can't find it. Aborting."; exit 1; }
}

check_prereqs_calibre(){
  echo "[INFO] Checking prerequisites [calibre] ..."
  command -v calibre >/dev/null 2>&1 || { echo >&2 "[ERROR] Say-What requires Calibre to convert your e-books but it is either not installed or we can't find it. Aborting."; exit 1; }
}

create_backup_txt() {
  echo "[INFO] Creating backup text for conversion ..."
  cp $FILE $BASE.txt
}

conversion_check(){
  echo "[INFO] Validating e-book ..."
  case "$FILE" in
    *.txt)
      create_backup_txt
      ;;
    *.mobi)
      convert_to_txt
      ;;
    *.epub)
      convert_to_txt
      ;;
    *.pdf)
      convert_to_txt
      ;;
    *)
      echo "[ERROR] Say-What only works on txt, mobi or epub file formats at this time. Sorry for the inconvenience!"
      ;;
  esac
}

convert_to_txt(){
  echo "[INFO] Detected that $FILE is not a txt file. Doing a conversion of $FILE to .txt. "
  ebook-convert "$FILE" $BASE.txt > /dev/null 2>&1
}

get_book_metadata(){
  echo "[INFO] Retrieving ebook metadata ..."
  ebook-meta --to-opf=$BASE.opf --get-cover "$BASE.jpg" "$FILE" > /dev/null 2>&1
  BOOK_TITLE=$(perl -nle 'print $& if m{(?<=title>).*(?=<)}' $BASE.opf)
  BOOK_AUTHOR=$(perl -nle 'print $& if m{(?<=">).*(?=<)}' $BASE.opf | HEAD -1) # Ugh ...
  rm $BASE.opf
}

dictate_text(){
  echo "[INFO] Dictating $BOOK_TITLE to audio. Please be patient. This may take a while ..."
  say -f "$BASE.txt" -r "$READING_SPEED" -v alex -o "$BASE.aiff"
}

convert_to_mp3(){
  echo "[INFO] Converting audio to mp3. Please be patient. This may take a while ..."
  case "$FILE" in
    *.txt)
      lame --quiet -m m "$BASE.aiff" "$BOOK_TITLE-$BOOK_AUTHOR.mp3" --tt "$BOOK_TITLE" --ta "$BOOK_AUTHOR"
      ;;
    *)
      lame --quiet -m m "$BASE.aiff" "$BOOK_TITLE-$BOOK_AUTHOR.mp3" --tt "$BOOK_TITLE" --ta "$BOOK_AUTHOR" --ti "$BASE.jpg"
      ;;
    esac
}

cleanup(){
  if [[ -f $BASE.aiff ]]; then
    rm $BASE.aiff
  fi
  
  if [[ -f $BASE.txt ]]; then
    rm $BASE.txt
  fi
  
  if [[ -f $BASE.jpg ]]; then
    rm $BASE.jpg
  fi
}

trap cleanup EXIT 

start_off_point(){
  if [[ -n "$START_OFF_POINT" ]]; then
    sed -i '' "/$START_OFF_POINT/,\$!d" $BASE.txt
  fi
}

end_point(){
  if [[ -n "$END_POINT" ]]; then
    ## TODO: Find a better way to do this.
    ## Sed'ing inline does not seem to clear out the text as expected in Mac OSX (works well in Linux)
    ## Running the output to a new tmp file and then replacing the tmp txt file seems to do the trick.
    sed "/$END_POINT/q" $BASE.txt > $BASE-tmp.txt 
    mv $BASE-tmp.txt $BASE.txt
  fi
}

success(){
  echo "SUCCESS! Your new \"audiobook\" should be ready now. See you next time!"
}

main(){
  check_prereqs_lame
  check_prereqs_calibre
  check_prereqs_mac_osx
  get_book_metadata
  conversion_check
  start_off_point
  end_point
  dictate_text
  convert_to_mp3
  success
}

main
