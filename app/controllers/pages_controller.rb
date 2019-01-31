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

      if params[:user]
        user_id = params[:user]
      else
        user_id = "tuggareutangranser"
      end
      user_response = HTTParty.get("https://api.spotify.com/v1/users/#{user_id}", :headers=> user_headers)
      user_response_body = JSON.parse(user_response.body)
      @display_name = user_response_body["display_name"]
      if !user_response_body["images"].empty?
        @profile_pic = user_response_body["images"][0]["url"]
      end
      
      
      playlist_response = HTTParty.get("https://api.spotify.com/v1/users/#{user_id}/playlists", :query=>{"limit"=>50}, :headers=>user_headers)
      playlist_response_body = JSON.parse(playlist_response.body)
      items = playlist_response_body["items"]
      @names = []
      items.each do |item|
        @names << {name: item["name"], id: item["id"]}
      end
  end

  def data
    # Get playlist id that user clicked on and token from params hash
    @name = params[:playlist_name]
    @playlist_id = params[:playlist_id]
    @token = params[:token]

    # Set header to access token with proper format 
    user_headers = {
      "Authorization" => "Bearer #{@token}"
    }

    # Query for a playlists tracks
    query = {
      "fields" => "items(track(id))"
    }

    # Get the tracks and put the ids in to comma separated list
    tracklist_response = HTTParty.get("https://api.spotify.com/v1/playlists/#{@playlist_id}/tracks", :headers=>user_headers, :query=>query)
    tracklist_response_body = JSON.parse(tracklist_response.body)
    items = tracklist_response_body["items"]
    playlist_tracks = ""
    puts "Tracks #{items.count}"
    items.each do |item|
      if item == items.last
        playlist_tracks << item["track"]["id"]
      else
        playlist_tracks << item["track"]["id"]
        playlist_tracks << ","
      end
    end
    puts playlist_tracks

    # Get audio features of tracks from the string from last API call
    audiofeature_response = HTTParty.get("https://api.spotify.com/v1/audio-features", :headers=>user_headers, :query=>{"ids"=>playlist_tracks})
    audiofeature_body = JSON.parse(audiofeature_response.body)
    # Declare variables to store sum
    @danceability = 0
    @energy = 0
    @valence = 0 
    @acousticness = 0
    @instrumentalness = 0
    @liveness = 0 
    @tempo = 0
    # Add the values to sum
    audiofeature_body["audio_features"].each do |track| 
      
      @danceability += track["danceability"].to_f
      @energy += track["energy"].to_f
      @valence += track["valence"].to_f
      @acousticness += track["acousticness"].to_f
      @instrumentalness += track["instrumentalness"].to_f
      @liveness += track["liveness"].to_f
      @tempo += track["tempo"].to_f
    end
    
    #Now average them
    num_audiofeatures = audiofeature_body["audio_features"].count
    puts "Num audiofeatures #{num_audiofeatures}"
    @danceability /= num_audiofeatures
    @energy /= num_audiofeatures
    @valence /= num_audiofeatures
    @acousticness /= num_audiofeatures
    @instrumentalness /= num_audiofeatures
    @liveness /= num_audiofeatures
    @tempo /= num_audiofeatures

    @danceability = (@danceability*100).round(2)
    @energy = (@energy*100).round(2)
    @valence = (@valence*100).round(2)
    @acousticness = (@acousticness*100).round(2)
    @instrumentalness = (@instrumentalness*100).round(2)
    @liveness = (@liveness*100).round(2)


    # Display the features for user
    respond_to do |format|
      format.js{}
    end
  end
end
