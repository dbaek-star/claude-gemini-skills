---
name: gemini-collab
description: |
  This skill should be used when the user asks to "collaborate with Gemini",
  "Gemini과 협업", "두 AI가 함께 코드 작성", "AI 협업 코딩",
  "Gemini와 함께 개발", or discusses collaborative coding between Claude and Gemini.
  Provides a workflow for Claude Code and Gemini to collaborate on code writing.
  Runs in Subagent mode for token optimization.
version: 3.1.0
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep]
---

# Gemini Collaborative Coding (Subagent Version)

Claude Code와 Gemini가 협업하여 코드를 작성하는 스킬입니다.
**Subagent에서 실행되어 메인 컨텍스트 토큰을 절약합니다.**

## 핵심 변경사항 (v3.1.0)

1. **모델 선택**: 기본 `gemini-3-pro-preview` 사용, 실패 시 `gemini-3-flash-preview`로 자동 전환
2. **Subagent 실행**: 전체 협업 과정이 Subagent에서 진행되고, 요약된 결과만 메인에 반환
3. **Claude 검토 단계**: Gemini 피드백을 Claude가 검토하여 동의/반박 후 선택적 반영
4. **토큰 최적화**: 메인 컨텍스트에 ~2,000 토큰만 사용 (기존 ~13,000 토큰에서 85% 절감)

## Gemini 모델 선택 규칙

### 기본 모델
- **Primary**: `gemini-3-pro-preview` (기본값)
- **Fallback**: `gemini-3-flash-preview` (실패 시 자동 전환)

### 호출 방식
```bash
# 1차 시도: gemini-3-pro-preview
cat {파일} | gemini -m gemini-3-pro-preview -p "{프롬프트} ultrathink" -o json

# 실패 시 2차 시도: gemini-3-flash-preview
cat {파일} | gemini -m gemini-3-flash-preview -p "{프롬프트} ultrathink" -o json
```

### 프롬프트 규칙
- 모든 Gemini 프롬프트의 마지막에 **"ultrathink"** 키워드를 반드시 포함
- **웹 검색 지시 (설계 단계만)**: 설계 검토 프롬프트에 "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요."를 포함

### Fallback 판단 기준
- exit code가 0이 아닌 경우
- JSON 파싱 실패
- `response` 필드가 비어있는 경우
- 타임아웃 발생

### Fallback 발생 시 사용자 알림
모델 변경 시 **반드시** 사용자에게 알립니다:
```
⚠️ 모델 변경 알림: gemini-3-pro-preview 호출 실패로 gemini-3-flash-preview로 전환하여 진행합니다.
```
이 알림은 요약 결과(`collab_summary.md`)의 상단에도 포함되어야 합니다.

## 실행 방식

이 스킬이 호출되면, Claude는 **반드시 Task 도구를 사용하여 Subagent를 생성**해야 합니다.

```
[메인 컨텍스트]
사용자 요청 수신 → Task 도구로 Subagent 생성
                         ↓
                  [Subagent 내부]
                  전체 협업 과정 수행
                  결과를 파일로 저장
                         ↓
                  [메인 컨텍스트]
                  요약된 결과 수신 및 사용자에게 전달
```

### Subagent 호출 방법

```
Task 도구 사용:
- subagent_type: "general-purpose"
- prompt: 아래 [Subagent 프롬프트 템플릿] 참조
- description: "Gemini 협업 코딩"
```

## 작업 산출물 저장 규칙

모든 파일은 **프로젝트 디렉토리 내** `.gemini/` 폴더에 저장합니다.

### 저장 경로 구조
```
{프로젝트루트}/.gemini/collab/{YYYYMMDD_HHMMSS}_{주제요약}/
  ├── collab_design.txt              (Phase 1: 설계안)
  ├── collab_design_gemini.md        (Phase 1: Gemini 설계 검토)
  ├── collab_design_decision.md      (Phase 1: Claude 검토 및 최종 결정)
  ├── collab_code.txt                (Phase 2: 작성된 코드)
  ├── collab_review_gemini.md        (Phase 3: Gemini 코드 리뷰)
  ├── collab_review_decision.md      (Phase 3: Claude 검토 - 동의/반박)
  ├── collab_final_code.txt          (Phase 4: 최종 코드)
  ├── collab_final_verification.md   (Phase 5: 최종 검증)
  └── collab_summary.md              (최종 요약 - 메인에 반환)
```

## Gemini CLI 호출 규칙

