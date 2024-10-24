module BxBlockApiintegration52
  class MusicConnectionsController < ApplicationController

    def create
      @music_connection = MusicConnection.new(connection_params.merge(account_id: current_user.id))
      if @music_connection.save
        render json: { message: 'Synced successfully', music_connection: @music_connection }, status: :created
      else
        render json: { errors: @music_connection.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def unsync
      @music_connection = MusicConnection.find_by(account_id: current_user.id, service_name: params[:service_name])
      if @music_connection.nil?
        render json: { errors: 'Music connection not found' }, status: :not_found
      else
        @music_connection.destroy
        render json: { message: 'Music connection unsynced successfully' }, status: :ok
      end
    end

    def index
      music_connections = MusicConnection.where(account_id: current_user.id)
      if music_connections.any?
        render json: MusicConnectionsSerializer.new(music_connections).serializable_hash, status: :ok
      else
        render json: { errors: 'No music connections found' }, status: :not_found
      end
    end

    def get_synced_users
      service_name = params[:service_name]
      if service_name.present? && ['Spotify', 'Apple'].include?(service_name)
        synced_users = MusicConnection.where(service_name: service_name)
        render json: { synced_users_count: synced_users.count }, status: :ok
      else
        render json: { errors: 'Invalid service name' }, status: :unprocessable_entity
      end
    end

    private

    def connection_params
      params.require(:music_connection).permit(:account_id, :service_name, :refresh_token, :access_token, :access_token_expiration_date)
    end
  end
end
