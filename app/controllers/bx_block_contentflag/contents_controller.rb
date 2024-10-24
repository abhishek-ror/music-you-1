module BxBlockContentflag
  class ContentsController < ApplicationController
		before_action :validate_json_web_token, only: [:create, :index, :flag_comment, :update]
		def create
			@post = BxBlockPosts::Post.find_by_id(params[:post_id])
			@flag_reason =  BxBlockContentflag::FlagCategory.find_by(id: params[:reason_id])
			@flag_reason =  BxBlockContentflag::FlagCategory.last unless @flag_reason.present?
			if @post.present? and @flag_reason.present?
				BxBlockContentflag::Content.create!(post_id: @post.id, flag_category_id: @flag_reason.id, account_id: current_user.id)
				render json: {success: [{message: 'Post Flagged Successfully'}]}, status: :ok
			else
				render json: {success: [{message: 'Please, provide all parameters'}]}, status: :not_found
			end
		end

		def index
		@all_content = BxBlockContentflag::Content.where(account: current_user)
			if @all_content.present?
				falgged_post = []
				@all_content.each do |p|
					falgged_post << p.post
				end
				render json: {success: [{falgged_post: falgged_post.as_json}]}, status: :ok
			else
				render json: {success: [{message:'No content found!'}]}, status: :not_found
			end
		end

		def update
			@content = BxBlockContentflag::Content.find(params[:id])
			if @content.update(content_params)
				render json: {success: [{message: 'Post Flagged Successfully'}]}, status: :ok
			else
				render 'edit'
			end
		rescue ActionController::ParameterMissing
			render json: {success: [{message: 'Please, provide all parameters'}]}, status: :unprocessable_entity
		end

		def flag_comment
			@comment = BxBlockComments::Comment.find_by_id(params[:comment_id])
			@post = BxBlockPosts::Post.find_by_id(params[:post_id])
			if @comment.present? and @post.present?
				BxBlockContentflag::FlagComment.create!(post_id: @post.id, account_id: current_user.id, comment_id: @comment.id)
				render json: {success: [{message: 'Comment Flagged Successfully'}]}, status: :ok
			else
				render json: {success: [{message: 'Please, provide all parameters'}]}, status: :not_found
			end
		end

		private

		def content_params
			params.require(:content).permit(:approved, :post_id)
		end
  end
end
