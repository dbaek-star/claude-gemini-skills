# Claude Code + Gemini CLI Skills

Claude Code와 Gemini CLI를 연동하여 두 AI가 협업하는 스킬 모음입니다.

## 개요

이 프로젝트는 Claude Code 환경에서 Gemini CLI를 활용하여 코드 리뷰, 기술 조사, AI 토론, 협업 코딩을 수행하는 4가지 스킬을 제공합니다.

### 핵심 특징

- **Claude 검증 단계**: Gemini 응답을 Claude가 검토하여 동의/반박/부분동의 판단
- **웹 검색 통합**: 최신 정보 확인 및 출처 제시 (research, discuss, collab)
- **토큰 최적화**: Subagent 실행으로 메인 컨텍스트 토큰 절약 (discuss, collab)
- **모델 Fallback**: `gemini-3-pro-preview` 실패 시 `gemini-3-flash-preview`로 자동 전환

## 스킬 목록

| 스킬 | 설명 | 실행 방식 |
|------|------|-----------|
| **gemini-research** | Gemini로 기술 조사 + Claude 검증 | 메인 컨텍스트 |
| **gemini-discuss** | Gemini와 주제 토론 + Claude 반론 | Subagent |
| **gemini-review** | Gemini 코드 리뷰 + Claude 동의/반박 | 메인 컨텍스트 |
| **gemini-collab** | Gemini와 협업 코딩 (설계→코드→리뷰) | Subagent |

## 요구사항

- [Claude Code](https://claude.com/claude-code) 설치
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) 설치 및 인증
- Windows / macOS / Linux

## 설치 방법

### 1. 저장소 클론

```bash
git clone https://github.com/dbaek-star/claude-gemini-skills.git
cd claude-gemini-skills
```

### 2. 설치 스크립트 실행

**Windows (PowerShell):**
```powershell
.\install.ps1
```

**macOS / Linux:**
```bash
chmod +x install.sh
./install.sh
```

<details>
<summary>수동 설치 (스크립트 없이)</summary>

**Windows:**
```powershell
# 스킬 디렉토리 생성
mkdir "$env:USERPROFILE\.claude\skills\gemini-collab" -Force
mkdir "$env:USERPROFILE\.claude\skills\gemini-discuss" -Force
mkdir "$env:USERPROFILE\.claude\skills\gemini-research" -Force
mkdir "$env:USERPROFILE\.claude\skills\gemini-review" -Force

# 파일 복사
Copy-Item "skills\gemini-collab\SKILL.md" "$env:USERPROFILE\.claude\skills\gemini-collab\"
Copy-Item "skills\gemini-discuss\SKILL.md" "$env:USERPROFILE\.claude\skills\gemini-discuss\"
Copy-Item "skills\gemini-research\SKILL.md" "$env:USERPROFILE\.claude\skills\gemini-research\"
Copy-Item "skills\gemini-review\SKILL.md" "$env:USERPROFILE\.claude\skills\gemini-review\"
```

**macOS / Linux:**
```bash
mkdir -p ~/.claude/skills/gemini-{collab,discuss,research,review}

cp skills/gemini-collab/SKILL.md ~/.claude/skills/gemini-collab/
cp skills/gemini-discuss/SKILL.md ~/.claude/skills/gemini-discuss/
cp skills/gemini-research/SKILL.md ~/.claude/skills/gemini-research/
cp skills/gemini-review/SKILL.md ~/.claude/skills/gemini-review/
```

</details>

### 3. Gemini CLI 설정

```bash
# Gemini CLI 설치 (npm)
npm install -g @anthropic/gemini-cli

# 인증
gemini auth login
```

## 사용법

Claude Code 세션에서 자연어로 요청하면 자동으로 해당 스킬이 활성화됩니다.

### gemini-research (기술 조사)

```
Python 비동기 웹 프레임워크 비교해줘 (FastAPI vs Starlette vs Sanic)
```
```
Gemini로 조사해줘: 위성 영상 분류에서 U-Net vs DeepLabV3+ 비교
```

### gemini-discuss (AI 토론)

```
Python에서 async/await vs threading에 대해 Gemini와 논의해줘
```
```
마이크로서비스 vs 모놀리식 장단점을 Gemini한테 물어봐
```

### gemini-review (코드 리뷰)

```
src/utils/parser.py 파일을 Gemini로 리뷰해줘
```
```
이 함수를 Gemini한테 검토받아줘:
def calculate_ndvi(nir, red):
    return (nir - red) / (nir + red)
```

### gemini-collab (협업 코딩)

```
Sentinel-2 영상에서 NDVI를 계산하는 Python 함수를 Gemini와 협업해서 작성해줘
```
```
파일 업로드 API를 Gemini와 함께 개발해줘
```

## 출력물 저장 위치

모든 작업 산출물은 프로젝트 디렉토리 내 `.gemini/` 폴더에 저장됩니다.

```
{프로젝트루트}/.gemini/
├── research/{타임스탬프}_{주제}/
│   ├── research_input.txt
│   ├── research_gemini.md
│   ├── research_claude_verification.md
│   └── research_final.md
├── discuss/{타임스탬프}_{주제}/
│   ├── discuss_input.txt
│   ├── discuss_gemini_1.md
│   ├── discuss_claude_review_1.md
│   └── discuss_summary.md
├── review/{타임스탬프}_{대상}/
│   ├── review_input.txt
│   ├── review_gemini.md
│   ├── review_claude_decision.md
│   └── review_final.md
└── collab/{타임스탬프}_{주제}/
    ├── collab_design.txt
    ├── collab_code.txt
    ├── collab_final_code.txt
    └── collab_summary.md
```

## 설정 옵션

### Gemini 모델

- **기본 모델**: `gemini-3-pro-preview`
- **Fallback 모델**: `gemini-3-flash-preview` (기본 모델 실패 시 자동 전환)

### 프롬프트 규칙

- 모든 Gemini 프롬프트 끝에 `ultrathink` 키워드 포함 (깊은 추론 활성화)
- 웹 검색이 필요한 스킬에서는 "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요." 포함

## 버전 정보

**v3.1.0** (2025-02-05)

- 모델 선택: `gemini-3-pro-preview` 기본, `gemini-3-flash-preview` fallback
- Claude 검증 단계 추가
- 웹 검색 통합 (research, discuss, collab 설계 단계)
- `ultrathink` 키워드 추가
- Subagent 토큰 최적화 (discuss, collab)

## 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

## 기여

이슈 및 Pull Request 환영합니다.

## 관련 링크

- [Claude Code](https://claude.com/claude-code)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
