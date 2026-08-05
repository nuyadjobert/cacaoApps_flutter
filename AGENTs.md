# AI Agent Behavior

Before implementing any feature:

1. Search the existing codebase.
2. Reuse existing widgets and UI components.
3. Reuse existing state management logic.
4. Reuse existing utilities and helpers.
5. Modify the smallest number of files possible.

Never introduce a new pattern when an existing one already exists.

Always explain architectural decisions when modifying core architecture, state management, routing, or native platform integrations.

If there is any confusion, ambiguity, or missing context, always ask before proceeding.

---

# Flutter

- Prefer stateless widgets where possible.
- Use const constructors everywhere possible.
- Always implement a responsive design that adapts to different screen sizes.
- Always follow the existing color palette; use Theme.of(context) instead of hardcoded colors.
- Use strict typing; never use dynamic types.
- Use relative imports within features and package imports across features.
- Update all dependent files when changing a shared function signature.
- Do not add new packages to pubspec.yaml without explicit permission.
- Do not hallucinate APIs or methods that do not exist.
- Do not leave empty placeholders or // TODO comments.

---

# Before Finishing

Always ensure:

- flutter analyze passes.
- Type safety is strictly maintained.
- Imports are clean and fully resolved.
- No dead code remains.
- No duplicate widgets or functions were introduced.
- No existing modules are broken by the changes.
- Reuse existing code.