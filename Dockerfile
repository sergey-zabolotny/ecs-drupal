# PHP Dependency install via Composer.
FROM composer as vendor

COPY composer.json composer.json
COPY composer.lock composer.lock
COPY scripts/ scripts/

RUN set -xe; \
	composer install \
	--ignore-platform-reqs \
	--no-interaction \
	--no-dev \
	--prefer-dist

# Build the Docker image for Drupal.
# Start with an official Drupal image for now.
# TODO: switch to php:7.3-apache
FROM drupal:8.7.3-apache
RUN set -xe; \
  apt-get update; \
	apt-get install -y --no-install-recommends \
		ssh; \
	# Remove existing Drupal installation
	rm -rf /var/www/html; \
	# Update ownership on /var/www or Drupal will complain that it cannot create the config folder (/var/www/config)
	chown www-data:www-data /var/www

# Change default Apache DocumentRoot
ENV APACHE_DOCUMENT_ROOT=/var/www/web
RUN set -xe; \
	sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf; \
	sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copy precompiled codebase into the container.
COPY --from=vendor --chown=www-data:www-data /app/ /var/www/

# Copy local overrides into the container.
COPY --chown=www-data:www-data . /var/www/

# Add Drush Launcher.
#RUN curl -OL https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar \
# && chmod +x drush.phar \
# && mv drush.phar /usr/local/bin/drush

WORKDIR /var/www/

EXPOSE 22

CMD ["sshd && apache2-foreground"]
