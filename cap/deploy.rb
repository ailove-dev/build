set :application, "equip"
set :domain,      "#{application}.pro.ailove.ru"
set :deploy_to,   "/srv/www/#{application}"
set :app_path,    "app"

set :use_sudo,   false

set :repository,  "git@dev.ailove.ru:/srv/git/#{application}"
set :scm,         :git

set :model_manager, "doctrine"

role :web,        domain                         # Your HTTP server, Apache/etc
role :app,        domain                         # This may be the same as your `Web` server
role :db,         domain, :primary => true       # This is where Symfony2 migrations will run

set  :keep_releases,  3

# Be more verbose by uncommenting the following line
#logger.level = Logger::MAX_LEVEL

set :web_path,    "htdocs"
set :shared_children,     []

depend :remote, :directory, "#:deploy_to/tmp"
depend :remote, :directory, "#:deploy_to/cache"

set :jenkins_host, "http://test.ailove.ru:8080"
set :jenkins_job_name, application
set :jenkins_check, true

set :branch,   "refs/heads/master"

before 'deploy', 'jenkins_cap:build_check' # check if the revision has been built by Jenkins successfully

set :releases_path, "#{deploy_to}/releases"
set :current_path, "#{deploy_to}/repo/master"
set :cache_path, "../../cache"

# Jenkins env vars
set :basedir,		"."
set :builddir,		"#{basedir}/../../build"
set :cachedir,  	"#{basedir}/../../cache"

namespace :ailove do

  desc "Cleanup cache and build artifacts"
  task :clean do
    pretty_print "--> Clean cache and build directory"
    run_locally "rm -rf #{builddir}/* #{cachedir}/*"
    puts_ok
  end

  desc "Prepare for build"
  task :prepare do
    pretty_print "--> Prepare for build"
    run_locally "mkdir #{builddir}/api"
    run_locally "mkdir #{builddir}/code-browser"
    run_locally "mkdir #{builddir}/coverage"
    run_locally "mkdir #{builddir}/pdepend"
    run_locally "mkdir #{builddir}/phpdox"
    run_locally "mkdir #{builddir}/behat"
    puts_ok
  end

  desc "Perform syntax check of sourcecode file"
  task :lint do
    pretty_print "--> Perform syntax check of sourcecode file"
    run_locally "find ./src -name '*.php' -print0 | xargs -0 -n1 -P8 php -l"
    puts_ok
  end

  desc "Behat"
  task :behat do
    pretty_print "--> Behat"
    run_locally "php app/console -e=test behat -f junit --out #{builddir}/behat"
    puts_ok
  end

  desc "PHPUnit"
  task :phpunit do
    pretty_print "--> PHPUnit"
    run_locally "phpunit -c ./app"
    puts_ok
  end

  desc "Run some tests"
  task :make_test do
    ailove.clean
    ailove.prepare
    ailove.lint
    ailove.behat
    ailove.phpunit
  end

  desc "Ailove factory deploy action"
  task :factory_deploy do
    jenkins_cap.build_check if jenkins_check
    deploy.update
  end

  desc "Ailove factory build action"
  task :factory_build do
    pretty_print "--> Adding build job #{application} to Jenkins queue"
    run_locally "curl -n --head #{jenkins_host}/job/#{application}/build 2> /dev/null"
    puts_ok
  end

  desc "Ailove factory rollback action"
  task :factory_rollback do
    deploy.rollback.code 
  end

end

namespace :deploy do
  desc "Updates latest release source path"
  task :finalize_update, :roles => :app, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    pretty_print "--> Creating cache directory"

    run "if [ -d #{latest_release}/#{cache_path} ] ; then rm -rf #{latest_release}/#{cache_path}/*; fi"

    puts_ok
  end
end

namespace :symfony do
#  namespace :bootstrap do
#    desc "Runs the bin/build_bootstrap script"
#    task :build, :roles => :app, :except => { :no_release => true } do
#      pretty_print "--> Building bootstrap file (skip)"
#
#      puts_ok
#    end
#  end
  namespace :cache do
    desc "Clears cache"
    task :clear, :roles => :app, :except => { :no_release => true } do
      pretty_print "--> Clearing cache"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:clear --env=#{symfony_env_prod}"
      puts_ok
    end

    desc "Warms up an empty cache"
    task :warmup, :roles => :app, :except => { :no_release => true } do
      pretty_print "--> Warming up cache"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} cache:warmup --env=#{symfony_env_prod}"
      puts_ok
    end
  end
end