### 모델 지정 (필수)
- 모든 Gemini 호출에 `-m gemini-3-pro-preview` 옵션 포함
- 실패 시 `-m gemini-3-flash-preview`로 재시도

### 입력 전달
- 코드나 긴 텍스트는 반드시 임시 파일로 작성 후 `cat` 또는 `<`로 전달
- 지시사항은 `-p` 플래그로 전달
- `echo "내용" | gemini` 패턴은 셸 이스케이핑 문제로 **사용 금지**

### 출력 처리
- 항상 `-o json` 플래그 사용
- `response` 필드에서 Gemini 답변 추출
- `session_id` 필드 보존 (후속 호출용)

### 세션 유지
- 멀티턴 대화가 필요한 경우 `--resume latest` 사용
- 첫 호출에서는 `--resume` 미사용

### 에러 대응
1. **1차**: `gemini-3-pro-preview`로 시도
2. **2차**: 실패 시 `gemini-3-flash-preview`로 재시도 + 사용자 알림
3. **3차**: 둘 다 실패 시 Claude 단독으로 대체 처리

## 워크플로우

```
┌─────────────────────────────────────────────────────────────┐
│                    [Subagent 내부]                           │
├─────────────────────────────────────────────────────────────┤
│  Phase 1: 설계 협의                                          │
│  - Claude: 초기 설계안 제시                                   │
│  - Gemini: 설계 검토 및 대안 제시                             │
│  - Claude: Gemini 의견 검토 (동의/반박) → 최종 설계 결정       │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: 코드 작성                                          │
│  - Claude: 합의된 설계 기반 코드 작성                         │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: 코드 리뷰 + Claude 검토                            │
│  - Gemini: 코드 리뷰 (버그, 성능, 보안, 가독성)               │
│  - Claude: 각 피드백 검토                                    │
│    → 동의: 수정 대상으로 표시                                 │
│    → 반박: 이유 기록, 수정하지 않음                           │
│    → 부분 동의: 수정된 방식으로 반영                          │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: 선택적 수정                                        │
│  - Claude: 동의한 피드백만 코드에 반영                        │
├─────────────────────────────────────────────────────────────┤
│  Phase 5: 최종 검증                                          │
│  - Gemini: 수정 사항 확인                                    │
│  - 결과 요약 생성                                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    collab_summary.md 반환
```

## Subagent 프롬프트 템플릿

Subagent를 호출할 때 아래 프롬프트를 사용합니다:

```
Gemini와 협업하여 코드를 작성합니다.

## 요청 내용
{사용자 요청}

## 프로젝트 경로
{현재 작업 디렉토리}

## Gemini 모델 선택 규칙
- 기본 모델: gemini-3-pro-preview
- Fallback 모델: gemini-3-flash-preview
- 모든 gemini 호출에 `-m gemini-3-pro-preview` 옵션 사용
- 호출 실패 시 `-m gemini-3-flash-preview`로 재시도
- Fallback 발생 시 사용자에게 알림 필수

## 수행할 작업

### 1. 출력 폴더 생성
```bash
mkdir -p "{프로젝트루트}/.gemini/collab/{YYYYMMDD_HHMMSS}_{주제요약}"
```

### 2. Phase 1: 설계 협의
1. 초기 설계안 작성 → `collab_design.txt` 저장
2. Gemini에게 설계 검토 요청:
   ```bash
   cat {경로}/collab_design.txt | gemini -m gemini-3-pro-preview -p "이 설계에 대한 의견과 더 나은 접근법이 있다면 제안해주세요. 웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json
   ```
   실패 시:
   ```bash
   cat {경로}/collab_design.txt | gemini -m gemini-3-flash-preview -p "이 설계에 대한 의견과 더 나은 접근법이 있다면 제안해주세요. 웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json
   ```
3. Gemini 응답 → `collab_design_gemini.md` 저장
4. **Claude 검토**: Gemini 의견 각각에 대해 동의/반박/부분동의 판단
5. 검토 결과 → `collab_design_decision.md` 저장

### 3. Phase 2: 코드 작성
- 최종 결정된 설계로 코드 작성
- 코드 → `collab_code.txt` 저장

### 4. Phase 3: 코드 리뷰 + Claude 검토
1. Gemini에게 코드 리뷰 요청:
   ```bash
   cat {경로}/collab_code.txt | gemini -m gemini-3-pro-preview -p "이 코드를 리뷰해주세요. 버그, 성능, 보안, 가독성 관점에서 검토하고 개선점을 제시해주세요. ultrathink" -o json --resume latest
   ```
   실패 시:
   ```bash
   cat {경로}/collab_code.txt | gemini -m gemini-3-flash-preview -p "이 코드를 리뷰해주세요. 버그, 성능, 보안, 가독성 관점에서 검토하고 개선점을 제시해주세요. ultrathink" -o json --resume latest
   ```
2. Gemini 응답 → `collab_review_gemini.md` 저장
3. **Claude 검토**: 각 피드백에 대해:
   - 동의: "이 지적은 타당함. 수정 예정."
   - 반박: "이 부분은 의도적임. 이유: ..."
   - 부분 동의: "일부 수용. 다른 방식으로 해결."
4. 검토 결과 → `collab_review_decision.md` 저장

### 5. Phase 4: 선택적 수정
- 동의한 피드백만 코드에 반영
- 최종 코드 → `collab_final_code.txt` 저장
- 실제 파일에 코드 작성/수정

### 6. Phase 5: 최종 검증
1. Gemini에게 최종 확인 요청:
   ```bash
   cat {경로}/collab_final_code.txt | gemini -m gemini-3-pro-preview -p "수정된 코드입니다. 이전 피드백이 잘 반영되었는지 확인해주세요. ultrathink" -o json --resume latest
   ```
   실패 시:
   ```bash
   cat {경로}/collab_final_code.txt | gemini -m gemini-3-flash-preview -p "수정된 코드입니다. 이전 피드백이 잘 반영되었는지 확인해주세요. ultrathink" -o json --resume latest
   ```
2. 응답 → `collab_final_verification.md` 저장

### 7. 요약 생성
`collab_summary.md` 파일 생성 (이 내용이 메인 컨텍스트로 반환됨):

```markdown
## Gemini 협업 코딩 결과 요약

