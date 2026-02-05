#!/bin/bash
# Claude Code + Gemini Skills Installation Script (macOS / Linux)

echo "Installing Claude Code + Gemini Skills..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_PATH="$HOME/.claude/skills"

skills=("gemini-collab" "gemini-discuss" "gemini-research" "gemini-review")

for skill in "${skills[@]}"; do
    target_dir="$SKILLS_PATH/$skill"

    mkdir -p "$target_dir"
    cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$target_dir/"

    echo "  [+] Installed skill: $skill"
done

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  In a Claude Code session, use natural language requests like:"
echo "  - 'Research with Gemini: [topic]'"
echo "  - 'Discuss with Gemini: [topic]'"
echo "  - 'Review code with Gemini: [file]'"
echo "  - 'Collaborate with Gemini to write: [request]'"
