---
applyTo: '**'
---

# Copilot / Sonnet 4.5 — Project Policy & Coding Guidelines

## Model Behavior
- Use Claude Sonnet 4.5 (or latest stable version).
- Keep explanations short but clear.
- Produce secure, production-ready, readable code with tests.

## Project Context
- All project changes must push to this repo:
  https://github.com/sathvik7137/learnease-community-platform/tree/main
- Default branch: `main`.
- Do not create, edit, or suggest any README.md or other .md files unless the user explicitly says: "the entire project is complete".

## Terminal Commands
- Every command must be shown as:
  `Run in NEW TERMINAL: <command>`
- Only use SAME TERMINAL when absolutely required.

## Git Rules
- Always push to:
  https://github.com/sathvik7137/learnease-community-platform.git
- Use clear commit messages:
  feat(scope): short summary
- Never commit secrets or .env files.

## File Deletion & Cleanup Rules (CRITICAL)
When deleting files:
1. **ALWAYS check .gitignore FIRST** before adding any files
2. **Delete files physically** using Remove-Item or rm commands
3. **Remove from git tracking** using: git rm --cached <files>
4. **Update .gitignore** to prevent files from coming back
5. **Commit deletions** with clear message about what was removed
6. **NEVER create temporary .md files** for troubleshooting (use comments in code instead)
7. **If temp files exist**: Delete them immediately, add patterns to .gitignore, then commit

Common patterns to NEVER commit:
- *_test.dart, test_*.dart (unless in test/ directory)
- debug_*.dart, check_*.dart, diagnose_*.dart
- *.log, *.txt (output files), *.db (local databases)
- TEMP_*.md, ADMIN_*.md, SECURITY_*.md (troubleshooting docs)
- Any file matching patterns in .gitignore

## Code Style
- Prefer TypeScript when possible.
- Clean code, strict typing, small functions.
- Add meaningful tests for all important logic.
- Use Prettier + ESLint.

## Deliverable Format
For every task:
1. List files to be created/updated.
2. Show full file contents in code blocks.
3. Show commands to run (NEW TERMINAL format).
4. Include test instructions.
5. Keep summary short.
6. Do not touch .md files unless final completion is declared.

## PR & Review Rules
- Explain problem, approach, tests, and security notes.
- Keep reviews focused and actionable.

## Security
- No secrets in code.
- Use environment variables for credentials.

## Performance
- Prefer pagination and efficient data handling.
- Mention complexity when relevant.

## Error Handling
- Use structured, clear errors.
- Validate all inputs.

## Notes to Copilot / Sonnet
- Ask only essential clarifying questions.
- If info is missing, use reasonable defaults.
- Follow this policy for all code, explanations, and change reviews.
