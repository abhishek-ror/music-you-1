# frozen_string_literal: true

module BxBlockComments
  class CommentsController < ApplicationController
    before_action :current_user
    before_action :load_comment, only: %i[like dislike show]
    # before_action :check_comment_type, only: [:create]

    def index
      authorize BxBlockComments::Comment
      comments = Comment.where(commentable_id: params[:commentable_id])
      if comments.present?
        render json: CommentSerializer.new(
          comments,
          {params: {current_user: current_user}}
        ).serializable_hash, status: :ok
      else
        render json: {
          errors: [
            {message: "No comments."}
          ]
        }, status: :ok
      end
    end

    def search
      @comments = Comment.where("comment ILIKE :search", search: "%#{search_params[:query]}%")
      render json: CommentSerializer.new(
        @comments, meta: {success: true, message: "Comment details."}
      ).serializable_hash, status: :ok
    end

    def show
      authorize @comment
      render json: CommentSerializer.new(
        @comment,
        meta: {success: true, message: "Comment details."},
        params: {current_user: current_user}
      ).serializable_hash, status: :ok
    end

    def create
      @comment = Comment.new(comment_params)

      authorize @comment
      @comment.account_id = current_user.id
      if @comment.save
        render json: CommentSerializer.new(
          @comment,
          meta: {
            success: true, message: "Comment created."
          },
          params: {current_user: current_user}
        ).serializable_hash, status: :created
      else
        render json: {errors: format_activerecord_errors(@comment.errors)},
          status: :unprocessable_entity
      end
    end

    def update
      @comment = Comment.find_by(id: params[:id], account_id: current_user.id)

      unless @comment.present?
        return render json: {
          errors: [
            {message: "Comment does not exist."}
          ]
        }, status: :unprocessable_entity
      end

      authorize @comment

      if @comment.update(comment: comment_params["comment"])
        render json: CommentSerializer.new(
          @comment,
          meta: {
            success: true, message: "Comment updated."
          },
          params: {current_user: current_user}
        ).serializable_hash, status: :ok
      else
        render json: {errors: format_activerecord_errors(@comment.errors)},
          status: :unprocessable_entity
      end
    end

    def destroy
      @comment = Comment.find_by(id: params[:id], account_id: current_user.id)

      unless @comment.present?
        return render json: {
          errors: [
            {message: "Comment does not exist."}
          ]
        }, status: :unprocessable_entity
      end

      authorize @comment

      if @comment.destroy
        render json: {message: "Comment deleted."}, status: :ok
      else
        render json: {errors: format_activerecord_errors(@comment.errors)},
          status: :unprocessable_entity
      end
    end

    private

    def comment_params
      params.require(:comment).permit(:commentable_id, :commentable_type, :comment)
    end

    #no need currenlty
    # def check_comment_type
    #   commentable_type = params[:comment][:commentable_type]
    #   unless commentable_type == "BxBlockPosts::Post" || commentable_type == "BxBlockComments::Comment" || commentable_type == "BxBlockCommunityforum::Post"
    #     render json: {error: "Only BxBlockComments::Comment, BxBlockPosts::Post, or BxBlockCommunityforum::Post can be used for comment type"},
    #       status: :bad_request
    #   end
    # end

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << {attribute => error}
      end
      result
    end

    def search_params
      params.permit(:query)
    end

    def load_comment
      @comment = BxBlockComments::Comment.find_by(id: params[:id])
      if @comment.nil?
        render json: {message: "Does not exist"},
          status: :not_found
      end
    end

    def filtered_comments
      comments = Comment.where(account_id: current_user.id)
      comments = comments.where(commentable_id: params[:commentable_id]) if params[:commentable_id].present?
      comments = comments.where(commentable_type: params[:commentable_type]) if params[:commentable_type].present?
      comments
    end
  end
end
