ActionController::Routing::Routes.draw do |map|
    map.connect 'projects/:id/repository/:controller', :action => 'server_script', :conditions => { :method => :post }
end
