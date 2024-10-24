module BxBlockContentflag
  class BuildingBlocksController < ApplicationController
    before_action :validate_json_web_token

    def create
      @post = BxBlockPosts::Post.find_by_id(params[:post_id])
      @flag_reason = BxBlockContentflag::FlagCategory.find_by_id(params[:category_id])
      if @post.present? && @flag_reason.present?
        BxBlockContentflag::Content.create!(post_id: @post.id, flag_category_id: @flag_reason.id, account_id: current_user.id)

        render json: {success: [{message: 'Post Flagged Successfully'}]}, status: :ok
      else
        render json: {success: [{message: 'Please, provide all parameters'}]}, status: :not_found
      end
    end

    def index
      @all_content = BxBlockContentflag::Content.where(account_id: current_user.id)
      if @all_content.present?
        falgged_post = []
        @all_content.each do |p|
          falgged_post << p.post
        end
        render json: {success: [{falgged_post: falgged_post.as_json}]}, status: :ok
      else
        render json: {success: [{message: 'No content found!'}]}, status: :not_found
      end
    end

    def flag_category
      @flag_reason =  BxBlockContentflag::FlagCategory.all
      if @flag_reason.present?
        render json: {success: [{flag_reason: @flag_reason.as_json(only: [:id, :reason])}]}, status: :ok
      else
        render json: {success: [{message: 'No reasons found!'}]}, status: :not_found
      end
    end
  end
end
