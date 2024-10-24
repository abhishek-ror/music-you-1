module BxBlockApplemusicapiconnection
  class AppleMusicApiConnectionsController < ApplicationController
  	def developer_token
	    token = AppleMusicTokenGenerator.generate_token
	    render json: { developer_token: token }
	end
  end
end
