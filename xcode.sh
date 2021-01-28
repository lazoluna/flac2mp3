#! /bin/bash

require()
 {
    local program all_ok=1
    for program; do
        if ! type "$program" &>/dev/null; then
            echo "Error: the required program '$program' is not installed or not in PATH"
            all_ok=
        fi
    done
    test "$all_ok" || exit 1
 }

require ffmpeg mktorrent


  #defaults
  INPUT_FOLDER=/mnt/sda1/***/flac2mp3/input #specify input folder
  OUTPUT_FOLDER=/mnt/sda1/***/flac2mp3/output #specify output folder
  DOWN_FOLDER=/mnt/sda1/transmission/downloads #specify your download folder
  # put your default announce url and required flag by your tracker (match numbers) in array below
  ANNOUNCE_URL[1]=https://my.tracker.world/a.../announce # first announce pair will be used as default
  ANNOUNCE_FLAG[1]=PFLAG
  ANNOUNCE_URL[3]=http://tracker.dp.a2m/boyonboy.php/b.../announce
  ANNOUNCE_FLAG[3]=GB
  ANNOUNCE_URL[69]=http://example.nosourceflag.world/d.../announce
  ANNOUNCE_FLAG[69]=

  

setenc ()

 {
	clear
	echo " "
	echo " Choose your desired Output now"
	echo " "
	echo " (1) encode to [MP3 320] & [V0] & [V2]"
	echo " (2) encode to [MP3 320] & [V0]"
	echo " (3) encode to [MP3 320] & [V2]"
	echo " (4) encode to [V0] & [V2]"
	echo " (5) encode to [V320]"
	echo " (6) encode to [V0]"
	echo " (7) encode to [V2]"
	echo " "
	read -r -p "choice: " i
	case $i in
		[1])
			s=" -> will encode to [MP3 320] & [V0] & [V2]"
			t320=1
			tv0=1
			tv2=1
			;;
		[2])
			s=" -> will encode to [MP3 320] & [V0]"
			t320=1
			tv0=1
			tv2=0;;
		[3])
			s=" -> will encode to [MP3 320] & [V2]"
			t320=1
			tv0=0
			tv2=1
			;;
		[4])
			s=" -> will encode to [V0] & [V2]"
			t320=0
			tv0=1
			tv2=1
			;;
		[5])
			s=" -> will encode to [MP3 320]"
			t320=1
			tv0=0
			tv2=0
			;;
		[6])
			s=" -> will encode to [V0]"
			t320=0
			tv0=1
			tv2=0
			;;
		[7])
			s=" -> will encode to [V2]"
			t320=0
			tv0=0
			tv2=1;;
		*)
			setenc
			;;
	esac
 }
 
copyflac ()

 {
	clear
	echo " "	
	read -r -p "would you like to have the FLACs in output folder as well? (y/n) " j
	case $j in
		[yY])
			c=" -> will copy original FLACs to output folder as well"
			optflac=1;;
		[nN])
			c=" -> will not copy original FLACs to output folder"
			optflac=0;;
		*)
			copyflac
			;;
	esac
 }
 
setannounce ()
{
	#this is a bit overload, but it will fix the array if numbers are not consecutive for smoother input in menu
	clear
	echo " "
	num=1
	for INDEX in "${!ANNOUNCE_URL[@]}";	do
		for zz in $INDEX; do
			arrsort[$num]="${ANNOUNCE_URL[$INDEX]}"
			arrsortf[$num]="${ANNOUNCE_FLAG[$INDEX]}"
			echo -n " ($num) "${ANNOUNCE_URL[$INDEX]:0:40}"... "
			if [ "${ANNOUNCE_FLAG[$INDEX]}" != "" ]; then
			echo "Flag: "${ANNOUNCE_FLAG[$INDEX]}""
			else
			echo "no Flag"
			fi
			let num=(num+1)
			done
	done
	echo " "
	let cnt="${#ANNOUNCE_URL[@]}"+1
	read -r -p "please choose your desired announce url: " a
	case $a in
		''|*[!0-9]*) setannounce ;;
		*) 	while [ "$a" -le 0 ] || [ "$a" -ge $cnt ]; do 
				setannounce
			done
			ANNOUNCE="${arrsort[$a]}"
			FLAG="${arrsortf[$a]}";;
	esac
	clear
}
 
