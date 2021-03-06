class ProfilesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_topic, :only => [:edit, :update]

  def info
    @profile = User.where(["email like ?", "#{params[:id]}@%"]).first

    #@profile = User.find(params[:id])
    #@profile = User.find(params[:id])
    @topics = Topic.where(:user_id => @profile.id )
    @comments = Comment.where(:user_id => @profile.id)

    favorite_topic_ids = []
    favorite_topics = UserTopicFavorite.where(:user_id=> @profile.id)

    @favorites = []
    favorite_topics.each do |favorite_topic|
      @favorites << Topic.find(favorite_topic.topic_id)
    end

    @likes = @profile.liked_topics

    @be_friend = current_user.friendships.find_by_friend_id(@profile.id)

    @friends = @profile.friends

  end

  def edit

  end

  def update

    if @profile.update(profile_params)
      flash[:notice] = "update success"
      redirect_to admin_topics_path
    else
      render "edit"
    end
  end

  protected

  def set_topic
    @profile = User.find(params[:id])
  end

  def profile_params
    params.require(:user).permit(:bio, :role)
  end



end
