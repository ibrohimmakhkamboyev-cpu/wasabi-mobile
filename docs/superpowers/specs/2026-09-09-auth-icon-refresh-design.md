# Auth Icon Refresh Design

## Goal

Give authentication form icons a modern Wasabi Sushi visual language without changing SMS, registration, date-picker, or language-selection behavior.

## Design

Each form field uses a 36px rounded icon tile inside the existing input leading area. The tile has a pale Wasabi-green surface and a 20px rounded Material symbol. Phone and birthday controls use the Wasabi-green symbol; name uses a dark neutral symbol. The calendar action uses the same treatment so the date control reads as a unified component.

SMS buttons keep their current labels and actions but use a matching rounded message icon. The visual system is limited to the authentication screens and preserves the existing field labels, accessibility semantics, focus states, and input sizes.

## Components

- `_AuthFieldIcon`: reusable leading icon tile for name, phone, birthday, and calendar controls.
- Existing `InputDecoration` instances: replace bare Material icons with `_AuthFieldIcon`.
- Existing SMS button icons: replace bare Material icons with the matching rounded message symbol.

## Validation

- Add a widget test asserting the reusable icon tile is present in the registration form.
- Preserve existing authentication tests for phone input, SMS code flow, and registration.
