#!/usr/bin/env bash
set -eo pipefail

# discourse_stats.sh – fetch and display Discourse forum statistics
#
# This script queries the Discourse `/site/statistics.json` endpoint and
# provides several ways to display the numeric statistics.  It can
# display all numeric keys at once, print a single key’s value, or run
# interactively where you can choose multiple stats until you quit.
#
# Usage:
#   discourse_stats.sh BASE_URL [--all]
#   discourse_stats.sh BASE_URL --key KEY
#   discourse_stats.sh BASE_URL
#
# Examples:
#   discourse_stats.sh https://example.com --all
#     # lists all numeric stats
#   discourse_stats.sh https://example.com --key topics_count
#     # prints the value of topics_count
#   discourse_stats.sh https://example.com
#     # interactive menu; choose stats until you type q to exit

# Print a usage message.
usage() {
  cat <<'EOF'
Usage: discourse_stats.sh BASE_URL [--all]
       discourse_stats.sh BASE_URL --key KEY
       discourse_stats.sh BASE_URL

BASE_URL should be the root of your Discourse forum (e.g., https://forum.example.com).

Without a flag, an interactive menu will be displayed allowing you to
select a statistic to view.  Use 'a' to show all stats or 'q' to quit.

Flags:
  --all         Print all numeric statistics (topics_count, posts_count, etc.)
  --key KEY     Print the value of a single statistic (replace KEY with e.g. topics_count)

Requires: curl, jq
EOF
}

# Check for required command-line utilities.
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: missing required dependency '$1'" >&2
    exit 1
  }
}

# Print all numeric statistics from the JSON cached in $JSON.
print_all() {
  echo "# All numeric statistics:" 1>&2
  echo "$JSON" \
    | jq -r 'to_entries
        | map(select(.value|type=="number"))
        | sort_by(.key)[]
        | "\(.key)\t\(.value)"'
}

# Print a single statistic by key.  Outputs key<tab>value.
print_one() {
  local key="$1"
  # Check if key exists in the JSON
  if ! echo "$JSON" | jq -e --arg k "$key" 'has($k)' >/dev/null; then
    echo "Error: statistic '$key' not found" >&2
    return 2
  fi
  # Print the key and value on the same line
  printf "%s\t" "$key"
  echo "$JSON" | jq -r --arg k "$key" '.[$k]'
}

# Interactive menu for selecting statistics.  Loops until user quits.
interactive_menu() {
  # Build a sorted array of numeric statistic keys
  local keys=()
  mapfile -t keys < <(echo "$JSON" \
    | jq -r 'to_entries
        | map(select(.value|type=="number"))
        | sort_by(.key)[]
        | .key')

  # Descriptive labels for each statistic used in the menu.
  # These descriptions explain what each metric represents.
  declare -A desc=(
    [active_users_last_day]="unique users active in the last day"
    [active_users_7_days]="unique users active in the last 7 days"
    [active_users_30_days]="unique users active in the last 30 days"
    [likes_last_day]="likes given in the last day"
    [likes_7_days]="likes given in the last 7 days"
    [likes_30_days]="likes given in the last 30 days"
    [likes_count]="total likes on the site"
    [participating_users_last_day]="unique users who participated in the last day"
    [participating_users_7_days]="unique users who participated in the last 7 days"
    [participating_users_30_days]="unique users who participated in the last 30 days"
    [posts_last_day]="posts created in the last day"
    [posts_7_days]="posts created in the last 7 days"
    [posts_30_days]="posts created in the last 30 days"
    [posts_count]="total posts on the site"
    [topics_last_day]="topics created in the last day"
    [topics_7_days]="topics created in the last 7 days"
    [topics_30_days]="topics created in the last 30 days"
    [topics_count]="total topics on the site"
    [users_last_day]="new users who joined in the last day"
    [users_7_days]="new users who joined in the last 7 days"
    [users_30_days]="new users who joined in the last 30 days"
    [users_count]="total registered users"

    [chat_channels_30_days]="chat channels created in the last 30 days"
    [chat_channels_7_days]="chat channels created in the last 7 days"
    [chat_channels_count]="total chat channels on the site"
    [chat_channels_last_day]="chat channels created in the last day"
    [chat_channels_previous_30_days]="chat channels created in the previous 30 days"
    [chat_messages_30_days]="chat messages posted in the last 30 days"
    [chat_messages_7_days]="chat messages posted in the last 7 days"
    [chat_messages_count]="total chat messages posted"
    [chat_messages_last_day]="chat messages posted in the last day"
    [chat_messages_previous_30_days]="chat messages posted in the previous 30 days"
    [chat_users_30_days]="unique chat users active in the last 30 days"
    [chat_users_7_days]="unique chat users active in the last 7 days"
    [chat_users_count]="total chat users"
    [chat_users_last_day]="unique chat users active in the last day"
    [chat_users_previous_30_days]="unique chat users active in the previous 30 days"
    [eu_visitors_30_days]="EU unique visitors in the last 30 days"
    [eu_visitors_7_days]="EU unique visitors in the last 7 days"
    [eu_visitors_last_day]="EU unique visitors in the last day"
    [visitors_30_days]="total unique visitors in the last 30 days"
    [visitors_7_days]="total unique visitors in the last 7 days"
    [visitors_last_day]="total unique visitors in the last day"
  )

  # Helper to print the menu once or when help is requested
  print_menu() {
    echo
    echo "Select a statistic to display:"
    local i=1
    for key in "${keys[@]}"; do
      local d="${desc[$key]:-}"
      # If no description is defined, just show the key
      if [[ -z "$d" ]]; then
        printf "  %2d) %s\n" "$i" "$key"
      else
        printf "  %2d) %s – %s\n" "$i" "$key" "$d"
      fi
      i=$((i + 1))
    done
    echo "  a) all – list all numeric stats"
    echo "  h) help – show this menu again"
    echo "  q) quit – exit the script"
  }

  # Print the menu initially
  print_menu

  while true; do
    printf "> "
    read -r choice

    case "$choice" in
      q|Q)
        echo "Exiting." 1>&2
        break
        ;;
      h|H)
        print_menu
        ;;
      a|A)
        print_all
        ;;
      '')
        continue
        ;;
      *)
        # If numeric, check range and print that statistic
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
          local idx
          idx=$((choice))
          if (( idx >= 1 && idx <= ${#keys[@]} )); then
            local key="${keys[idx-1]}"
            print_one "$key"
          else
            echo "Invalid selection" >&2
          fi
        else
          echo "Invalid selection" >&2
        fi
        ;;
    esac
  done
}

# -------- Main program --------

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

BASE_URL="$1"
shift || true

if [[ "$BASE_URL" != http*://* ]]; then
  BASE_URL="https://$BASE_URL"
fi

need curl
need jq

# Fetch statistics JSON once at startup.  If this fails, exit.
JSON="$(curl -fsS "$BASE_URL/site/statistics.json")" || {
  echo "Error: failed to retrieve statistics from $BASE_URL" >&2
  exit 1
}

# If no flags are provided, run interactive menu.
if [[ $# -eq 0 ]]; then
  interactive_menu
  exit 0
fi

case "$1" in
  --all)
    print_all
    ;;
  --key)
    shift
    if [[ $# -lt 1 ]]; then
      usage
      exit 1
    fi
    print_one "$1"
    ;;
  *)
    usage
    exit 1
    ;;
esac