#!/bin/bash

usage() {
    cat << EOF
A bash script that check and change code style with clang-format.

usage: $0 [-h][-m][-a]
flags:  Flag    Description
        -h      show this help message
        -m      modify file inplace
        -a      check all files instead of changed files reported by git diff
EOF
    exit $1;
}

# argv flags
VAR_CHECK_ALL_FILES=0
VAR_MODIFY_INPLACE=0

while getopts "hma" o; do
    case "${o}" in
    m)
        VAR_MODIFY_INPLACE=1
        ;;
    a)
        VAR_CHECK_ALL_FILES=1
        ;;
    h)
        usage 0
        ;;
    *)
        usage 1
        ;;
    esac
done
shift $((OPTIND-1))

# Check clang-format
CLANGF=$(which clang-format)
if [ $? -ne 0 ]; then
    echo "[!] clang-format not installed. Unable to check source file format policy." >&2
    exit 1
fi

# Build list of files to be checked
FILES=""
if [ $VAR_CHECK_ALL_FILES -eq 1 ]; then
    FILES=$(git ls-files | grep -E "\.(c|cpp|h|hpp)$")
else
    FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E "\.(c|cpp|h|hpp)$")
fi

dry_run_check() {
    for FILE in $FILES; do
        $CLANGF -style=file --dry-run --Werror $FILE &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[!] $FILE does not respect the agreed coding style." >&2
            RETURN=1
        else
            echo "[*] $FILE passed code style check."
        fi
    done
    return $RETURN
}

modify_in_place() {
    for FILE in $FILES; do
        $CLANGF -style=file -i --Werror $FILE &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[!] Failed to format $FILE in place" >&2
            RETURN=1
        fi
    done
    return $RETURN
}

# Check
if [ $VAR_MODIFY_INPLACE -eq 1 ]; then
    modify_in_place
    if [ $? -eq 0 ]; then
        echo "[*] Formatting done"
        exit 0
    else
        echo "[!] Failed to format some files" >&2
        exit 1
    fi
else
    dry_run_check
    if [ $? -eq 0 ]; then
        echo "[*] All files passed"
        exit 0
    else
        echo "[!] Some files do not respect the agreed coding style" >&2
        exit 1
    fi
fi
