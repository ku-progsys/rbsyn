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
    synthesized_code(params[:file][:tempfile].read)
  else
    status 400
    return { error: "No file uploaded" }.to_json
  end
end
