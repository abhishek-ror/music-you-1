module BxBlockAudiomusic2
  class TracksController < ApplicationController
   	before_action :set_track, only: [:show, :play, :pause]

    def index
      @tracks = current_user.tracks
      render json: @tracks
    end

    def show
      render json: @track
    end

    def create
		  # Set play_status to false for any currently playing tracks
		  current_user.tracks.where(play_status: true).update_all(play_status: false)

		  # Build a new track and attempt to save it
		  @track = current_user.tracks.build(track_params)
		  if @track.save
		    render json: @track, status: :created
		  else
		    render json: @track.errors, status: :unprocessable_entity
		  end
		end

		def recently_added_tracks
      @tracks = current_user.tracks.order(created_at: :desc).limit(3)
      tracks = @tracks.map do |track|
        {
          'song_name': track.song_name,
          'artist_name': track.artist_name,
          'image_url': track.image_url,
          'song_url': track.song_url
        }
      end
      render json: tracks
    end

    def play
	  	current_user.tracks.where(play_status: true).update_all(play_status: false) # Pause any currently playing tracks
	  	@track.update(play_status: true)
	  	render json: { message: "Track '#{@track.song_name}' is now playing", track: @track }
		end

		def pause
	  	@track.update(play_status: false)
	  	render json: { message: "Track '#{@track.song_name}' is now paused", track: @track }
		end

		def currently_playing
	  	@track = current_user.tracks.find_by(play_status: true)
	  	if @track
	    	render json: @track
  		else
	    	render json: { message: "No track is currently playing" }
  		end
		end

    def get_currently_playing_track
      connection = BxBlockApiintegration52::MusicConnection.find_by(account_id: current_user.id, service_name: 'Spotify')

      if connection.blank?
        render json: { errors: 'Spotify connection not found' }, status: :not_found
        return
      end

      access_token = connection.access_token
      response = BxBlockAudiomusic2::Player.spotify_currently_playing_track(access_token)

      if response.code == 401 && response.parsed_response["error"]["message"] == 'The access token expired'
        token_response = BxBlockApiintegration52::Spotify.update_tokens(connection)
        if token_response.code == '200'
          access_token = connection.access_token
          response = BxBlockAudiomusic2::Player.spotify_currently_playing_track(access_token)
        else
          error_response = JSON.parse(token_response.body)
          render json: error_response, status: token_response.code
          return
        end
      end

      render json: response, status: response.code
    end

    private

    def set_track
      @track = current_user.tracks.find(params[:id])
    end

    def track_params
      params.require(:track).permit(:song_name, :artist_name, :image_url, :song_url, :service_name, :play_status)
    end
  end
end
