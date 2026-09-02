---
name: input-optimizer
description: Rewrite user prompts into concise, direct, concrete instructions while preserving the original intent, facts, constraints, and requested output. Use when a prompt contains greetings, filler, indirect requests, undefined jargon, abstract wording, vague scope, or tangled sentence structure. Do not use this skill to execute the request unless the user also asks for execution.
license: MIT
---

# Input Optimization

Rewrite the supplied user text into a clear prompt that another agent or engineer can execute without guessing.

## Preserve The Request

- Keep the original objective, facts, constraints, files, values, dates, technologies, and requested output.
- Keep the input language unless the user requests another language.
- Do not add requirements, rationale, facts, acceptance criteria, or technical choices that the input does not support.
- Do not perform the requested implementation. Return the rewritten prompt unless the user asks for analysis or execution as a separate action.

## Rewrite Procedure

1. Extract the main action, target, constraints, deliverables, and validation requirements.
2. Remove greetings, apologies, social filler, hedging, repetition, and sign-offs.
3. Replace indirect requests with imperative commands.
4. Replace metaphors, undefined jargon, and subjective wording with specific actions or measurable conditions. Avoid invented terms.
5. Split long sentences into short statements. Put prerequisites before actions and acceptance conditions after actions.
6. Preserve important uncertainty instead of silently resolving it. State a missing choice as an explicit question only when the original request requires it.
7. Return one optimized prompt, not multiple alternatives.

When rewriting Chinese text, avoid these undefined buzzwords unless they are exact defined technical terms: `链路`, `闭环`, `沉淀`, `抓手`, `护栏`, `赋能`, `编排`, `对齐`, and `打通`.

## Examples

Input: `Hey, I need you to kind of look over this draft and make it look a bit better if you don't mind.`

Output: `Review and optimize the provided text draft for clarity and structure.`

Input: `It would be great if the report could eventually show some numbers about sales from last week.`

Output: `Extract and display the previous week's sales metrics in the report.`

## Output Rules

- Output the optimized prompt immediately and directly.
- Do not add a greeting, explanation, sign-off, or evaluation unless requested.
- Keep commands, paths, identifiers, and quoted user text exact.
- Make every required action and expected result explicit and verifiable.
