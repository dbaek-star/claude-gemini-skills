#!/bin/bash
# Claude Code + Gemini Skills 설치 스크립트 (macOS / Linux)

echo "Claude Code + Gemini Skills 설치를 시작합니다..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_PATH="$HOME/.claude/skills"

skills=("gemini-collab" "gemini-discuss" "gemini-research" "gemini-review")

for skill in "${skills[@]}"; do
    target_dir="$SKILLS_PATH/$skill"

    mkdir -p "$target_dir"
    cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$target_dir/"

    echo "  [+] 스킬 설치: $skill"
done

echo ""
echo "설치 완료!"
echo ""
echo "사용법:"
echo "  Claude Code 세션에서 다음과 같이 요청하세요:"
echo "  - 'Gemini로 조사해줘: [주제]'"
echo "  - 'Gemini와 논의해줘: [주제]'"
echo "  - 'Gemini로 코드 리뷰해줘: [파일]'"
echo "  - 'Gemini와 협업해서 코드 작성해줘: [요청]'"
