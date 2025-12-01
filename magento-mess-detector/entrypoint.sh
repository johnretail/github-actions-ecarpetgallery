#!/bin/sh -l
test -z "${FILES_CHANGED}" && FILES_CHANGED=$INPUT_FILES_CHANGED
echo "FILES changed: ${FILES_CHANGED}"
echo "The current working directory: $PWD"
echo ${FILES_CHANGED} > $GITHUB_WORKSPACE/fileschanged.txt
sh -c "cd /m2/dev/tests/static && /m2/vendor/bin/phpunit -c /m2/dev/tests/static/phpunit.phpmd.xml $*"
