Capistrano::Configuration.instance(:must_exist).load do
  task "my_task" do
    run "echo PEOPLE_LIKE_YOU > #{shared_path}/PEOPLE_LIKE_YOU"
  end
end
