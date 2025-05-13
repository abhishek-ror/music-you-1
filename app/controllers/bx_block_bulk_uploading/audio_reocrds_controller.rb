module BxBlockBulkUploading
  class AudioRecordsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation

    def index
      account_id = params[:account_id]
      @audios = BxBlockBulkUploading::AudioRecord.where(account_id: account_id)
      audio_records = @audios.map do |audio|
        {
        id: audio.id,
        audio_url: active_storage_url_with_host(audio.record_audio),
        duration: audio.duration,
        created_at: audio.created_at,
        updated_at: audio.updated_at
        }
      end
      render json: { status: 'success', audio_records: audio_records }, status: :ok
    end

    def create
      account = current_user
      audio_params = params.require(:audio_record).permit(:record_audio)

      @audio = BxBlockBulkUploading::AudioRecord.new(account: account)

      if audio_params[:record_audio].present?
        @audio.record_audio.attach(audio_params[:record_audio])
      end

      if @audio.save
        audio_url = active_storage_url_with_host(@audio.record_audio)
        render json: { status: 'success', message: 'Audio was successfully created.', audio_url: audio_url }, status: :created
      else
        render json: { status: 'error', message: @audio.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end

    private

    def audio_params
      params.require(:audio_record).permit(:record_audio, :duration)
    end

    def active_storage_url_with_host(attachment)
      attachment.attached? ? Rails.application.routes.url_helpers.rails_blob_url(attachment,
        host: request.base_url,
        only_path: false
      ) : nil
    end
  end
end
