#!/bin/bash

# File to store the list of radio stations
STATIONS_FILE="$HOME/.config/hypr/scripts/radio-stations.txt"

# Load stations from the file
declare -A RADIO_STATIONS
if [ -f "$STATIONS_FILE" ]; then
    while IFS='=' read -r name url; do
        RADIO_STATIONS["$name"]="$url"
    done < "$STATIONS_FILE"
else
  # Default stations if the file doesn't exist
  declare -A RADIO_STATIONS=(
      ["1. Off Radio"]="http://s3.yesstreaming.net:7062/stream"
      ["2. Best Radio"]="http://best926live.mdc.akamaized.net/strmBest/userBest/chunks.m3u8"
      ["3. En Lefko"]="http://stream.radiojar.com/enlefko877"
      ["4. Sto Kokkino"]="http://stream.radiojar.com/kokkino-ath.mp3"
      ["5. Paranoise"]="https://paranoisewebcast.radioca.st/stream"
      ["6. Kiosk Radio"]="https://kioskradiobxl.out.airtime.pro/kioskradiobxl_b"
      ["7. NTS 1"]="http://stream-relay-geo.ntslive.net/stream"
      ["8. NTS 2"]="http://stream-relay-geo.ntslive.net/stream2"
      ["Add Station"]="Add Station"
  )
fi

# PID file to track the running process
PID_FILE="/tmp/waybar-radio.pid"

# Function to save stations to the file
save_stations() {
    > "$STATIONS_FILE"  # Clear the file
    for name in "${!RADIO_STATIONS[@]}"; do
        echo "$name=${RADIO_STATIONS[$name]}" >> "$STATIONS_FILE"
    done
}

# Function to stop the radio
stop_radio() {
    if [ -f "$PID_FILE" ]; then
        kill -9 "$(cat "$PID_FILE")" &> /dev/null
        rm "$PID_FILE"
    fi
}

# Function to start the radio
start_radio() {
    STATION_NAME="$1"
    STATION_URL="${RADIO_STATIONS[$STATION_NAME]}"
    if [ -z "$STATION_URL" ]; then
        echo "Error: Station not found."
        exit 1
    fi

    # Stop any existing radio stream
    stop_radio

    # Start the new stream
    mpv --no-video "$STATION_URL" &> /dev/null &
    echo $! > "$PID_FILE"
    echo "{\"text\": \"📻 $STATION_NAME\", \"tooltip\": \"Now Playing: $STATION_NAME\", \"class\": \"custom-radio\"}"
}

# Function to display a menu of radio stations using Fuzzel
show_menu() {
    # Add "Add Station" option to the list of stations
    STATION=$(printf "%s\n" "${!RADIO_STATIONS[@]}" | fuzzel --dmenu --prompt "Select Radio Station:")
    
    if [ "$STATION" == "Add Station" ]; then
        add_station
    elif [ -n "$STATION" ]; then
        start_radio "$STATION"
    fi
}

# Function to add a new station
add_station() {
    NAME=$(fuzzel --dmenu --placeholder="Enter a name" --prompt "Station Name: ")
    if [ -z "$NAME" ]; then
        exit 0
    fi
    URL=$(fuzzel --dmenu --placeholder="Enter the URL" --prompt "Station URL: ")
    if [ -z "$URL" ]; then
        exit 0
    fi
    RADIO_STATIONS["$NAME"]="$URL"
    save_stations
    echo "{\"text\": \"📻 Station Added\", \"tooltip\": \"Added: $NAME\", \"class\": \"custom-radio\"}"
}

# Main logic
case "$1" in
    "menu")
        show_menu
        ;;
    "add")
        add_station
        ;;
    *)
        if [ -f "$PID_FILE" ]; then
            stop_radio
            echo '{"text": "📻 Radio Stopped", "tooltip": "Radio is stopped", "class": "custom-radio"}'
        else
            show_menu
        fi
        ;;
esac
