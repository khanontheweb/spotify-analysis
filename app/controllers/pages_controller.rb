class PagesController < ApplicationController
  def home
    id = ENV["SPOTIFY_ID"]
      secret = ENV["SPOTIFY_SECRET"]
      credentials = "#{id}:#{secret}"
      # encode the string to base 64
      enc = Base64.encode64(credentials)
      enc = enc.gsub(/\s+/,"")

      body = {
          "grant_type" => "client_credentials"
      }

      headers = {
          "Authorization" => "Basic #{enc}"
      }

      
      # make the post request with required body and header parameters
      response = HTTParty.post("https://accounts.spotify.com/api/token", :body => body, :headers => headers)
      body = JSON.parse(response.body)
      # set the access token for future calls
      @client_access_token = body["access_token"]


      user_headers = {
        "Authorization" => "Bearer #{@client_access_token}"
      }

      user_id = "tuggareutangranser"
      user_response = HTTParty.get("https://api.spotify.com/v1/users/#{user_id}", :headers=> user_headers)
      user_response_body = JSON.parse(user_response.body)
      @display_name = user_response_body["display_name"]
      @profile_pic = user_response_body["images"][0]["url"]
      
      
      playlist_response = HTTParty.get("https://api.spotify.com/v1/users/#{user_id}/playlists", :query=>{"limit"=>50}, :headers=>user_headers)
      playlist_response_body = JSON.parse(playlist_response.body)
      items = playlist_response_body["items"]
      @names = []
      items.each do |item|
        @names << item["name"]
      end
  end

  def search
  end
end
