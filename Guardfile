guard :shell do
  watch /.*/ do |m|
    path = m[0]
    asset_type = if %r{^client/(javascripts|templates)/.+$}.match path
      "javascripts"
    elsif %r{^client/stylesheets/.+$}.match path
      "stylesheets"
    elsif %r{^spec/javascripts/.+$}.match path
      "specs"
    end
    `rake assets:compile_#{asset_type}`  unless asset_type.nil?
  end
end
