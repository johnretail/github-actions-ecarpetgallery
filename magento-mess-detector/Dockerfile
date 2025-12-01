FROM extdn/magento-integration-tests-action:8.3-latest AS builder
RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/custom-memory.ini
RUN composer2 create-project --repository=https://repo-magento-mirror.fooman.co.nz/ --no-plugins --no-install --no-interaction magento/project-community-edition /var/www/magento2ce "2.4.8-p3"
WORKDIR "/var/www/magento2ce"
RUN composer2 config --unset repo.0
RUN composer2 config repo.foomanmirror composer https://repo-magento-mirror.fooman.co.nz/
RUN composer2 config --no-plugins allow-plugins true
RUN composer2 config repositories.magento false || true
RUN composer2 install --prefer-dist


FROM extdn/magento-integration-tests-action:8.3-latest
COPY --from=builder /var/www/magento2ce/ /m2/
RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/custom-memory.ini
ADD phpunit.phpmd.xml /m2/dev/tests/static/phpunit.phpmd.xml
ADD PhpmdRunner.php /m2/dev/tests/static/testsuite/Magento/Test/Php/PhpmdRunner.php
ADD LiveCodePhpmdRunner.php /m2/dev/tests/static/framework/Magento/TestFramework/CodingStandard/Tool/LiveCodePhpmdRunner.php

ADD entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
