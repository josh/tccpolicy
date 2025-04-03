#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# client="/bin/date"
# TODO: Add stub program to use as test client
client="com.mitchellh.ghostty"
policy_file="$(mktemp)"
echo '{"Reminders": true}' >"$policy_file"

echo "1..6"

if swift build >/dev/null 1>&2; then
  echo "ok 1 - swift build: pass"
else
  echo "not ok 1 - swift build: fail"
  exit 1
fi

tccpolicy=".build/arm64-apple-macosx/debug/tccpolicy"

if $tccpolicy dump --client "$client" | jq --exit-status 'has("Reminders") == false' 1>/dev/null; then
  echo "ok 2 - tccpolicy dump: clean"
else
  echo "not ok 2 - tccpolicy dump: dirty"
fi

if $tccpolicy request --policy "$policy_file" 1>&2; then
  echo "ok 3 - tccpolicy request: pass"
else
  echo "not ok 3 - tccpolicy request: fail"
  exit 1
fi

if $tccpolicy check --client "$client" --policy "$policy_file"; then
  echo "ok 4 - tccpolicy check: pass"
else
  echo "not ok 4 - tccpolicy check: fail"
fi

if $tccpolicy dump --client "$client" | jq --exit-status '.Reminders == true' 1>/dev/null; then
  echo "ok 5 - tccpolicy dump: pass"
else
  echo "not ok 5 - tccpolicy dump: fail"
fi

if $tccpolicy reset --client "$client" --service "Reminders" 1>&2; then
  echo "ok 6 - tccpolicy reset: pass"
else
  echo "not ok 6 - tccpolicy reset: fail"
fi
