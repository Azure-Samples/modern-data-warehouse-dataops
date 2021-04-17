---
name: Sample Complete Review
about: Final review before merging feature branch into the main branch.
title: ''
labels: Release
assignees: ''

---

This checklist is for verifying if a Sample is ready to be merged into the main branch.

## SAMPLE TITLE

< Description >

## Acceptance Criteria

- [ ]
- [ ]
- [ ]

## Key Features (if applicable)

- [ ]
- [ ]
- [ ]

## Definition of Done

- [ ] New or Existing documentation is updated (readme, .md's) with appropriate sections:
  - [ ] Solution Overview
  - [ ] Key Concepts
  - [ ] Key Learnings
  - [ ] How to Use the Sample, Known Issues and Workarounds.
- [ ] All existing automated tests (unit and e2e) pass successfully, new tests added as needed
- [ ] Rebase with main to pull in latest.
- [ ] CI completes successfully, along with CD (if applicable)
- [ ] Sample includes Devcontainer
- [ ] Sample includes `./deploy.sh` or `./deploy.ps1`
- [ ] Sample can be deployed by user outside of main Development team.
