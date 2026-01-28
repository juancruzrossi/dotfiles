#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // "/"')

# Get directory name (basename)
dir_name=$(basename "$current_dir")

# Colors
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# Get git branch
git_info=""
if cd "$current_dir" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"
    git_info=" ${GRAY}│${NC} ${MAGENTA}${branch}${NC}"
fi

# Build output: carpeta │ modelo │ rama-git
echo -e " ${CYAN}${dir_name}${NC} ${GRAY}│${NC} ${GRAY}${model_name}${NC}${git_info}"
