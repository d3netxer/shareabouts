require 'cgi'

module ApplicationHelper

  def vote_for(supportable)
    if current_user
      current_user.votes.where(:supportable_type => supportable.class.to_s, :supportable_id => supportable.id).first
    else
      return false if cookies[:supportable].inspect == "nil"
      
      supported   = Marshal.load(cookies[:supportable])
      key         = supportable.class.to_s.to_sym
      
      Vote.find(supported[key][supportable.id]) if supported.key?(key) && supported[key][supportable.id]
    end
  end
  
  def supportable_votes_path(supportable)
    send "#{supportable.class.to_s.underscore}_votes_path", supportable.id
  end
  
  def commentable_comments_path(commentable)
    send "#{commentable.class.to_s.underscore}_comments_path", commentable.id
  end
  
  def list_friends   
    # facebook friends are grabbed every new session
    session[:fb_friends] ||= user_friends_hash session[:fb_token] 
    session[:fb_friends].map {|id,name| name}.join ", "
  end
  
  def tweet(message)
    link_to "tweet", "https://twitter.com/intent/tweet?source=webclient&text=#{message}", :class => "twitter"
  end
  
  # message is irrelevant for this
  def facebook_share_feature(feature)
    url = CGI.escape(feature_point_url(feature))
    title = I18n.t("feature.sharing.facebook.status", :name => feature.display_submitter, :thing => feature.display_type)
    title = CGI.escape(title)
    # Contrary to https://developers.facebook.com/docs/share/
    # the title is ignored??
    link_to "recommend on fb", "https://www.facebook.com/sharer.php?u=#{url}&t=#{title}", :class => "facebook"
  end
  
  def page_link_attributes(page)
    page.welcome_page? ? {'data-welcome-page' => true} : {}
  end
  
  def facebook_avatar(user)
    image_tag "https://graph.facebook.com/#{user.facebook_id}/picture" if user.facebook_id.present?
  end
  
  private
  
  def user_friends_hash(access_token)
    friends_graph = FGraph.me('friends', :access_token => access_token)
    return {} if friends_graph.blank?
        
    User.where("facebook_id in (#{friends_graph.map { |h| h["id"] }.join(",")})").inject({}) do |memo, user|
      memo[user.id] = user.name
      memo
    end
  end
end
