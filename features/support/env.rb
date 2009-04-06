require 'spec'
require 'erb'
require 'etc'

Before do
  @test_files_dir = File.join(Dir.pwd, "test_files")
  @app_dir  = File.join(@test_files_dir, "app")
  @repo_dir = File.join(@test_files_dir, "repo")
  
  FileUtils.rm_r(@test_files_dir) if File.exists?(@test_files_dir)
  FileUtils.mkdir_p(@test_files_dir)
end

