SCRIPTS_TO_TEST := aliases apps build-caesium build-kernel build-twrp common files functions gitshit hastebin kronic-build
SCRIPTS_TO_TEST += setup.sh server system ssh-copy-id-github.sh telegram setup/bat.sh setup/diff-so-fancy.sh setup/gdrive.sh
SCRIPTS_TO_TEST += setup/hub.sh setup/xclip.sh

test:
		@shellcheck --exclude=SC1090,SC1091 ${SCRIPTS_TO_TEST}

installhook:
		@cp -v shellcheck-hook .git/hooks/pre-commit
		@chmod +x .git/hooks/pre-commit

install:
		@./setup.sh

.PHONY: test