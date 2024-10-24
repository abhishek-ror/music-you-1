module BxBlockCommunityforum
  class CommunityForumsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token

    def invite_members
      invited_emails = params.dig(:community_forum, :emails)
      if invited_emails.present?
        render json: { message: "Invitations sent successfully to #{invited_emails}" }, status: :ok
      else
        render json: { message: "No email addresses provided" }, status: :unprocessable_entity
      end
    end

    def join
      current_user.join_requests.create(community_forum: @community_forum)
      render json: { message: "You have successfully joined the group" }, status: :ok
    end

    def create
      community_forum = CommunityForum.new(community_forum_params)
      community_forum.admin = current_user
      if community_forum.save
        render json: { community_forum: CommunityForumSerializer.new(community_forum), message: "Group created successfully" }, status: :created
      else
        render json: { errors: community_forum.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def community_forum_params
      params.require(:community_forum).permit(
        :name,
        :description,
        :topics,
        :profile_pic,
        :cover_pic
      )
    end
  end
end
