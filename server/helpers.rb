class App < Sinatra::Base
  App.helpers do
    def haml_partial(page, options={})
      haml page, options.merge!(:layout => false)
    end

    def erb_partial(page, options={})
      erb page, options.merge!(:layout => false)
    end

    def json(body_hash, status=200, headers={})
      body = if params[:readable]
        JSON.pretty_generate(body_hash)
      else
        body_hash.to_json
      end
      halt status, headers.merge({'Content-Type' => 'application/json'}), body
    end
  end
end
