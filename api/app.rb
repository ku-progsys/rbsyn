require 'sinatra'
require 'open3'
require 'json'
require_relative 'local_run'

scripts_folder = "unsynthesized_scripts"

FileUtils.mkdir_p(File.join(File.expand_path("..", __dir__), scripts_folder))

syntheis_folder = "synthesized_scripts"

FileUtils.mkdir_p(File.join(File.expand_path("..", __dir__), syntheis_folder))

post '/run_rbsyn' do
  content_type :json

  if params[:file] && params[:file][:tempfile]
    filename = "unsynthesized_#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{params[:file][:filename]}"
    filepath = File.join(File.expand_path("..", __dir__), scripts_folder, filename)

    File.open(filepath, "wb") { |f| f.write(params[:file][:tempfile].read) }

    synthesized_filename = "synthesized_#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{params[:file][:filename]}"
    synthesized_filepath = File.join(File.expand_path("..", __dir__), syntheis_folder, synthesized_filename)

    synthesized_code(filepath, synthesized_filepath)

    content = File.read(synthesized_filepath)
    content_type 'text/plain', :charset => 'utf-8'
    return content
  else
    status 400
    return { error: "No file uploaded" }.to_json
  end
end