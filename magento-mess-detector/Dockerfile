FROM extdn/magento-integration-tests-action:8.3-latest AS builder
RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/custom-memory.ini
RUN composer create-project --repository=https://repo-magento-mirror.fooman.co.nz/ --no-plugins --no-install --no-interaction magento/project-community-edition /var/www/magento2ce "2.4.8-p3"
WORKDIR "/var/www/magento2ce"
RUN composer config --unset repo.0 || true
RUN composer config repo.foomanmirror composer https://repo-magento-mirror.fooman.co.nz/
RUN composer config --no-plugins allow-plugins true
RUN php -r '$json = json_decode(file_get_contents("composer.json"), true); if (isset($json["repositories"])) { $json["repositories"] = array_filter($json["repositories"], function($repo) { return !isset($repo["url"]) || strpos($repo["url"], "repo.magento.com") === false; }); $json["repositories"] = array_values($json["repositories"]); file_put_contents("composer.json", json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)); }' || true
RUN composer install --prefer-dist


FROM extdn/magento-integration-tests-action:8.3-latest
COPY --from=builder /var/www/magento2ce/ /m2/
RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/custom-memory.ini
ADD phpunit.phpmd.xml /m2/dev/tests/static/phpunit.phpmd.xml
ADD PhpmdRunner.php /m2/dev/tests/static/testsuite/Magento/Test/Php/PhpmdRunner.php
ADD LiveCodePhpmdRunner.php /m2/dev/tests/static/framework/Magento/TestFramework/CodingStandard/Tool/LiveCodePhpmdRunner.php

ADD entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
