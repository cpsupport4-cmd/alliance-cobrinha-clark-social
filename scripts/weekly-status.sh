#!/usr/bin/env bash
#
# weekly-status.sh — print the state of a single week as a formatted table.
#
# Usage:
#   scripts/weekly-status.sh                  # current ISO week (Manila)
#   scripts/weekly-status.sh 2026-W19         # specific week
#   scripts/weekly-status.sh 2026-W19 --quiet # status table only, no nudges
#
# Why this exists:
#   The weekly-status skill used to walk content/<week>/ via multiple
#   Read/Bash tool calls + reasoning. That cost ~5-10k tokens per check.
#   This script does the same work in pure bash, called once, returning
#   the formatted table. The skill becomes "run this and print output."

set -uo pipefail
# Note: we don't use 'set -e' because the script does a lot of "grep returns
# non-zero when no match" lookups that are intentional. Each error case is
# handled explicitly with || true or by checking exit codes inline.

# --- Resolve which week to inspect -----------------------------------------

WEEK="${1:-}"
QUIET=""
if [[ "${1:-}" == "--quiet" ]]; then QUIET="1"; WEEK=""; fi
if [[ "${2:-}" == "--quiet" ]]; then QUIET="1"; fi

if [[ -z "$WEEK" ]]; then
  WEEK=$(TZ='Asia/Manila' date +%G-W%V)
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEEK_DIR="$REPO_ROOT/content/$WEEK"
TODAY_PHT=$(TZ='Asia/Manila' date '+%Y-%m-%d')
TODAY_DAY=$(TZ='Asia/Manila' date '+%A')
TODAY_DAY_NUM=$(TZ='Asia/Manila' date '+%u')

# --- Banner ----------------------------------------------------------------

echo "Weekly status — $WEEK"
echo "Today: $TODAY_DAY $TODAY_PHT PHT (day $TODAY_DAY_NUM of 7)"
echo ""

# --- Early exit if week folder doesn't exist -------------------------------

if [[ ! -d "$WEEK_DIR" ]]; then
  echo "No content folder for $WEEK yet."
  if [[ -z "$QUIET" ]]; then
    echo "Run 'daily-check' or 'produce-post <slot-id>' to bootstrap."
  fi
  exit 0
fi

# --- Slot table ------------------------------------------------------------

SLOTS=(
  "01-mon-set-the-tone:MON:1"
  "02-tue-member-story:TUE:2"
  "03-wed-value-trust:WED:3"
  "04-thu-kids-family:THU:4"
  "05-fri-community:FRI:5"
  "06-sat-social-proof:SAT:6"
  "07-sun-leader-voice:SUN:7"
)

draft_count=0
approved_count=0
posted_count=0
missing_count=0

printf "| %-25s | %-3s | %-9s | %-9s |\n" "Slot" "Day" "State" "Drop (PHT)"
printf "|---------------------------|-----|-----------|-----------|\n"

for entry in "${SLOTS[@]}"; do
  IFS=':' read -r slot_id day day_num <<<"$entry"
  slot_dir="$WEEK_DIR/$slot_id"
  state="missing"

  if [[ -f "$slot_dir/drafts/draft.json" ]]; then
    state="draft"
    draft_count=$((draft_count + 1))
  fi
  if [[ -d "$slot_dir/approved" ]]; then
    if ls "$slot_dir/approved/" 2>/dev/null | grep -vq '^\.gitkeep$' ; then
      if [[ -n "$(ls "$slot_dir/approved/" 2>/dev/null | grep -v '^\.gitkeep$')" ]]; then
        state="approved"
        approved_count=$((approved_count + 1))
      fi
    fi
  fi
  if [[ -f "$slot_dir/approved/.posted" ]]; then
    state="posted"
    posted_count=$((posted_count + 1))
  fi

  if [[ "$state" == "missing" ]]; then
    missing_count=$((missing_count + 1))
  fi

  marker=""
  if [[ "$day_num" == "$TODAY_DAY_NUM" ]]; then marker=" *TODAY*"; fi

  printf "| %-25s | %-3s | %-9s | %-9s |%s\n" "$slot_id" "$day" "$state" "19:00" "$marker"
done

echo ""
echo "Drafted: $draft_count/7 · Approved: $approved_count/7 · Posted: $posted_count/7 · Missing: $missing_count/7"

# --- Stories rollup --------------------------------------------------------

stories_count=0
if [[ -d "$WEEK_DIR/stories" ]]; then
  stories_count=$(ls "$WEEK_DIR/stories/" 2>/dev/null | grep -c '\.json$' || true)
fi
echo "Stories packs this week: $stories_count days covered (target: 7)"

# --- Nudges (skip if --quiet) ----------------------------------------------

if [[ -z "$QUIET" ]]; then
  echo ""

  # Look up today's slot from the canonical SLOTS list, not from disk —
  # the directory might not exist yet (and that's the very state we want
  # to nudge about).
  TODAY_SLOT=""
  for entry in "${SLOTS[@]}"; do
    IFS=':' read -r s_id _ s_day_num <<<"$entry"
    if [[ "$s_day_num" == "$TODAY_DAY_NUM" ]]; then
      TODAY_SLOT="$s_id"
      break
    fi
  done

  if [[ -n "$TODAY_SLOT" ]]; then
    today_dir="$WEEK_DIR/$TODAY_SLOT"
    today_has_draft=0
    today_has_approved=0
    [[ -f "$today_dir/drafts/draft.json" ]] && today_has_draft=1
    if [[ -d "$today_dir/approved" ]]; then
      approved_non_gitkeep=$(ls "$today_dir/approved/" 2>/dev/null | grep -v '^\.gitkeep$' || true)
      [[ -n "$approved_non_gitkeep" ]] && today_has_approved=1
    fi

    if [[ "$today_has_approved" == "1" ]]; then
      : # nothing to nudge
    elif [[ "$today_has_draft" == "1" ]]; then
      echo "TODAY'S NUDGE: $TODAY_SLOT has a draft awaiting approval. Run 'approve $TODAY_SLOT' once reviewed."
    else
      echo "TODAY'S NUDGE: $TODAY_SLOT has no draft. Drop is at 19:00 PHT. Run 'produce-post $TODAY_SLOT'."
    fi
  fi

  if [[ "$stories_count" -lt "$TODAY_DAY_NUM" ]]; then
    echo "STORIES NUDGE: Stories pack for today not yet generated. Run 'stories-pack' (5–10 stories non-negotiable per CLAUDE.md)."
  fi
fi
