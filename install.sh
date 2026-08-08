#!/usr/bin/env bash
set -euo pipefail

# 압축을 푼 디렉터리에서 실행한다. 배포물 중 옮기는 것은 실행파일 셋뿐이고,
# 함께 들어 있는 문서와 설정은 건드리지 않는다.
BINS=(kontexus-cli kontexus-mcp)
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/bin"
DRY_RUN=0

usage() {
    cat <<EOF
사용법: install.sh [-n|--dry-run] [-h|--help]

  압축을 푼 디렉터리의 ${BINS[*]}를 \$HOME/.local/bin 에 설치합니다.

  -n, --dry-run   아무것도 바꾸지 않고 수행할 명령만 출력합니다.
  -h, --help      이 도움말을 출력합니다.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf '알 수 없는 인자: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# dry-run은 명령을 출력만 하고 실행하지 않는다. 부수효과를 내는 명령은 전부 이 함수를 거친다.
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        # %q로 인용해야 출력한 그대로 실행해도 같은 명령이 된다.
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

missing=0
for bin in "${BINS[@]}"; do
    if [ ! -f "$SRC/$bin" ]; then
        printf '실행파일이 없습니다: %s/%s\n' "$SRC" "$bin" >&2
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    printf '압축을 푼 디렉터리에서 실행하십시오.\n' >&2
    exit 1
fi

run mkdir -p "$DEST"

for bin in "${BINS[@]}"; do
    if [ "$DRY_RUN" -eq 1 ] && [ -e "$DEST/$bin" ]; then
        printf '[dry-run] 주의: 기존 %s/%s 를 덮어씁니다\n' "$DEST" "$bin"
    fi
    run xattr -c "$SRC/$bin"
    run chmod +x "$SRC/$bin"
    run mv "$SRC/$bin" "$DEST/"
done
