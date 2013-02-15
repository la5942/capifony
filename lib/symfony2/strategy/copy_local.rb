# Redefine Copy strategy so we can include additional build steps.
require 'capistrano/recipes/deploy/strategy/copy'
Capistrano::Deploy::Strategy::Copy.class_eval do
  # Deploy
  def deploy!
    copy_cache ? run_copy_cache_strategy : run_copy_strategy
    create_revision_file
    composer_install
    update_build_bootstrap
    compress_repository
    distribute!
  ensure
    rollback_changes
  end

  # Get composer in temp location.
  def composer_get
    logger.debug "Downloading composer to #{destination}"
    capifony_pretty_print "--> Downloading Composer to temp location"
    run "cd #{destination} && curl -s http://getcomposer.org/installer | #{php_bin}'"
    capifony_puts_ok
  end

  # Install composer deps in temp location.
  def composer_install
    if !composer_bin
      composer_get
      set :composer_bin, "#{php_bin} composer.phar"
    end

    logger.debug "Installing composer dependencies to #{destination}"
    capifony_pretty_print "--> Installing Composer dependencies in temp location"
    run "cd #{destination} && #{composer_bin} install #{composer_options}'"
    capifony_puts_ok
  end
0
  # Dump autoloader in temp location.
  def dump_autoload
    if !composer_bin
      composer_get
      set :composer_bin, "#{php_bin} composer.phar"
    end

    logger.debug "Dumping an optimised autoloader to #{destination}"
    capifony_pretty_print "--> Dumping an optimized autoloader to temp location"
    run cd "#{destination} && #{composer_bin} dump-autoload --optimize"
    capifony_puts_ok
  end
end

# Build bootstrap file in temp location.
def update_build_bootstrap
  logger.debug "Building bootstrap file in #{destination}"
  capifony_pretty_print "--> Building bootstrap file in temp location"

  if !local_file_exists?("#{destination}/#{build_bootstrap}") then
    set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
    run_locally "cd #{destination} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped''"
  else
    run_locally "cd #{destination} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped''"
  end

  capifony_puts_ok
end