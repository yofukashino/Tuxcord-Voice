#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <process_id> <mic_node_id>"
    exit 1
fi

PID="$1"
PARENT_PID=$(ps -o ppid= -p "$1")
nightmic_id="$2"
system_name=$(hostname)
selected_app_ids=()

fetch_audio_nodes() {
    pw-dump | jq "[.[] | select(.type == \"PipeWire:Interface:Node\") | select(.info.props[\"application.process.id\"] != $PID) | select(.info.props[\"media.class\"] == \"Stream/Output/Audio\" or .info.props[\"media.class\"] == \"Audio/Sink\")]"
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

get_window_title() {
    local pid=$1
    local ppid=$2
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        if command -v wmctrl &>/dev/null; then
            title=$(wmctrl -lp | awk -v pid="$pid" -v ppid="$ppid" '$3 != 0 && ($3 == pid || $3 == ppid)' | sed "s/.*$system_name//" | head -n 1)
        fi
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        title=$(swaymsg -t get_tree | jq -r --argjson pid "$pid" ppid "$ppid" '.. | select(.pid == $pid) | select(.ppid == $ppid) | .name')
    fi
    if [ -z "$title" ]; then
        echo "null"
    else
        echo "$title"
    fi
}

display_ui() {
    local nodes=$(fetch_audio_nodes)

    local checklist_items=()

    while IFS= read -r node; do
        id=$(echo "$node" | jq -r '.id')
        media_class=$(echo "$node" | jq -r '.info.props["media.class"]')
        app_pid=$(echo "$node" | jq -r '.info.props["application.process.id"]')
        app_name=$(echo "$node" | jq -r '.info.props["application.name"]')
        app_process=$(echo "$node" | jq -r '.info.props["application.process.binary"]')
        device_desc=$(echo "$node" | jq -r '.info.props["device.profile.description"]')
        node_nick=$(echo "$node" | jq -r '.info.props["node.nick"]')

        if [[ "$media_class" == "Stream/Output/Audio" ]]; then
            if [[ "$app_pid" != "null" ]]; then
                app_parent_pid=$(ps -o ppid= -p "$app_pid")
                window_title=$(get_window_title "$app_pid" "$app_parent_pid")
            else
                app_parent_pid=
                window_title=
            fi
            if [[ "$window_title" == "null" || -z $window_title ]]; then
                if [[ "$app_name" == "$app_process" ]]; then
                    name="$app_name"
                else
                    name=$(printf '%s (%s)' "$app_name" "$app_process")
                fi
            else
                name="$window_title"
            fi
        else
            name=$(printf '%s (%s)' "$device_desc" "$node_nick")
        fi

        if [[ " ${selected_app_ids[@]} " =~ " $id " ]]; then
            selection_state="TRUE"
        else
            selection_state="FALSE"
        fi

        if [[ -n "$id" && -n "$name" && "$id" != "null" && "$name" != "null" && $app_parent_pid != $PARENT_PID ]]; then
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
    local selected_ids=("$@")

    old_audio_ids=()

    for id in "${selected_app_ids[@]}"; do
        if [[ ! " ${selected_ids[@]} " =~ " $id " ]]; then
            old_audio_ids+=("$id")
        fi
    done

    selected_app_ids=("${selected_ids[@]}")

    for id in $old_audio_ids; do
        unlink_audio "$id" "$nightmic_id"
    done
    input_ports=$(pw-dump | jq "[.[] | select(.info.props[\"node.id\"] == $nightmic_id) | select(.info.direction == \"input\") | .id] | .[]")

    for id in "${selected_ids[@]}"; do

        output_ports=$(pw-dump | jq "[.[] | select(.info.props[\"node.id\"] == $id) | select(.info.direction == \"output\") | .id] | .[]")

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

unlink_nightmic() {
    local links=$(pw-dump | jq -r ".[] | select(.info[\"input-node-id\"] == $nightmic_id) | .id")
    for link_id in $links; do
        pw-link -d "$link_id"
    done
}

unlink_nightmic

while true; do
    selected=$(display_ui)
    if [[ "$selected" != "null" && (-n "$selected" || -n "$selected_app_ids") ]]; then
        IFS='|' read -ra selected_ids <<<"$selected"
        if [[ "$selected_app_ids" != "${selected_ids[@]}" ]]; then
            manage_pw_links "${selected_ids[@]}"
        fi
        sleep 1
    else
        sleep 1
    fi
done
