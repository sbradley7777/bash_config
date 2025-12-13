#?bin/bash
# URL: https://forums.plex.tv/index.php/topic/121345-app-shell-script-to-identify-missing-seasonsepisodes/
# Usage:
# $ find-missing_tvshows.sh > /tmp/missing-shows/missing_shows.txt
# TODO: 
# Need path option or copy db to tmp.
# option to not show season 0, but that could be grepped out.
# $ grep -v "season 0" /tmp/missing-shows/missing_shows.txt

#DB="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
DB="/tmp/com.plexapp.plugins.library.db"


mkdir -p /tmp/missing-shows

# 1 = Middle missing
# 2 = All missing episodes
# 3 = All missing
RUNLEVEL=1
if [ -n "$1" ]; then
	if [ "$1" = "episodes" ]; then
		RUNLEVEL=1
	fi;
	if [ "$1" = "allepisodes" ]; then
		RUNLEVEL=2
	fi;
	if [ "$1" = "all" ]; then
		RUNLEVEL=3
	fi;
fi

# Loop through the shows
echo "select id,title from metadata_items where metadata_type=2 and library_section_id in (select id from library_sections where section_type = 2) order by title;" | sqlite3 "${DB}" > /tmp/missing-shows/showlist.txt
while read SHOWS; do
        if [ -n "$SHOWS" ]; then
		SHOWID=${SHOWS%|*}
		NAME=${SHOWS#*|}

		# Loop through the seasons
		echo "select id,\"index\" from metadata_items where metadata_type=3 and parent_id=${SHOWID};" | sqlite3 "${DB}" > /tmp/missing-shows/seasonlist.txt
		SEASONINDEXES=()
		SEASONIDS=()
		while read SEASONS; do
			if [ -n "$SEASONS" ]; then
				SEASONIDS+=("${SEASONS%|*}")
				SEASONINDEXES+=("${SEASONS#*|}")
			fi
		done < /tmp/missing-shows/seasonlist.txt
		SEASONINDEX=0
		for ((A=0; A<${#SEASONINDEXES[*]}; A++)); do
			SEASONEXPECTED=$(( ${SEASONINDEX} + 1 ))
			if [ "${SEASONINDEXES[$A]}" -gt "$SEASONEXPECTED" ]; then
				for ((B=${SEASONEXPECTED}; B<${SEASONINDEXES[$A]}; B++)); do
					if (( $RUNLEVEL >= 3 )); then
						echo "${NAME} is missing season ${B}";
					fi
				done
			fi;
			SEASONINDEX=${SEASONINDEXES[$A]}

			# Loop through episodes
			echo "select \"index\",title from metadata_items where metadata_type=4 and parent_id=${SEASONIDS[$A]} order by \"index\";" | sqlite3 "${DB}" > /tmp/missing-shows/episodelist.txt
			EPISODEINDEXES=()
			EPISODETITLES=()
			while read EPISODES; do
				if [ -n "$EPISODES" ]; then
					EPISODEINDEXES+=("${EPISODES%|*}")
					EPISODETITLES+=("${EPISODES#*|}")
				fi
			done < /tmp/missing-shows/episodelist.txt
			EPISODEINDEX=0
			FIRSTEPISODEINDEX=${EPISODEINDEXES[0]};
			for ((C=0; C<${#EPISODEINDEXES[*]}; C++)); do
				EPISODEEXPECTED=$(( ${EPISODEINDEX} + 1 ))
				if [ "${EPISODEINDEXES[$C]}" -gt "$EPISODEEXPECTED" ]; then
					for ((B=${EPISODEEXPECTED}; B<${EPISODEINDEXES[$C]}; B++)); do
						if (( $RUNLEVEL >=2 )); then
							echo "${NAME} is missing season ${SEASONINDEX} episode ${B}";
						elif (( $FIRSTEPISODEINDEX < $B )); then
							echo "${NAME} is missing season ${SEASONINDEX} episode ${B}";
						fi;
					done
				fi;
				EPISODEINDEX=${EPISODEINDEXES[$C]}
			done;

		done
	fi
done < /tmp/missing-shows/showlist.txt

