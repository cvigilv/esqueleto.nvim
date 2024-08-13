all: format lint test

STYLUA ?= stylua

.PHONY: test 
test:
	nvim --headless -u scripts/minimal_init.lua -c "PlenaryBustedDirectory tests { minimal_init='./scripts/minimal_init.lua', sequential=true, }"

.PHONY: lint_stylua
lint_stylua:
	${STYLUA} --color always --check lua

.PHONY: lint_luacheck
lint_luacheck:
	luacheck lua

.PHONY: lint 
lint: lint_luacheck lint_stylua

.PHONY: format 
format:
	${STYLUA} lua
