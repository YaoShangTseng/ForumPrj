class TopicsController < ApplicationController

  before_action :authenticate_user!, :except => [:index]
  before_action :set_topic, :only => [:show, :edit, :update, :destroy, :subscribe, :unsubscribe]

  def index

    # 依照分類篩選文章(預留)
    if params[:sort] && params[:sort] == "sports"
      @topics = Category.find_by(:name => "Sports").topics
    elsif params[:sort] && params[:sort] == "boardgame"
      @topics = Category.find_by(:name => "BoardGame").topics
    elsif params[:sort] && params[:sort] == "love"
      @topics = Category.find_by(:name => "Love").topics
    elsif params[:sort] && params[:sort] == "action"
      @topics = Category.find_by(:name => "Action").topics
    else
      # 目前預設排序為文章update時間
      @topics = Topic.includes(:comments => :user).all #.order("updated_at desc")
      #@topics = Topic.all.order("comment_last_updated_at desc")
    end

    # 隱藏不是自己的draft文章
    if current_user.nil?
      @topics = @topics.where(:status => "release")
    else
      @topics = @topics.where("user_id = ? or status = ?", current_user.id, "release")
    end
    @short_names = {}
    @topics.each do |topic|
      @short_names["#{topic.id}"] =
        topic.comments.map do |comment|
         { comment.user.id => comment.user.short_name }
        end.uniq
    end

    # @topics.each do |topic|
    #   @short_names["#{topic.id}"] =
    #     topic.comments.map do |comment|
    #       comment.user.short_name
    #     end.uniq
    # end

    if params[:order]
      if params[:order] == "last_comment_time"
        @topics = Topic.all.order("comment_last_updated_at desc")
      elsif params[:order] && params[:order] == "comment_number"
        @topics = Topic.all.order("comments_count desc")
      elsif params[:order] && params[:order] == "topic_clicks"
        @topics = Topic.all.order("clicked desc")
      end
    end

    params_for_page

    @categories = Category.all

    @friendship_asks = []
    @friendship_asks = current_user.inverse_friendships.where(:status => "request") if current_user
  end

  def show
    @topic.clicked += 1
    @topic.save

    # 隱藏不是自己的draft評論
    if current_user
      @comments = @topic.comments.where("user_id = ? or status = ?", current_user.id, "release").order("updated_at desc")
    else
      @comments = @topic.comments.where(:status => "release").order("updated_at desc")
    end

    # 讀取這篇文章是否已經被此使用者收藏
    @is_favorite = UserTopicFavorite.where(:user_id => current_user.id, :topic_id => @topic.id).count == 0 ? false : true

    @subscription = @topic.find_my_subscription(current_user)

    @like = @topic.find_my_like(current_user)

    if params[:cid]
      @comment = Comment.find(params[:cid])
    else
      @comment = Comment.new
    end


  end

  def destroy
    if @topic.user.admin? || @topic.user.is_current_user?(current_user.id)
      @topic.destroy
      flash[:alert] = "delete success"
      redirect_to topics_path
    else
      flash[:alert] = "you cannot DESTROY others' topics"
      redirect_to topics_path
    end
  end

  def new
    @topic = Topic.new
  end

  def create
    @topic = Topic.new(topic_params)
    @topic.user = current_user
    if @topic.save
      if params[:photos]
        params[:photos].each do |photo|
          @topic.photos.create(:photo => photo)
        end
      end
      flash[:notice] = "create success"
      redirect_to topics_path
    else
      render "new"
    end
  end

  def edit
    unless @topic.user.is_current_user? current_user.id #!= current_user
      # TODO 6 Define a method in User model to replace this line
      flash[:alert] = "you cannot EDIT others' topics"
      redirect_to topics_path
    end
  end

  def update

    if params[:_remove_pic] == "1"
      @topic.pic = nil
    end

    if params[:_remove_photos] == "1"
      @topic.photos.destroy_all
    end



    if @topic.update(topic_params)

      if params[:photos]
        params[:photos].each do |photo|
          @topic.photos.create(:photo => photo)
        end
      end

      flash[:notice] = "update success"
      redirect_to topics_path
    else
      render "edit"
    end

  end

  def about
    @users = User.all
    @topics = Topic.all
    @comments = Comment.all
  end

  def favorite
    Topic.find(params[:id]).favorite_users << current_user
    #UserTopicFavorite.create(:user_id => current_user.id, :topic_id => params[:id])
    @is_favorite = UserTopicFavorite.where(:user_id => current_user.id, :topic_id => params[:id]).count == 0 ? false : true
    redirect_to topic_path(params[:id])
  end

  def unfavorite
    Topic.find(params[:id]).favorite_users.delete(current_user.id)
    #UserTopicFavorite.find_by(:user_id => current_user.id, :topic_id => params[:id]).destroy
    @is_favorite = UserTopicFavorite.where(:user_id => current_user.id, :topic_id => params[:id]).count == 0 ? false : true
    redirect_to topic_path(params[:id])
  end

  def subscribe
    @subscription = @topic.find_my_subscription(current_user)

    unless @subscription
      @subscription = Subscription.create(:topic => @topic, :user => current_user)
    end

    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def unsubscribe
    @subscription = @topic.find_my_subscription(current_user)
    @subscription.destroy
    @subscription = nil
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  protected

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:title, :content, :pic, :photos, :clicked, :status,:category_ids => [])
  end

  def params_for_page
    @topics = @topics.page(params[:page]).per(5)
  end

end
