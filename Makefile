default: lint test

# use a platform in depended path separator
ifdef ComSpec
    PATHSEP2=\\
else
    PATHSEP2=/
endif
PATHSEP=$(strip $(PATHSEP2))

.PHONY: setup
setup:
	pip install vim-vint
	mkdir build
	git clone https://github.com/junegunn/vader.vim.git build/vader.vim
	git clone https://github.com/arecarn/selection.vim.git build/selection.vim

.PHONY: clean
clean:
	git clean -x -d --force

.PHONY: lint
lint:
	vint plugin/*.vim autoload/*.vim

.PHONY: test
test:
	vim -Nu test/vimrc_test -c 'Vader! test/*.vader'
