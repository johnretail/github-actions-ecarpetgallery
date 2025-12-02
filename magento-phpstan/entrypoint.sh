#!/bin/bash
set -e

test -z "${MODULE_SOURCE}" && MODULE_SOURCE=$INPUT_MODULE_SOURCE
test -z "${COMPOSER_NAME}" && COMPOSER_NAME=$INPUT_COMPOSER_NAME
test -z "${COMPOSER_VERSION}" && COMPOSER_VERSION=$INPUT_COMPOSER_VERSION

if [ -z "$COMPOSER_VERSION" ] ; then
   COMPOSER_VERSION=2
fi

MAGENTO_ROOT=/m2
test -d "${MAGENTO_ROOT}" || MAGENTO_ROOT=/var/www/magento2ce

# Validate required inputs
test -z "${COMPOSER_NAME}" && (echo "Error: 'composer_name' is not set in your GitHub Actions YAML file" && exit 1)
test -z "${MODULE_SOURCE}" && (echo "Error: 'module_source' is not set in your GitHub Actions YAML file" && exit 1)
test -z "${INPUT_PHPSTAN_LEVEL}" && (echo "Error: 'phpstan_level' is not set in your GitHub Actions YAML file" && exit 1)

echo "Using composer ${COMPOSER_VERSION}"
ln -sf /usr/local/bin/composer$COMPOSER_VERSION /usr/local/bin/composer

#echo "Fix issue 115"
#cd $MAGENTO_ROOT
#rm -rf vendor/
#composer install

echo "Setup extension source folder within Magento root"
if [ ! -d "${GITHUB_WORKSPACE}/${MODULE_SOURCE}" ]; then
    echo "Error: Module source directory '${MODULE_SOURCE}' not found in workspace"
    exit 1
fi
mkdir -p "$MAGENTO_ROOT/local-source/"
cd "$MAGENTO_ROOT/local-source/"
cp -R "${GITHUB_WORKSPACE}/${MODULE_SOURCE}" .

echo "Configure extension source in composer"
cd "$MAGENTO_ROOT"
if [ ! -f "composer.json" ]; then
    echo "Error: composer.json not found in Magento root: $MAGENTO_ROOT"
    exit 1
fi
composer config repositories.local-source path "$MAGENTO_ROOT/local-source/*"

echo "Pre Install Script [magento_pre_install_script]: $INPUT_MAGENTO_PRE_INSTALL_SCRIPT"
if [ -n "$INPUT_MAGENTO_PRE_INSTALL_SCRIPT" ] && [ -f "${GITHUB_WORKSPACE}/${INPUT_MAGENTO_PRE_INSTALL_SCRIPT}" ]; then
    echo "Running custom pre-installation script: ${INPUT_MAGENTO_PRE_INSTALL_SCRIPT}"
    . "${GITHUB_WORKSPACE}/${INPUT_MAGENTO_PRE_INSTALL_SCRIPT}"
fi

echo "Installing module"
COMPOSER_MIRROR_PATH_REPOS=1 composer require "$COMPOSER_NAME:@dev" --no-interaction --dev

CONFIGURATION_FILE=dev/tests/static/testsuite/Magento/Test/Php/_files/phpstan/phpstan.neon
if [ -f "vendor/${COMPOSER_NAME}/phpstan.neon" ]; then
    CONFIGURATION_FILE="vendor/${COMPOSER_NAME}/phpstan.neon"
fi

echo "Configuration file: $CONFIGURATION_FILE"
echo "Level: $INPUT_PHPSTAN_LEVEL"

if [ ! -f "$CONFIGURATION_FILE" ]; then
    echo "Warning: Configuration file '$CONFIGURATION_FILE' not found, using default"
fi

if [ ! -d "vendor/${COMPOSER_NAME}" ]; then
    echo "Error: Module '${COMPOSER_NAME}' not found in vendor directory"
    exit 1
fi

echo "Running PHPStan"
php vendor/bin/phpstan analyse \
    --level "$INPUT_PHPSTAN_LEVEL" \
    --no-progress \
    --memory-limit=4G \
    --configuration "$CONFIGURATION_FILE" \
    "vendor/${COMPOSER_NAME}"
