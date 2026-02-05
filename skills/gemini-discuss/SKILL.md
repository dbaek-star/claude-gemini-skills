---
name: gemini-discuss
description: |
  This skill should be used when the user asks to "discuss with Gemini",
  "Gemini와 논의", "Gemini한테 물어봐", "AI끼리 토론", "두 AI 의견 비교",
  or wants Claude and Gemini to discuss a topic and compare perspectives.
  Provides a workflow for collecting information through discussion with Gemini.
  Runs in Subagent mode for token optimization.
version: 4.0.0
allowed-tools: [Task, Read, Write, Bash, Glob, Grep]
---

# Gemini Discuss (Subagent Version)

Gemini CLI와 특정 주제에 대해 논의하고 정보를 수집하는 스킬입니다.
**Subagent에서 실행되어 메인 컨텍스트 토큰을 절약합니다.**

## 핵심 변경사항 (v4.0.0)

1. **모델 선택**: 기본 `gemini-3-pro-preview` 사용, 실패 시 `gemini-3-flash-preview`로 자동 전환
2. **Subagent 실행**: 전체 토론 과정이 Subagent에서 진행되고, 요약된 결론만 메인에 반환
3. **Claude 검토 강화**: Gemini 의견을 단순 수집이 아닌, 검증 및 반론 포함
4. **토큰 최적화**: 메인 컨텍스트에 ~1,500 토큰만 사용 (기존 ~7,000 토큰에서 78% 절감)
5. **[NEW] 3라운드 토론**: 기존 최대 2라운드 → 3라운드로 확장 (더 깊은 토론)
6. **[NEW] 결론 형식 개선**: 합의점/논쟁점/미결정 사항 분리
7. **[NEW] 조기 종료**: 합의 도달 시 라운드 제한 전 종료
8. **[NEW] 진행 상황 표시**: 각 단계별 텍스트 출력

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
- **웹 검색 지시**: 프롬프트에 "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요."를 포함

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
이 알림은 요약 결과(`discuss_summary.md`)의 상단에도 포함되어야 합니다.

## 목적

- 특정 주제에 대해 Gemini의 관점 수집
- Claude가 Gemini 의견을 **검토하고 반론/보완**
- 두 AI의 관점을 종합하여 더 나은 결론 도출

## 실행 방식

이 스킬이 호출되면, Claude는 **반드시 Task 도구를 사용하여 Subagent를 생성**해야 합니다.

```
[메인 컨텍스트]
사용자 요청 수신 → Task 도구로 Subagent 생성
                         ↓
                  [Subagent 내부]
                  Gemini와 다중 라운드 토론
                  Claude 검토 및 반론
                  결론 도출 및 파일 저장
                         ↓
                  [메인 컨텍스트]
                  요약된 결론 수신 및 사용자에게 전달
```

### Subagent 호출 방법

```
Task 도구 사용:
- subagent_type: "general-purpose"
- prompt: 아래 [Subagent 프롬프트 템플릿] 참조
- description: "Gemini 토론"
```

## 작업 산출물 저장 규칙

모든 파일은 **프로젝트 디렉토리 내** `.gemini/` 폴더에 저장합니다.

