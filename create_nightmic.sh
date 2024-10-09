SINK_NAME="nightmic"
SOURCE_DESCRIPTION="nightmic"

nightmic_id=$(pw-dump | jq -r ".[] | select(.info.props[\"node.description\"] == \"$SOURCE_DESCRIPTION\") | .id")

if [ -n "$nightmic_id" ]; then
    links=$(pw-dump | jq -r ".[] | select(.info[\"input-node-id\"] == $nightmic_id) | .id")

    for link_id in $links; do
        pw-link -d "$link_id"
    done

else
    pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name="$SINK_NAME" sink_properties=device.description="$SOURCE_DESCRIPTION" channel_map=front-left,front-right >/dev/null 2>&1

    nightmic_id=$(pw-dump | jq -r ".[] | select(.info.props[\"node.description\"] == \"$SOURCE_DESCRIPTION\") | .id")

fi

echo "$nightmic_id"
