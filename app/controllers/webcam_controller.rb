class WebcamController < ApplicationController
  DIR = "/opt/webcamlogs"
  
  def show_images
    @files = Dir.entries(DIR).sort.select {|e| e.end_with? ".jpg" }
  end
end