### 저장 경로 구조
```
{프로젝트루트}/.gemini/discuss/{YYYYMMDD_HHMMSS}_{주제요약}/
  ├── discuss_input.txt                (초기 질문)
  ├── discuss_gemini_1.md              (Gemini 첫 응답)
  ├── discuss_claude_review_1.md       (Claude 검토 - 동의/반박/보완)
  ├── discuss_followup_1.txt           (후속 질문/반론)
  ├── discuss_gemini_2.md              (Gemini 재응답)
  ├── discuss_claude_review_2.md       (Claude 재검토)
  ├── discuss_conclusion.md            (최종 종합 결론)
  └── discuss_summary.md               (요약 - 메인에 반환)
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
3. **3차**: 둘 다 실패 시 Claude 단독으로 의견 제시

## 워크플로우

```
┌─────────────────────────────────────────────────────────────┐
│                    [Subagent 내부]                           │
├─────────────────────────────────────────────────────────────┤
│  Step 1: 초기 질문                                           │
│  - 주제/질문 → `discuss_input.txt` 저장                      │
│  - Gemini 호출 (새 세션, -m gemini-3-pro-preview)            │
│  - 실패 시 gemini-3-flash-preview로 재시도                   │
│  - 둘 다 실패 시 Claude 단독 의견 제시 + 품질 경고           │
│  - Gemini 응답 → `discuss_gemini_1.md` 저장                  │
│  - 진행 상황: "[1/5] Gemini 의견 수집 중..."                 │
├─────────────────────────────────────────────────────────────┤
│  Step 2: Claude 검토                                         │
│  - Gemini 의견 각 포인트별 검토:                              │
│    → 동의: 근거와 함께 수용                                   │
│    → 반박: 다른 관점 제시                                     │
│    → 보완: 누락된 정보 추가                                   │
│    → 질문: 명확하지 않은 부분 지적                            │
│  - 검토 결과 → `discuss_claude_review_1.md` 저장             │
│  - 진행 상황: "[2/5] Claude 검토 중..."                      │
├─────────────────────────────────────────────────────────────┤
│  Step 3: 후속 토론 (필요시, 최대 3라운드) [UPDATED]          │
│  - Claude 반론/질문 → `discuss_followup_N.txt` 저장          │
│  - Gemini 호출 (--resume latest)                             │
│  - Gemini 응답 → `discuss_gemini_N.md` 저장                  │
│  - Claude 재검토 → `discuss_claude_review_N.md` 저장         │
│  - 합의 도달 시 조기 종료 [NEW]                              │
│  - 진행 상황: "[3/5] 토론 라운드 N/3..."                     │
├─────────────────────────────────────────────────────────────┤
│  Step 4: 결론 도출                                           │
│  - 합의점/논쟁점/미결정 분리 정리 [NEW]                      │
│  - 종합 결론 및 권장사항 → `discuss_conclusion.md` 저장       │
│  - .gemini/context.md 업데이트                               │
│  - 진행 상황: "[4/5] 결론 도출 중..."                        │
├─────────────────────────────────────────────────────────────┤
│  Step 5: 요약 생성                                           │
│  - 요약 생성 → `discuss_summary.md` 저장                     │
│  - 진행 상황: "[5/5] 토론 완료!"                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    discuss_summary.md 반환
```

## Subagent 프롬프트 템플릿

Subagent를 호출할 때 아래 프롬프트를 사용합니다:

```
Gemini와 특정 주제에 대해 토론하고 결론을 도출합니다.

## 토론 주제
{사용자 질문/주제}

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
mkdir -p "{프로젝트루트}/.gemini/discuss/{YYYYMMDD_HHMMSS}_{주제요약}"
```

### 2. Step 1: Gemini 의견 수집
1. 질문 → `discuss_input.txt` 저장
2. Gemini 호출:
   ```bash
   cat {경로}/discuss_input.txt | gemini -m gemini-3-pro-preview -p "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json
   ```
   실패 시:
   ```bash
   cat {경로}/discuss_input.txt | gemini -m gemini-3-flash-preview -p "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json
   ```
3. Gemini 응답 → `discuss_gemini_1.md` 저장

### 3. Step 2: Claude 검토
Gemini 의견의 각 포인트에 대해:
- **동의**: "이 의견에 동의함. 이유: ..."
- **반박**: "이 부분은 다르게 봄. Claude 의견: ..."
- **보완**: "추가로 고려할 점: ..."
- **질문**: "이 부분이 불명확함: ..."

검토 결과 → `discuss_claude_review_1.md` 저장

### 4. Step 3: 후속 토론 (이견이 있는 경우, 최대 3라운드) [UPDATED]

1. 진행 상황 출력:
```
[3/5] 토론 라운드 N/3...
```

2. **조기 종료 조건 [NEW]:**
- 모든 주요 포인트에서 합의 도달
- Claude가 더 이상 반박/질문이 없음
- "합의 도달로 토론을 조기 종료합니다."

3. Claude가 반박하거나 질문한 내용이 있으면:
1. 반론/질문 → `discuss_followup_1.txt` 저장
2. Gemini 호출:
   ```bash
   cat {경로}/discuss_followup_1.txt | gemini -m gemini-3-pro-preview -p "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json --resume latest
   ```
   실패 시:
   ```bash
   cat {경로}/discuss_followup_1.txt | gemini -m gemini-3-flash-preview -p "웹 검색을 통해 최신 정보를 확인하고, 출처를 함께 제시해주세요. ultrathink" -o json --resume latest
   ```
3. 응답 → `discuss_gemini_2.md` 저장
4. Claude 재검토 → `discuss_claude_review_2.md` 저장

(최대 3라운드까지, 합의 시 조기 종료)

### 5. Step 4: 결론 도출

1. 진행 상황 출력:
```
[4/5] 결론 도출 중...
```

2. `discuss_conclusion.md` 생성 (개선된 형식 [NEW]):
```markdown
## 주제
{토론 주제}

