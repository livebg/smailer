guard :bundler do
  watch 'Gemfile'
end

guard :rspec, cmd: 'rspec --format progress --color -r ./spec/spec_helper.rb', all_on_start: true, all_after_pass: false do

  watch 'spec/spec_helper.rb'
  watch %r{^spec/support/.+\.rb$}

  watch(%r{^spec/.+_spec\.rb$})

  watch(%r{^lib/smailer/models/(.+)\.rb$}) {|m| "spec/models/#{m[1]}_spec.rb" }

end
