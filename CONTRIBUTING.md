# Contributing

Thanks for your interest in contributing to Expert Context Pack (ECP).

## What to contribute

- Bug reports and reproducible test cases
- Spec clarifications (keep schemas authoritative when prose and schema disagree)
- Reference implementation improvements (`ecpctl`, runtime, indexers, packaging)
- New example packs and conformance cases

## Development setup

Prerequisites: Python 3.10+.

Install (editable):

```bash
python -m pip install -e .
```

Run tests:

```bash
python -m unittest discover -s tests
```

Validate example packs (strict + artifacts):

```bash
ecpctl validate --strict --with-artifacts --skill examples/ecp-conformance-pack
ecpctl validate --strict --with-artifacts --skill examples/codebase-expert
```

## Pull requests

- Keep PRs focused; avoid unrelated refactors.
- Update or add tests for behavior changes.
- If you change the spec, update the corresponding JSON Schemas under `spec/schemas/`.
- Run `ecpctl validate --strict --with-artifacts` on impacted examples before opening the PR.

## License

By contributing, you agree that your contributions will be licensed under the Apache-2.0 license (see `LICENSE`).

