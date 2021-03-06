.DEFAULT_GOAL := all

.PHONY: install
install:
	pip install -U setuptools pip
	pip install -U -r requirements.txt
	pip install -e .

.PHONY: format
format:
	isort -rc -w 120 pydantic tests
	black -S -l 120 --py36 pydantic tests

.PHONY: lint
lint:
	python setup.py check -rms
	flake8 pydantic/ tests/
	pytest pydantic -p no:sugar -q
	black -S -l 120 --py36 --check pydantic tests

.PHONY: mypy
mypy:
	mypy pydantic

.PHONY: test
test:
	pytest --cov=pydantic

.PHONY: external-mypy
external-mypy:
	@echo "testing simple example with mypy (and python to check it's sane)..."
	python tests/mypy_test_success.py
	mypy tests/mypy_test_success.py
	@echo "checking code with incorrect types fails..."
	@mypy tests/mypy_test_fails1.py 1>/dev/null; \
	  test $$? -eq 1 || \
	  (echo "mypy_test_fails1: mypy passed when it should have failed!"; exit 1)
	@mypy tests/mypy_test_fails2.py 1>/dev/null; \
	  test $$? -eq 1 || \
	  (echo "mypy_test_fails2: mypy passed when it should have failed!"; exit 1)

.PHONY: testcov
testcov:
	pytest --cov=pydantic
	@echo "building coverage html"
	@coverage html

.PHONY: all
all: testcov lint mypy external-mypy

.PHONY: benchmark-all
benchmark-all:
	python benchmarks/run.py

.PHONY: benchmark-pydantic
benchmark-pydantic:
	python benchmarks/run.py pydantic-only

.PHONY: clean
clean:
	rm -rf `find . -name __pycache__`
	rm -f `find . -type f -name '*.py[co]' `
	rm -f `find . -type f -name '*~' `
	rm -f `find . -type f -name '.*~' `
	rm -rf .cache
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf htmlcov
	rm -rf *.egg-info
	rm -f .coverage
	rm -f .coverage.*
	rm -rf build
	python setup.py clean
	make -C docs clean

.PHONY: docs
docs:
	make -C docs html

.PHONY: publish
publish: docs
	cd docs/_build/ && cp -r html site && zip -r site.zip site
	@curl -H "Content-Type: application/zip" -H "Authorization: Bearer ${NETLIFY}" \
	      --data-binary "@docs/_build/site.zip" https://api.netlify.com/api/v1/sites/pydantic-docs.netlify.com/deploys
