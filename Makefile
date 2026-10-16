.PHONY: html preview serve clean

# Documentation (q2doc + MyST, the gut-to-soil-tutorial layout). Run after
# `q2doc refresh-cache` in an environment with both plugins installed (README,
# "Build the site"). html executes every usage example (downloads about
# 30 GB, runs sylph): the tutorial test run. preview renders the interface
# tabs without executing; ReadTheDocs builds the preview.
# The site offers the extras environment file for download (myst.yml);
# _copy-env-file stages it under docs/_static/, which is gitignored.

_copy-env-file:
	mkdir -p docs/_static
	cp environment-files/thermo-hec-tutorial-extras.yml docs/_static/environment.yml

html: _copy-env-file
	cd docs && Q2DOC_BASE_COMMAND='qiime' jupyter book build --html

preview: _copy-env-file
	cd docs && Q2DOC_BASE_COMMAND='qiime' Q2DOC_PREVIEW= jupyter book build --html

serve:
	npx serve docs/_build/html/ -p 4000

clean:
	rm -rf docs/_build/html/
