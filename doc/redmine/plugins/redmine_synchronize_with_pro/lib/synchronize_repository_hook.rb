# Hooks to attach to the Redmine Projects.
class SynchronizeRepositiryHook < Redmine::Hook::ViewListener

  def protect_against_forgery?
    false
  end
  
  
  #  Renders link "Synhronize with PRO"
  def view_repositories_show_contextual(context = { })
    if context[:project].module_enabled?('synchronize_module')
	 if User.current.allowed_to?(:view_synchronize_link, context[:project])
	    url_options={:controller=>'synchronize',:action=>'server_script',:id=>context[:project].id, :host=>Setting.host_name}
	    if Setting.protocol=='https'
	      url_options[:protocol]='https'
	      url_options[:only_path]=false
	    end
	    #raise url_options.inspect
	    return link_to_remote("Синхронизировать с PRO",:url=>url_options) + "&nbsp;|&nbsp;"
	  else
	   return ''
      end 
	else   
	  return ''
	end 
  end

  
end  