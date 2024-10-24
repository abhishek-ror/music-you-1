module BxBlockFreecredits
  class FreecreditHistoriesController < ApplicationController
    before_action :validate_json_web_token

    def index
      @histories = BxBlockFreecredits::FreecreditHistory.where(account_id: @token.id)
      if @histories.count > 0
        render json: { freecredit_histories: BxBlockFreecredits::FreecreditHistorySerializer.new(@histories).serializable_hash }
      else
        render status: :not_found, json: { message: "No free credit transactions found." }
      end
    end

  end
end
