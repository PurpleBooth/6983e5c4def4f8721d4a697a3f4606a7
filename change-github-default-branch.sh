#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 3 ] && [ $# -ne 2 ] && [ -z "$GITHUB_TOKEN" ] && [ $# -ne 1 ]; then
	echo "USAGE: $0 user/repo [pat_token] [new_default]" 1>&2
	echo
	printf "pat_token\tA GitHub personal access with at least repo:public_repo, or repo on private repositores https://github.com/settings/tokens/new\n"
	printf "user/repo\tA github repository, for example purplebooth/readable-name-generator\n"
	printf "new_default\tName of the new default branch, default: main\n"
	exit 1
fi

if [ -z "$GITHUB_TOKEN" ] && [ $# -ge 2 ]; then
	GITHUB_TOKEN="$2"
fi
REPO="$1"

DEFAULT_BRANCH_NAME="${3:-main}"
CURRENT_DEFAULT_BRANCH="$(
	curl \
		--silent \
		--header "Authorization: token $GITHUB_TOKEN" \
		--header "Content-Type: application/json" \
		"https://api.github.com/repos/$REPO" |
		python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])'
)"

LATEST_SHA="$(
	curl \
		--silent \
		-X GET \
		--header "Authorization: token $GITHUB_TOKEN" \
		--location \
		--output - \
		"https://api.github.com/repos/$REPO/git/refs/heads/$CURRENT_DEFAULT_BRANCH" |
		python -c 'import sys, json; print(json.load(sys.stdin)["object"]["sha"])'
)"
curl \
	--silent \
	-X POST \
	--header "Authorization: token $GITHUB_TOKEN" \
	--header "Content-Type: application/json" \
	-d "{ \"ref\": \"refs/heads/$DEFAULT_BRANCH_NAME\", \"sha\": \"$LATEST_SHA\" }" \
	"https://api.github.com/repos/$REPO/git/refs"

curl \
	--silent \
	-X PATCH \
	--header "Authorization: token $GITHUB_TOKEN" \
	--header "Content-Type: application/json" \
	--data "{\"default_branch\": \"$DEFAULT_BRANCH_NAME\" }" \
	"https://api.github.com/repos/$REPO"
