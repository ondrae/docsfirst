require "sinatra"
require "sinatra/reloader" if development?
require "mini_magick"
require "httparty"
require "pry"

class App < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get "/" do
    erb :form
  end

  post "/" do
    puts request.env
    puts headers
  end

  post '/save_image' do

    @filename = params[:file][:filename]
    file = params[:file][:tempfile]

    File.open("./public/#{@filename}", 'wb') do |f|
      f.write(file.read)
    end

    image = MiniMagick::Image.open("./public/#{@filename}")
    image.resize "1500x750"
    image.format "jpeg"
    image.write "./public/output.jpeg"



    response = HTTParty.post('https://api.ocr.space/parse/image', headers: {apikey: ENV["ocr_apikey"]}, body: { file: File.open("./public/output.jpeg")} )
    groups = /LN\s*(.+?) \r\nFN\s*(.+?) \r\n(\d+ .+?) \r\n(.+?) \r\n/.match(response["ParsedResults"].first["ParsedText"])

    results = {
      last_name: groups[1],
      first_name: groups[2],
      street_address: groups[3],
      city_state_zip: groups[4]
    }

    erb :show_image, locals: { results: results }
  end
end
