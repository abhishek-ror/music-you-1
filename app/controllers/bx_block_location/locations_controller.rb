module BxBlockLocation
  class LocationsController < ApplicationController
  	before_action :lat_lon, only: %i(user_location)

  	def user_location
      profile = current_user.profiles.last
      if profile.present?
        profile.update(latitude: params[:latitude], longitude: params[:longitude])
        render json: {
    		  message: 'Location is fetched and updated on user profile',
    		  location: {
    		    Country: profile.country,
    		    City: profile.city,
    		    Address: profile.address,
    		    Postal_code: profile.postal_code
    		  }
    		}, status: :ok
      else
        render json: { errors: 'Profile does not exist' }, status: :unprocessable_entity
      end
    end

    private

    def current_user
      @account = AccountBlock::Account.find_by(id: @token.id)
    end

    def lat_lon
      unless params[:latitude].present? && params[:longitude].present?
        render json: { errors: 'Please send location' }, status: :unprocessable_entity and return
      end
      [params[:latitude], params[:longitude]]
    end
  end
end
