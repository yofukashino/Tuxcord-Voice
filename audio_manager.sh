#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <process_id>"
    exit 1
fi

PID="$1"
selected_app_ids=()
remove_from_engine_id=

fetch_audio_nodes() {
    pw-dump | jq "[.[] | select(.type == \"PipeWire:Interface:Node\") | select(.info.props[\"application.process.id\"] != $PID) | select(.info.props[\"media.class\"] == \"Stream/Output/Audio\" or .info.props[\"media.class\"] == \"Audio/Sink\")]"
}

get_audio_streams() {
    pw-dump | jq -r "[.[] | select(.type == \"PipeWire:Interface:Node\") | select(.info.props[\"application.name\"] == \"WEBRTC VoiceEngine\" and .info.props[\"media.name\"] == \"recStream\"  and .info.props[\"application.process.id\"] == $PID)] | if length == 3 then .[2] else empty end | .id"
}

link_audio() {
    local outputId=$1
    local inputId=$2
    pw-link -L "$outputId" "$inputId"
}

unlink_audio() {
    local outputId=$1
    local inputId=$2
    pw-link -d "$outputId" "$inputId"
}

remove_inputs() {
    local nodeId="$1"
    
    local nodes=$(pw-dump | jq -r ".[] | select(.info[\"input-node-id\"] == $nodeId) | .id")
    
    for id in $nodes; do
        pw-link -d "$id"
    done 
}

display_ui() {
    local nodes=$(fetch_audio_nodes)

    local checklist_items=()

    while IFS= read -r node; do
        id=$(echo "$node" | jq -r '.id')
        media_class=$(echo "$node" | jq -r '.info.props["media.class"]')
        app_name=$(echo "$node" | jq -r '.info.props["application.name"]')
        app_process=$(echo "$node" | jq -r '.info.props["application.process.binary"]')
        device_desc=$(echo "$node" | jq -r '.info.props["device.profile.description"]')
        node_nick=$(echo "$node" | jq -r '.info.props["node.nick"]')
y
        if [[ "$media_class" == "Stream/Output/Audio" ]]; then
            if [[ "$app_name" == "$app_process" ]]; then
                name="$app_name"
            else
                name=$(printf '%s (%s)' "$app_name" "$app_process")
            fi
        else
            name=$(printf '%s (%s)' "$device_desc" "$node_nick")
        fi

        if [[ " ${selected_app_ids[@]} " =~ " $id " ]]; then
            selection_state="TRUE"
        else
            selection_state="FALSE"
        fi

        if [[ -n "$id" && -n "$name" && "$id" != "null" && "$name" != "null" ]]; then
            checklist_items+=("$selection_state" "$id" "$name")
        fi
    done < <(echo "$nodes" | jq -c '.[]')

    zenity_output=$(zenity --list --title "Pick your choice" --text "Select games or applications to share Audio:" \
        --checklist --column "Pick" --column "Identity" --hide-column=2 --column "Audio Source" \
        "${checklist_items[@]}" \
        --multiple --width=500 --height=500 --cancel-label=Refresh --ok-label=Apply)
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "null"
    fi

    echo "$zenity_output"
}

manage_pw_links() {
    local webRtc_id="$1"
    shift
    local selected_ids=("$@")

    old_audio_ids=()

    for id in "${selected_app_ids[@]}"; do
        if [[ ! " ${selected_ids[@]} " =~ " $id " ]]; then
            old_audio_ids+=("$id")
        fi
    done

    selected_app_ids=("${selected_ids[@]}")

    for id in $old_audio_ids; do
        unlink_audio "$id" "$webRtc_id"
    done

    input_ports=$(pw-dump | jq "[.[] | select(.info.props[\"node.id\"] == $webRtc_id) | select(.info.direction == \"input\") | .id] | .[]")

    for id in "${selected_ids[@]}"; do

        output_ports=$(pw-dump | jq "[.[] | select(.info.props[\"node.id\"] == $id) | select(.info.direction == \"output\") | .id] | .[]")
        echo "bruh iddd $id"
        echo "bruh $output_ports $input_ports"

        output_ports_array=$(echo -e "$output_ports")
        input_ports_array=$(echo -e "$input_ports")

        i=1
        while read -r output_port && read -r input_port <&3; do
            if [ $i -eq 1 ]; then
                link_audio "$output_port" "$input_port"
            else
                link_audio "$output_port" "$input_port"
            fi
            i=$((i + 1))
        done <<<"$output_ports_array" 3<<<"$input_ports_array"

    done

}

check_audio_stream() {
    local previous_stream_id=""
    local unchanged_duration=0
    local timeout=10

    while true; do
        local current_stream_id=$(get_audio_streams)
        if [[ "$current_stream_id" != "$previous_stream_id" ]]; then
            if [[ -n "$current_stream_id" ]]; then
                remove_inputs "$current_stream_id"
            fi

            if [[ -n "$previous_stream_id" ]]; then
                remove_inputs "$previous_stream_id"
            fi
            unchanged_duration=0
            previous_stream_id="$current_stream_id"
        fi

        if [ -z "$stream_id" ]; then
            unchanged_duration=$((unchanged_duration + 1))
        else
            unchanged_duration=0
        fi

        if [ "$unchanged_duration" -ge "$timeout" ]; then
            break
        fi

        sleep 1 
    done
}

check_audio_stream &

start() {
    while true; do
        selected=$(display_ui) 
        echo "$selected"

        if [[ "$selected" != "null" && (-n "$selected" || -n "$selected_app_ids") ]]; then
            IFS='|' read -ra selected_ids <<<"$selected" 
            web_rtc_id=$(get_audio_streams)
            manage_pw_links "$web_rtc_id" "${selected_ids[@]}"

        fi
    done

}

start &
