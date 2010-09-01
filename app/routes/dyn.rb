class Main
  get "/dyn/:stylesheet.css" do
    dev = session[:device]
    if dev
      device = Device.find_by_devid(dev)
      @ht = device.height
      @wd = device.width
    else
      @ht= 320
      @wd= 240
    end
    
    content_type "text/css", :charset => "UTF-8"
    erb :"css/#{params[:stylesheet]}"
  end
end
