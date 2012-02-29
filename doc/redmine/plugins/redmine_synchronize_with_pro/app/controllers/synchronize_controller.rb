class SynchronizeController < ApplicationController
   
   
  def server_script
      #respond_to do |format|
        #if User.current.allowed_to?(:'view_synhronize_link',Project.find())
		@project=Project.find(params[:id])
        if User.current.allowed_to?(:'view_synchronize_link',@project)
		  @result=`/srv/admin/bin/update-pro.sh #{@project.identifier.to_s} 2>&1 | /bin/grep -v "audit_log_user_command"`
		else
		  render :nothing => true
		end  
      #end
  end

end