## 토론 요약
- 총 라운드: {N}회
- 조기 종료: {예/아니오} (사유: 합의 도달 / 라운드 제한)

## ✅ 합의점 (Agreements)
두 AI가 동의한 사항:
1. {합의 사항 1}
2. {합의 사항 2}

## ⚔️ 논쟁점 (Disagreements)
의견이 갈린 사항:
1. **{주제}**
   - Gemini: {의견}
   - Claude: {의견}
   - 근거 비교: {분석}

## ❓ 미결정 사항 (Unresolved)
추가 정보가 필요한 사항:
1. {미결정 사항} - 필요한 정보: {설명}

## Gemini 주요 의견
- {핵심 포인트 1}
- {핵심 포인트 2}

## Claude 주요 의견
- {핵심 포인트 1}
- {핵심 포인트 2}

## 종합 결론
{두 AI의 의견을 종합한 최종 결론}

## 권장사항
{사용자에게 권장하는 행동}
- 합의점 기반: {행동 1}
- 논쟁점 관련: {추가 조사 또는 사용자 판단 필요}
```

3. `.gemini/context.md` 업데이트:
```markdown
## 최근 토론 (discuss)
- {날짜}: {주제} → 합의: {N}개, 논쟁: {N}개
```

### 6. 요약 생성
`discuss_summary.md` 생성 (메인 컨텍스트로 반환):
```markdown
## Gemini 토론 결과 요약

{Fallback 발생 시 아래 알림 포함}
⚠️ 모델 변경 알림: gemini-3-pro-preview 호출 실패로 gemini-3-flash-preview로 전환하여 진행했습니다.

### 사용된 모델
- {실제 사용된 모델명}

### 주제
{토론 주제 한 줄 요약}

### 핵심 결론
{2-3문장}

### 합의점
- {항목 1}
- {항목 2}

### 주요 이견
- {있는 경우}

### 권장사항
{사용자 행동 제안}

### 상세 내용
{프로젝트루트}/.gemini/discuss/{타임스탬프}_{주제}/
```

## 메인 컨텍스트에서의 처리

Subagent 완료 후, 메인 컨텍스트에서:

1. `discuss_summary.md` 내용을 사용자에게 전달
2. **Fallback 알림이 있으면 사용자에게 명확히 전달**
3. 상세 내용이 필요하면 `.gemini/discuss/` 폴더 참조 안내

## 활용 예시

### 기술 조사
```
Python에서 비동기 처리 best practice에 대해 Gemini와 논의해줘
```

### 아키텍처 논의
```
마이크로서비스 vs 모놀리식 장단점을 Gemini한테 물어봐
```

### 알고리즘 비교
```
이미지 분류에서 CNN vs Transformer 비교를 Gemini와 토론해줘
```

## 메인 컨텍스트 응답 예시

```
## Gemini 토론 결과 요약

### 사용된 모델
- gemini-3-pro-preview

### 주제
Python 비동기 처리 best practice

### 핵심 결론
asyncio를 기본으로 사용하되, CPU-bound 작업은 ProcessPoolExecutor와
병행하는 것이 효과적. 라이브러리 선택은 사용 목적에 따라 달라짐.

### 합의점
- asyncio가 Python 비동기의 표준
- I/O-bound 작업에 효과적
- 동시성 제어에 세마포어 활용 권장

### 주요 이견
- Gemini: trio 라이브러리 권장 ↔ Claude: 표준 asyncio 선호 (생태계 호환성)

### 권장사항
신규 프로젝트는 asyncio로 시작하고, 필요시 uvloop으로 성능 향상 고려

### 상세 내용
.gemini/discuss/20250205_143022_Python비동기/
```

## 주의사항

- 토론이 최대 3라운드까지 진행 (이전 2라운드에서 확장)
- 합의 도달 시 즉시 조기 종료
- 상세 과정은 모두 파일로 저장되어 나중에 확인 가능
- Subagent 실행 중에는 사용자 개입이 어려움
- **모델 Fallback 발생 시 반드시 사용자에게 알림**