#set default announce
num=1
for INDEX in "${!ANNOUNCE_URL[@]}";	do
	for zz in $INDEX; do
		arrsort[$num]="${ANNOUNCE_URL[$INDEX]}"
		arrsortf[$num]="${ANNOUNCE_FLAG[$INDEX]}"
		let num=(num+1)
		done
done
ANNOUNCE="${arrsort[1]}"
FLAG="${arrsortf[1]}"




clear
while true; do
  echo " "
  echo " "
  echo " (1) Batchencode from INPUT to OUTPUT and make .torrents"
  echo " "
  echo " (2) Specific folder in downloads, encode and make .torrent"
  echo " "
  echo " (3) Rebuild .torrent for every folder in OUTPUT"
  echo " "
  echo " (4) Batchshrink from INPUT to [MP3 V0] in OUTPUT (no .torrent)"
  echo " "
  echo " "
  echo " (5) change default announce url for this session"
  echo "    -> now using "${ANNOUNCE:0:40}...""
  if [ "$FLAG" != "" ]; then
	echo "    -> adding source flag: -s "$FLAG""
  else
    echo "    -> adding NO source flag"
  fi
  echo " "
  echo " (00) quit"
  echo " "
  echo " "
  echo -n " choice: "; read f


#####################################################################################################
if [ "$f" = "1" ]; then 

echo " "
setenc
copyflac
clear
	echo " "
	echo "$s"
	echo " "
	echo "$c"
	echo " "
	echo " -> will make a torrent for created folders"
	echo " "
	echo " "
	echo "This will overwrite files in output folder if already exists!"
	echo " "
	echo "Press any key to encode EVERY folder"
	echo "from INPUT: $INPUT_FOLDER" 
	read -n 1 -s -r -p " to OUTPUT: $OUTPUT_FOLDER "
clear
  
  
cd "$INPUT_FOLDER"



for in in *; do
	if [ -d "$in" ]; then
		# Will not run if no directories are available
		echo "  ##INPUT: $in"
		echo "  ########         ***name changing***"
		out=$(echo $in | sed 's/[ \?,-]\?FLAC \?//g' | sed 's/[ \?,-]\?flac \?//g' | sed 's/ \?([ \*]\?)//g' | sed 's/ \?\[[ \*]\?\]//g' | sed 's/ \?([ \*]\?)//g' | sed 's/^ *//;s/ *$//')
		echo "  #OUTPUT: $out"
				
		set -euo pipefail
		IFS=$'\n'

		# expand input path
		function abspath {
			if [[ -d "$in" ]]
				then
					pushd "$in" >/dev/null
					pwd
					popd >/dev/null
				elif [[ -e $in ]]
				then
					pushd "$(dirname "$in")" >/dev/null
					echo "$(pwd)/$(basename "$in")"
					popd >/dev/null
				else
					echo "$in" does not exist! >&2
					return 127
			fi
			}

		
# input parameters, the source directory, and the stem of our naming scheme
SOURCE=`abspath $in`

