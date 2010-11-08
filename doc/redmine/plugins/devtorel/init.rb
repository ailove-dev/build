require 'redmine'

# Hooks
require_dependency 'devtorel_hook'

Redmine::Plugin.register :redmine_devtorel do
  name 'devtorel'
  author 'Igor Olemskoi'
  description 'Adds SVN "Copy dev -> rel" link'
  version '0.0.1'
  
  project_module :devtorel_module do
    permission :view_devtorel_link, {:devtorel => :server_script}
  end
end
