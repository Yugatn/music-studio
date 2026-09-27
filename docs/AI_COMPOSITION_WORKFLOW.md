# AI composition workflow

AI is an iterative collaborator, not a one-shot generator.

## Workflow

1. Define musical intent.
2. Generate a candidate.
3. Edit manually in Piano Roll and Curve Lab.
4. Ask the advisor to analyze the edited version.
5. Review recommendations.
6. Apply selected changes or ask AI for a variation.
7. Compare revisions.
8. Keep, branch, or revert.

## Style and emotion

A style request is represented by multiple dimensions rather than a single genre label: style, energy, complexity, groove, brightness, humanization, emotional targets, references, and elements to avoid.

Example: `Deep electronic, nocturnal and mysterious, medium tempo, strong groove, restrained brightness, gradual energy increase, slightly humanized drums.`

Emotion is treated as a target rather than a guaranteed psychological effect. Musical parameters can include tempo, rhythmic density, register, velocity contrast, harmonic tension, repetition, articulation, timing variation, and arrangement density.

## After manual editing

The current edited project is always the source context for analysis. The AI must not silently overwrite it. Recommendations and generated variations are separate results that the user can accept, reject, compare, or branch.

`CompositionAdvisor` and `AICompositionEngine` are provider-neutral so local or remote models can be connected later without changing the editor or project format.