if [ -z "$(ls -A $SOURCE)" ]; then
	echo " "   
	echo "  #####>>>>>  skipping empty folder"
	echo "-->: $SOURCE"
	echo "  #####>>>>>  skipping empty folder"
	echo " "
	else
		STEM=$out
	
		# naming scheme completed with formats
		FLAC_NAME="$STEM [FLAC]"
		M_320_NAME="$STEM [MP3 320]"
		M_V0_NAME="$STEM [MP3 V0]"
		M_V2_NAME="$STEM [MP3 V2]"

		# paths to our encoded formats
		FLAC_PATH="$OUTPUT_FOLDER/$FLAC_NAME"
		M_320_PATH="$OUTPUT_FOLDER/$M_320_NAME"
		M_V0_PATH="$OUTPUT_FOLDER/$M_V0_NAME"
		M_V2_PATH="$OUTPUT_FOLDER/$M_V2_NAME"

		if [ "$t320" = "1" ]; then
		    rm -rf "$M_320_PATH"
			mkdir -p "$M_320_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_320_PATH/{}" ';'
		fi
		if [ "$tv0" = "1" ]; then
		    rm -rf "$M_V0_PATH"
			mkdir -p "$M_V0_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_V0_PATH/{}" ';'
		fi
		if [ "$tv2" = "1" ]; then
		    rm -rf "$M_V2_PATH"
			mkdir -p "$M_V2_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_V2_PATH/{}" ';'
		fi

		# encode the MP3 files
		for x in `find . -type d -name "*" -print`; do
 			cd $x
			for file in *.flac
				do
				if [ "$file" != "*.flac" ]; then
					echo "     $file"
					MP3=$(echo "${file%.*}").mp3
					if [ "$t320" = "1" ]; then
					echo -n "       ---> writing 320k "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -b:a 320k ""$M_320_PATH"/"$x"/"$MP3""
					echo "done"
					fi
					if [ "$tv0" = "1" ]; then
					echo -n "       ---> writing V0 "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -q:a 0  ""$M_V0_PATH"/"$x"/"$MP3""
					echo "done"
					fi
					if [ "$tv2" = "1" ]; then
					echo -n "       ---> writing V2 "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -q:a 2  ""$M_V2_PATH"/"$x"/"$MP3""
					echo "done"
					fi
				fi	
			done
				cd "$SOURCE"
		done

	# move over the cover art and the .m3u (or .m3u8) files

	if [ "$t320" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_320_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
		done
		cd "$SOURCE"
	done
	fi
	if [ "$tv0" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_V0_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
		done
		cd "$SOURCE"
	done
	fi
	if [ "$tv2" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_V2_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
			done
		cd "$SOURCE"
	done
	fi
	
	# create a copy of the FLAC folder with your naming scheme and build the torrent files
	if [ "$optflac" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		rm -rf "$FLAC_PATH"
		cp -alT "$SOURCE/." "$FLAC_PATH"
		for name in "$FLAC_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$t320" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_320_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$tv0" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_V0_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$tv2" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_V2_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi

fi
cd "$INPUT_FOLDER"
fi
clear
	if [ "$in" = "*" ]; then
		echo " "
		echo "  #####>>>>> \""$INPUT_FOLDER"\" is empty"
		echo " "
	else
		echo " "
		echo "  #####>>>>> finished succesfully encoding every folder in "
		echo "  #####>>>>> "$INPUT_FOLDER""
		echo "  #####>>>>>  --> to:"
		echo "  #####>>>>> "$OUTPUT_FOLDER""
		echo "  #####>>>>> and making .torrents"
	fi
done


#####################################################################################################
elif [ "$f" = "2" ]; then

clear
cd "$DOWN_FOLDER"


	echo " "
	echo " "
	echo " copy/paste EXACT foldername to encode from download folder to here"
	echo " "
	echo -n "Foldername to encode: "; read in
	while [ ! -d "$in" ]
	do
		echo "Folder does NOT exist, try again: "
		echo -n "Foldername to encode: "; read in
	done
	echo " "
	echo "great, if the foldername contains \"FLAC\" I'll remove it"
	echo -n "would you like to edit the foldername anyway? (y/n) "; read edi
		case $edi in
		[yY])
		echo "                      ok, now compose new folder scheme"
		echo "                      like: Artist - Album (YEAR)"
		echo -n " specify output foldername: "; read out
		;;
		*)
			out=$in;;
		esac
	echo " "

set -euo pipefail
IFS=$'\n'

# expand input path
	function abspath {
		if [[ -d "$in" ]]
		then
			pushd "$in" >/dev/null
			pwd
			popd >/dev/null				
			elif [[ -e $in ]]
			then
				pushd "$(dirname "$in")" >/dev/null
				echo "$(pwd)/$(basename "$in")"
				popd >/dev/null
			else
				echo "$in" does not exist! >&2
				return 127
		fi
	}

SOURCE=`abspath $in`
		
clear
setenc
copyflac
clear
	echo " "
	echo "$s"
	echo " "
	echo "$c"
	echo " "
	echo " -> will make a torrent for created folders"
	echo " "
	echo " "
	echo "This will overwrite files in Outputfolder if already exists!"
	echo " "
	echo "Press any key to encode"
	echo "from INPUT: $DOWN_FOLDER/$in" 
	read -n 1 -s -r -p " to OUTPUT: $OUTPUT_FOLDER "

clear

if [ -z "$(ls -A $SOURCE)" ]; then
	echo " "   
	echo "  #####>>>>>  skipping empty folder"
	echo "-->: $SOURCE"
	echo "  #####>>>>>  skipping empty folder"
	echo " "
	else
	echo "  ##INPUT: $in"
	echo "  ########         ***name changing***"
	out=$(echo $in | sed 's/[ \?,-]\?FLAC \?//g' | sed 's/[ \?,-]\?flac \?//g' | sed 's/ \?([ \*]\?)//g' | sed 's/ \?\[[ \*]\?\]//g' | sed 's/ \?([ \*]\?)//g' | sed 's/^ *//;s/ *$//')
	echo "  #OUTPUT: $out"
	
    STEM=$out
	# naming scheme completed with formats
	FLAC_NAME="$STEM [FLAC]"
	M_320_NAME="$STEM [MP3 320]"
	M_V0_NAME="$STEM [MP3 V0]"
	M_V2_NAME="$STEM [MP3 V2]"
	
	# paths to our encoded formats
	FLAC_PATH="$OUTPUT_FOLDER/$FLAC_NAME"
	M_320_PATH="$OUTPUT_FOLDER/$M_320_NAME"
	M_V0_PATH="$OUTPUT_FOLDER/$M_V0_NAME"
	M_V2_PATH="$OUTPUT_FOLDER/$M_V2_NAME"
	
		if [ "$t320" = "1" ]; then
		    rm -rf "$M_320_PATH"
			mkdir -p "$M_320_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_320_PATH/{}" ';'
		fi
		if [ "$tv0" = "1" ]; then
		    rm -rf "$M_V0_PATH"
			mkdir -p "$M_V0_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_V0_PATH/{}" ';'
		fi
		if [ "$tv2" = "1" ]; then
		    rm -rf "$M_V2_PATH"
			mkdir -p "$M_V2_PATH"
			cd "$SOURCE"
			find . -type d -exec mkdir -p "/$M_V2_PATH/{}" ';'
		fi
	
	# encode the MP3 files
		for x in `find . -type d -name "*" -print`; do
 			cd $x
			for file in *.flac
				do
				if [ "$file" != "*.flac" ]; then
					echo "     $file"
					MP3=$(echo "${file%.*}").mp3
					if [ "$t320" = "1" ]; then
					echo -n "       ---> writing 320k "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -b:a 320k "$M_320_PATH/$x/$MP3"
					echo "done"
					fi
					if [ "$tv0" = "1" ]; then
					echo -n "       ---> writing V0 "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -q:a 0  "$M_V0_PATH/$x/$MP3"
					echo "done"
					fi
					if [ "$tv2" = "1" ]; then
					echo -n "       ---> writing V2 "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -q:a 2  "$M_V2_PATH/$x/$MP3"
					echo "done"
					fi
				fi	
			done
				cd "$SOURCE"
		done

	# move over the cover art and the .m3u (or .m3u8) files

	if [ "$t320" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_320_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
		done
		cd "$SOURCE"
	done
	fi
	if [ "$tv0" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_V0_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
		done
		cd "$SOURCE"
	done
	fi
	if [ "$tv2" = "1" ]; then
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_V2_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
			done
		cd "$SOURCE"
	done
	fi
	
	# create a copy of the FLAC folder with your naming scheme and build the torrent files
	if [ "$optflac" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		rm -rf "$FLAC_PATH"
		cp -alT "$SOURCE/." "$FLAC_PATH"
		for name in "$FLAC_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$t320" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_320_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$tv0" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_V0_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
	if [ "$tv2" = "1" ]; then
		cd "$OUTPUT_FOLDER"
		for name in "$M_V2_NAME"
			do
				torrent="$OUTPUT_FOLDER/$name.torrent"
				[ -f "$torrent" ] && rm "$torrent"
				mktorrent -p -s "$FLAG" -a $ANNOUNCE $name -o "$torrent"
			done
		echo " "
	fi
clear
echo " "
echo "  #####>>>>>   finished succesfully encoding"
echo "  #####>>>>>  \""$SOURCE"\""
echo "  #####>>>>>   --> to"
echo "  #####>>>>>  \""$OUTPUT_FOLDER"/"$out"\""
echo "  #####>>>>>   and making .torrents"
fi

	  
#####################################################################################################
elif [ "$f" = "3" ]; then

clear
echo " "
echo "Rebuilding torrent files for EVERY folder in: "
echo " "
echo " "$OUTPUT_FOLDER""
echo " "
echo " "
echo "Press any key to proceed"
echo " "
read -n 1 -s -r -p "This will overwrite torrents if already exist"
clear
  
  
cd "$OUTPUT_FOLDER"

for in in *; do
	if [ -d "$in" ]; then
		echo " "
		echo "#Building TORRENT#: $in"
				
		set -euo pipefail
		IFS=$'\n'
		torrent="$OUTPUT_FOLDER/$in.torrent"
		[ -f "$torrent" ] && rm "$torrent"
		mktorrent -p -s "$FLAG" -a $ANNOUNCE $in -o "$torrent"
	fi
done
clear
	if [ "$in" = "*" ]; then
		echo " "
		echo "  #####>>>>> \""$OUTPUT_FOLDER"\" is empty"
	else
		echo " "
		echo "   #####>>>>>  finished succesfully making .torrents in"
		echo "   #####>>>>> "$OUTPUT_FOLDER""
	fi


#####################################################################################################
elif [ "$f" = "4" ]; then 

clear
echo " "
echo "This is only to shrink to [V0] and make things portable"
echo "No .torrent file will be created"
echo " "
echo " "
echo "This will overwrite files in output folder if already exists!"
echo " "
echo "Press any key to encode EVERY folder"
echo "from INPUT: "$INPUT_FOLDER"" 
read -n 1 -s -r -p " to OUTPUT: "$OUTPUT_FOLDER""
clear
  
  
cd "$INPUT_FOLDER"



for in in *; do
	if [ -d "$in" ]; then
		# Will not run if no directories are available
		echo "  ##INPUT: $in"
		echo "  ########         ***name changing***"
		out=$(echo $in | sed 's/[ \?,-]\?FLAC \?//g' | sed 's/[ \?,-]\?flac \?//g' | sed 's/ \?([ \*]\?)//g' | sed 's/ \?\[[ \*]\?\]//g' | sed 's/ \?([ \*]\?)//g' | sed 's/^ *//;s/ *$//')
		echo "  #OUTPUT: $out"
				
		set -euo pipefail
		IFS=$'\n'

		# expand input path
		function abspath {
			if [[ -d "$in" ]]
				then
					pushd "$in" >/dev/null
					pwd
					popd >/dev/null
				elif [[ -e $in ]]
				then
					pushd "$(dirname "$in")" >/dev/null
					echo "$(pwd)/$(basename "$in")"
					popd >/dev/null
				else
					echo "$in" does not exist! >&2
					return 127
			fi
}
		
# input parameters, the source directory, and the stem of our naming scheme
SOURCE=`abspath $in`

if [ -z "$(ls -A $SOURCE)" ]; then
	echo " "   
	echo "  #####>>>>>  skipping empty folder"
	echo "-->: $SOURCE"
	echo "  #####>>>>>  skipping empty folder"
	echo " "
	else
		STEM=$out
	
		# naming scheme completed with formats
		M_V0_NAME="$STEM [MP3 V0]"
		
		# paths to our encoded formats
		M_V0_PATH="$OUTPUT_FOLDER/$M_V0_NAME"
		
		mkdir -p "$M_V0_PATH"
		cd "$SOURCE"
		find . -type d -exec mkdir -p "/$M_V0_PATH/{}" ';'

		# encode the MP3 files
		for x in `find . -type d -name "*" -print`; do
 			cd $x
			for file in *.flac
				do
					if [ "$file" != "*.flac" ]; then
					echo "     $file"
					MP3=$(echo "${file%.*}").mp3
					echo -n "       ---> writing V0 "
					ffmpeg -y -hide_banner -v 8 -i "$file" -codec:a libmp3lame -write_id3v1 1 -id3v2_version 3 -q:a 0  "$M_V0_PATH/$x/$MP3"
					echo "done"
					fi	
				done
				cd "$SOURCE"
		done

	# move over the cover art and the .m3u (or .m3u8) files
	for y in `find . -type d -name "*" -print`; do
		cd $y
		for path in "$M_V0_PATH"
			do
				for file in *.{jp{e,}g,m3u{,8}}
				do
					[ -f "$file" ] && cp "$file" "$path/$y"
				done
			done
		cd "$SOURCE"
	done

cd "$INPUT_FOLDER"
fi
fi
done
clear
	if [ "$in" = "*" ]; then
		echo " "
		echo "  #####>>>>> \""$INPUT_FOLDER"\" is empty"
	else
		echo " "
		echo "  #####>>>>> finished succesfully shrinking to [V=0] for every folder in"
		echo "  #####>>>>> "$INPUT_FOLDER""
		echo "  #####>>>>>  --> to:"
		echo "  #####>>>>> "$OUTPUT_FOLDER""
fi


#####################################################################################################
elif [ "$f" = "5" ]; then
	setannounce

	
#####################################################################################################
elif [ "$f" = "00" ]; then
	clear
	exit
fi
done