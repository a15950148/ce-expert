# Create Stable Address

## Goal
State the exact result to achieve and the observable condition that proves success.

## Prerequisites
- Correct target process attached.
- Reproducible target state.
- Relevant references loaded from `references/`.

## Procedure
1. Establish a controlled baseline.
2. Perform one deliberate action.
3. Observe the result in CE.
4. Record addresses, instructions, registers, or object fields as appropriate.
5. Repeat to eliminate coincidences.
6. Build the smallest working solution.
7. Test enable, disable, reload, and restart behavior.

## Decision Branches
- If expected evidence is absent, consult the matching file in `diagnostics/`.
- If multiple objects are affected, use object comparison and filtering.
- If the address changes, compare pointer and code-based approaches.

## Verification
Document the exact test, expected result, and failure condition.
