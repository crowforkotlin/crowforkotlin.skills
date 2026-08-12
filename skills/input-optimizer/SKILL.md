---
name: input-optimizer
description: Refines user prompts and inputs by removing colloquialisms, eliminating abstract metaphors, and ensuring rigorous, direct, and professional expression. Use when user text contains conversational filler, overly complex jargon, vague analogies, or indirect phrasing.
license: MIT
---

# Input Optimization Standard

This skill provides explicit procedures to analyze and optimize raw user text into clear, professional, and direct prompt instructions.

## Operational Objectives
1. Remove all conversational filler, introductory remarks, and casual/colloquial phrasing.
2. Eliminate highly abstract vocabulary, complex theoretical metaphors, and convoluted sentence structures.
3. Replace indirect instructions with explicit, imperative, and actionable commands.

## Optimization Protocol

### 1. Analysis and Filtering
- Scan the text for conversational phrases (e.g., "Could you please", "I was wondering if", "Hey there"). Delete them completely.
- Identify words that describe highly abstract or subjective concepts without concrete reference points.
- Identify multi-clause sentences that hide the main objective.

### 2. Rewriting and Restructuring
- Convert indirect statements into direct requests.
- Use explicit terminology rather than figurative analogies.
- Ensure sentence structure follows a direct Subject-Verb-Object pattern where possible to maintain professional rigor.

## Direct Reference Transformations

### Example 1: Eliminating Conversational Phrase
* **Input:** "Hey, I need you to kind of look over this draft and make it look a bit better if you don't mind."
* **Optimized Output:** "Review and optimize the provided text draft for clarity and structure."

### Example 2: Removing Abstract or Complex Concepts
* **Input:** "We need to synergize our multi-dimensional paradigms to create a holistic ecosystem for user onboarding."
* **Optimized Output:** "Standardize and simplify the user onboarding process sequence."

### Example 3: Changing Indirect Request to Explicit Command
* **Input:** "It would be great if the report could eventually show some numbers about sales from last week."
* **Optimized Output:** "Extract and display the previous week's sales performance metrics in the report."

## Execution Rules
- Do not add conversational greetings or sign-offs in the final response.
- Do not interpret or add external meaning beyond the core intent of the user's input.
- Output the optimized result immediately and directly.
