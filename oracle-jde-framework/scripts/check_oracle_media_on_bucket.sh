#!/bin/bash
set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly RESET='\033[0m'

if [[ $# -gt 1 ]]; then
	printf 'Usage: %s [BUCKET|gs://BUCKET]\n' "$0" >&2
	exit 2
fi

bucket=${1:-}
if [[ -z "$bucket" ]]; then
	read -r -p 'GCS bucket (name or gs:// URI): ' bucket
fi

if [[ -z "$bucket" ]]; then
	printf 'A bucket name or gs:// URI is required.\n' >&2
	exit 2
fi

if [[ "$bucket" != gs://* ]]; then
	bucket="gs://${bucket}"
fi
bucket="${bucket%/}"

if ! command -v gcloud >/dev/null 2>&1; then
	printf 'gcloud is required but was not found in PATH.\n' >&2
	exit 1
fi

files="
LINUX.X64_193000_db_home.zip
V1045131-01.zip
V1053599-01.zip
V1053600-01.zip
V1053602-01.zip
V1053603-01.zip
V1053604-01.zip
V1053605-01.zip
V1053607-01.zip
V1053608-01.zip
V1053609-01.zip
V1053610-01.zip
V1053619-01.zip
V1055306-01.zip
V994956-01.zip
ojdbc8-full.tar.gz
p28186730_1394224_Generic.zip
p39034528_190000_Linux-x86-64.zip
p39796866_141100_Generic.zip
p6880880_190000_Linux-x86-64.zip
"

missing=0
while IFS= read -r file; do
	[[ -z "$file" ]] && continue

	if gcloud storage ls "${bucket}/${file}" >/dev/null 2>&1; then
		printf '%bOK%b      %s\n' "$GREEN" "$RESET" "$file"
	else
		printf '%b!!! MISSING%b %s -- see oracle-jde-framework/README.md for download links\n' \
			"$RED" "$RESET" "$file"
		missing=$((missing + 1))
	fi
done <<< "$files"

if [[ $missing -gt 0 ]]; then
	printf '\n%b%d file(s) are missing. Upload them to %s after downloading them from the README.%b\n' \
		"$RED" "$missing" "$bucket" "$RESET"
	exit 1
fi

printf '\n%bAll required Oracle media files are present in %s.%b\n' "$GREEN" "$bucket" "$RESET"