{Fallback 발생 시 아래 알림 포함}
⚠️ 모델 변경 알림: gemini-3-pro-preview 호출 실패로 gemini-3-flash-preview로 전환하여 진행했습니다.

### 사용된 모델
- {실제 사용된 모델명}

### 요청
{원래 요청 요약}

### 설계 결정
- 선택한 접근법: {요약}
- Gemini 제안 중 반영된 것: {목록}
- 반영하지 않은 것과 이유: {목록}

### 작성된 코드
- 파일: {파일 경로}
- 주요 기능: {설명}

### 코드 리뷰 결과
- Gemini 지적 사항: {N}개
- 동의하여 수정: {N}개
- 반박하여 유지: {N}개

### 산출물 위치
{프로젝트루트}/.gemini/collab/{타임스탬프}_{주제}/
```

## 메인 컨텍스트에서의 처리

Subagent 완료 후, 메인 컨텍스트에서:

1. `collab_summary.md` 내용을 사용자에게 전달
2. **Fallback 알림이 있으면 사용자에게 명확히 전달**
3. 상세 내용이 필요하면 `.gemini/collab/` 폴더 참조 안내

## 예시

### 사용자 요청
```
Sentinel-2 영상에서 NDVI를 계산하는 Python 함수를 Gemini와 협업해서 작성해줘
```

### 메인 컨텍스트 응답 (요약)
```
## Gemini 협업 코딩 결과 요약

### 사용된 모델
- gemini-3-pro-preview

### 요청
Sentinel-2 NDVI 계산 함수 작성

### 설계 결정
- 선택한 접근법: numpy 배열 기반 처리, 0 나누기 방지 포함
- Gemini 제안 중 반영: 입력 검증, np.where 사용
- 반영하지 않은 것: 클래스 래핑 (단일 함수로 충분)

### 작성된 코드
- 파일: src/utils/ndvi.py
- 주요 기능: calculate_ndvi(nir, red) 함수

### 코드 리뷰 결과
- Gemini 지적 사항: 4개
- 동의하여 수정: 3개
- 반박하여 유지: 1개 (예외 처리 방식)

### 산출물 위치
.gemini/collab/20250205_143022_NDVI함수/
```

## 주의사항

- Subagent 실행 중에는 사용자 개입이 어려움
- 중요한 결정은 요약에 포함하여 사용자가 확인할 수 있도록 함
- 상세 과정은 모두 파일로 저장되어 나중에 확인 가능
- 협업 토큰 사용량이 많은 경우에만 이 스킬 사용 권장
- **모델 Fallback 발생 시 반드시 사용자에게 알림**
