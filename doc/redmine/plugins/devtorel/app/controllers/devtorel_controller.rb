class DevtorelController < ApplicationController
   
   
  def server_script
      #respond_to do |format|
        #if User.current.allowed_to?(:'view_devtorel_link',Project.find())
		@project=Project.find(params[:id])
        if User.current.allowed_to?(:'view_devtorel_link',@project)
		  @result=`/srv/admin/bin/sync-devtorel.sh #{@project.identifier.to_s}`
		else
		  render :nothing => true
		end  
      #end
  end

end
