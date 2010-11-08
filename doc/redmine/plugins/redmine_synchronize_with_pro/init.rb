require 'redmine'

# Hooks
require_dependency 'synchronize_repository_hook'

Redmine::Plugin.register :redmine_synchronize_with_pro do
  name 'Redmine Synchronize With Pro plugin'
  author 'Tarazanova Marina'
  description 'Adds "Synchronize with PRO" to repository'
  version '0.0.1'
  
  project_module :synchronize_module do
    permission :view_synchronize_link, {:synchronize => :server_script}
  end
end
