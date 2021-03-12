---
name: Release Template
about: Verify code is ready to release
title: ''
labels: Release
assignees: ''

---

This checklist is for verifying the release is ready to publish and published correctly.

## Release Summary

- Title / Repo
- vx.x.x

### Validation

- [ ] All packages up to date (or task created)
- [ ] Remove any unused flags or conditional compilation
- [ ] Remove unused packages
- [ ] Code Version updated
- [ ] Code Review completed
- [ ] All existing automated tests (unit and e2e) pass successfully, new tests added as needed
- [ ] Code changes checked into main
- [ ] Sync github actions from main template
- [ ] Existing documentation is updated (readme, .md's)
- [ ] New documentation needed to support the change is created
- [ ] CI completes successfully
- [ ] CD completes successfully
- [ ] Smoke test deployed for 48 hours

### Release

- [ ] Reviewed & updated readme for Developer Experience
- [ ] Resolve to-do from code
- [ ] Verify all new libraries and dependencies are customer approved
- [ ] Tag repo with version tag
- [ ] Ensure CI-CD runs correctly
- [ ] Ran cred scan
- [ ] Removed workflow for issue triage and PR submission
- [ ] Validate e2e testing
- [ ] Close Release Task
