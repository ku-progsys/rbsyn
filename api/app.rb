require 'sinatra'
require 'open3'
require 'json'

FileUtils.mkdir_p(File.join(File.expand_path("..", Dir.pwd), "tmp_bench"))

post '/run_rbsyn' do
  content_type :json

  if params[:file] && params[:file][:tempfile]
    filename = "script_#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{params[:file][:filename]}"
    filepath = File.join(File.expand_path("..", Dir.pwd), "tmp_bench", filename)

    File.open(filepath, "wb") { |f| f.write(params[:file][:tempfile].read) }

    command = "bundle exec rake bench TEST=\"#{filepath}\""
    stdout, stderr, status = Open3.capture3(command)

    # Force UTF-8
    stdout = stdout.encode('UTF-8', invalid: :replace, undef: :replace)
    stderr = stderr.encode('UTF-8', invalid: :replace, undef: :replace)

    last_line = stdout.lines.last&.chomp

    result = {
      command: command,
      exit_status: status.exitstatus,
      output: stdout.strip,
      main_output: last_line.strip,
      error: stderr.strip
    }

    return result.to_json
  else
    status 400
    return { error: "No file uploaded" }.to_json
  end
end